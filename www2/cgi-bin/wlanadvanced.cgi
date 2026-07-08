#!/bin/sh

SESSION_TIMEOUT=600

# ---- Auth gate (mirrors lme.cgi) ----
BROWSER_SESSION=$(echo "$HTTP_COOKIE" | busybox sed -n 's/.*session=\([^;]*\).*/\1/p' | busybox tr -d '\r\n')
# Sanitize: session IDs are sha256 hex. Strip anything else to block
# path traversal (e.g. Cookie: session=../../config/foo) into rm/mv/cat.
BROWSER_SESSION=$(printf '%s' "$BROWSER_SESSION" | busybox tr -cd 'a-fA-F0-9')
SESSION_FILE="/tmp/sessions/$BROWSER_SESSION"

if [ -z "$BROWSER_SESSION" ] || [ ! -f "$SESSION_FILE" ]; then
    printf "Status: 302 Found\r\n"
    printf "Location: /login.html\r\n\r\n"
    exit 0
fi

LAST=$(cat "$SESSION_FILE" 2>/dev/null | busybox tr -d '\r\n')
NOW=$(date +%s)
if [ $((NOW - LAST)) -gt $SESSION_TIMEOUT ]; then
    rm -f "$SESSION_FILE"
    printf "Status: 302 Found\r\n"
    printf "Location: /login.html\r\n\r\n"
    exit 0
fi

echo "$NOW" > "$SESSION_FILE"

# ---- Debug logging ----
DBG_LOG="/tmp/wlanadvanced_debug.log"
dbg() {
    printf '[%s] wlanadvanced.cgi: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
        >> "$DBG_LOG" 2>/dev/null
}

# ---- Band-specific key/table setup ----
# 5GHz   → WLAN_MBSSIB_TBL  / wlan0   (no "1" in prefix — matches the
#          convention already used in wlanbasic.cgi / wan-repurpose.cgi)
# 2.4GHz → WLAN1_MBSSIB_TBL / wlan1
# WLAN_SHORTGI / WLAN1_SHORTGI are true radio-wide MIB keys (no per-interface
# variant), so Short Guard Interval only ever appears on the idx=0 (Main AP)
# card/form — same precedent as channel/txpower in wlanbasic.cgi's save_ap.
band_keys() {
    case "$1" in
        5)
            TBL_PFX="WLAN_MBSSIB_TBL"
            SGI_KEY="WLAN_SHORTGI"
            WLAN_IF="wlan0"
            RV_PFX="/tmp/advwlan_rb_5"
            ;;
        *)
            TBL_PFX="WLAN1_MBSSIB_TBL"
            SGI_KEY="WLAN1_SHORTGI"
            WLAN_IF="wlan1"
            RV_PFX="/tmp/advwlan_rb_24"
            ;;
    esac
}

ADV_TIMEOUT=90

# ---- MIB helpers ----
# Note: mib get reads from the live (running) radio state, not the committed
# config database. After mib set+commit but before wlan_apply restart, mib get
# still returns the OLD live values — this is what makes the rollback pattern work.
mib_get() {
    mib get "$1" \
        | busybox grep "=" \
        | busybox cut -d'=' -f2- \
        | busybox tr -d '\r\n'
}


# POST field helper: extract an integer field; $1 = field name, $2 = default
pd_int() {
    V=$(echo "$POST_DATA" \
        | busybox sed -n "s/.*${1}=\\([^&]*\\).*/\\1/p" \
        | busybox tr -d '\r\n')
    case "$V" in ''|*[!0-9]*) V="${2:-0}" ;; esac
    printf '%s' "$V"
}

# Per-interface getters (idx 0-5). MIMO/TXBF/MC2U/rate-limits/PMF/SHA-256/
# rate-adaptive/fixed-rate are assumed to exist per MBSSIB_TBL entry, the same
# way dotIEEE80211W (PMF) is already confirmed per-idx in wlansecurity —
# verify with `mib get` on a VAP/VXD idx if any of these don't take effect.
get_mimo()      { mib_get "${TBL_PFX}.$1.txbf_mu"; }
get_txbf()      { mib_get "${TBL_PFX}.$1.txbf"; }
get_mc2u()      { mib_get "${TBL_PFX}.$1.mc2u_disable"; }
get_txr()       { mib_get "${TBL_PFX}.$1.tx_restrict"; }
get_rxr()       { mib_get "${TBL_PFX}.$1.rx_restrict"; }
get_pmf()       { mib_get "${TBL_PFX}.$1.dotIEEE80211W"; }
get_sha256()    { mib_get "${TBL_PFX}.$1.sha256"; }
get_disabled()  { mib_get "${TBL_PFX}.$1.wlanDisabled"; }
get_rateadapt() { mib_get "${TBL_PFX}.$1.rateAdaptiveEnabled"; }
get_fixedrate() { mib_get "${TBL_PFX}.$1.fixedTxRate"; }
get_sgi()       { mib_get "$SGI_KEY"; }   # radio-wide, no idx

# ---- 5GHz 11ac fixed-rate encoding ----
# fixedTxRate = 2147483648 + (NSS-1)*10 + MCS, for NSS 1-2 and MCS 0-9:
#   2147483648-2147483657 = NSS1 MCS0-9   2147483658-2147483667 = NSS2 MCS0-9
# No mapping has been supplied for 2.4GHz (11n) yet, so fixed-rate is only
# ever accepted when band=5; 2.4GHz always stays on rate-adaptive (auto).
FIXEDRATE_BASE=2147483648
is_valid_fixedrate_5g() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "$1" -ge "$FIXEDRATE_BASE" ] && [ "$1" -le $((FIXEDRATE_BASE + 19)) ]
}

# ==========================================================
# GET
# ==========================================================
if [ "$REQUEST_METHOD" = "GET" ]; then

    BAND=$(echo "$QUERY_STRING" \
        | busybox sed -n 's/.*band=\([^&]*\).*/\1/p' \
        | busybox tr -d '\r\n')
    case "$BAND" in 5) ;; *) BAND=24 ;; esac
    band_keys "$BAND"

    # --- action=adv_confirm: client confirmed, cancel every revert timer for this band ---
    if echo "$QUERY_STRING" | busybox grep -q "action=adv_confirm"; then
        rm -f "${RV_PFX}_"*
        printf "Status: 200 OK\r\n"
        printf "Content-Type: text/plain\r\n\r\n"
        printf "confirmed"
        exit 0
    fi

    # --- action=adv_status: return band-wide + per-interface settings as JSON ---
    if echo "$QUERY_STRING" | busybox grep -q "action=adv_status"; then
        SGI=$(get_sgi); [ -z "$SGI" ] && SGI=0

        # Build ifaces JSON array (idx 0-5), aggregating the max remaining
        # revert time across every interface that has a pending timer.
        IFACES_J="["
        ISEP=""
        PENDING=false
        REMAINING=0
        I=0
        while [ "$I" -le 5 ]; do
            DIS=$(get_disabled "$I");  [ -z "$DIS"  ] && DIS=1
            MIMO=$(get_mimo "$I");     [ -z "$MIMO" ] && MIMO=0
            TXBF=$(get_txbf "$I");     [ -z "$TXBF" ] && TXBF=0
            MC2U=$(get_mc2u "$I");     [ -z "$MC2U" ] && MC2U=1
            TXR=$(get_txr "$I");       [ -z "$TXR"  ] && TXR=0
            RXR=$(get_rxr "$I");       [ -z "$RXR"  ] && RXR=0
            PMF=$(get_pmf "$I");       [ -z "$PMF"  ] && PMF=0
            SHA=$(get_sha256 "$I");    [ -z "$SHA"  ] && SHA=0
            RA=$(get_rateadapt "$I");  [ -z "$RA"   ] && RA=1
            FR=$(get_fixedrate "$I");  [ -z "$FR"   ] && FR=0

            if   [ "$I" = "0" ]; then TY="ap"
            elif [ "$I" = "5" ]; then TY="vxd"
            else                       TY="vap"
            fi

            if [ -f "${RV_PFX}_${I}_pending" ] && [ -f "${RV_PFX}_${I}_start" ]; then
                PENDING=true
                RVS=$(cat "${RV_PFX}_${I}_start" 2>/dev/null)
                if [ -n "$RVS" ]; then
                    REM=$(( ADV_TIMEOUT - ($(date +%s) - RVS) ))
                    [ "$REM" -lt 0 ] && REM=0
                    [ "$REM" -gt "$REMAINING" ] && REMAINING=$REM
                fi
            fi

            IFACES_J="${IFACES_J}${ISEP}{\"idx\":${I},\"type\":\"${TY}\",\"disabled\":${DIS},\"mimo\":${MIMO},\"txbf\":${TXBF},\"mc2u_disable\":${MC2U},\"tx_restrict\":${TXR},\"rx_restrict\":${RXR},\"pmf\":${PMF},\"sha256\":${SHA},\"rate_adaptive\":${RA},\"fixed_rate\":${FR}}"
            ISEP=","
            I=$((I + 1))
        done
        IFACES_J="${IFACES_J}]"

        printf "Status: 200 OK\r\n"
        printf "Content-Type: application/json\r\n\r\n"
        printf '{"band":"%s","wlan_if":"%s","shortgi":%s,"ifaces":%s,"pending":%s,"remaining":%d}' \
            "$BAND" "$WLAN_IF" "$SGI" "$IFACES_J" "$PENDING" "$REMAINING"
        exit 0
    fi

    # Default GET — redirect to the page
    printf "Status: 302 Found\r\n"
    printf "Location: /wlanadvanced.html\r\n\r\n"
    exit 0
fi

# ==========================================================
# POST
# ==========================================================
if [ "$REQUEST_METHOD" = "POST" ]; then

    BAND=$(echo "$QUERY_STRING" \
        | busybox sed -n 's/.*band=\([^&]*\).*/\1/p' \
        | busybox tr -d '\r\n')
    case "$BAND" in 5) ;; *) BAND=24 ;; esac
    band_keys "$BAND"

    IDX=$(echo "$QUERY_STRING" \
        | busybox sed -n 's/.*idx=\([^&]*\).*/\1/p' \
        | busybox tr -d '\r\n')
    case "$IDX" in
        0|1|2|3|4|5) ;;
        *)
            dbg "WARN save_adv: invalid index '$IDX'"
            printf "Status: 400 Bad Request\r\n"
            printf "Content-Type: text/plain\r\n\r\n"
            printf "Invalid interface index"
            exit 0
            ;;
    esac

    # Clamp body size: reject non-numeric and cap to 64KB to stop a
    # malicious Content-Length from forcing a huge/slow byte-by-byte read (DoS).
    __CL="${CONTENT_LENGTH:-0}"; case "$__CL" in *[!0-9]*|"") __CL=0 ;; esac
    [ "$__CL" -gt 65536 ] && __CL=65536
    POST_DATA=$(busybox dd bs=1 count="$__CL" 2>/dev/null)

    FORM_MIMO=$(pd_int mimo          0)
    FORM_TXBF=$(pd_int txbf          0)
    FORM_MC2U=$(pd_int mc2u_disable  1)
    FORM_TXR=$(pd_int  tx_restrict   0)
    FORM_RXR=$(pd_int  rx_restrict   0)
    FORM_PMF=$(pd_int  pmf           0)
    FORM_SHA=$(pd_int  sha256        0)
    FORM_RATEADAPT=$(pd_int rate_adaptive 1)
    FORM_FIXEDRATE=$(pd_int fixed_rate    0)

    # Validate binary flags / enums
    case "$FORM_MIMO" in 0|1)   ;; *) FORM_MIMO=0 ;; esac
    case "$FORM_TXBF" in 0|1)   ;; *) FORM_TXBF=0 ;; esac
    case "$FORM_MC2U" in 0|1)   ;; *) FORM_MC2U=1 ;; esac
    case "$FORM_PMF"  in 0|1|2) ;; *) FORM_PMF=0  ;; esac
    case "$FORM_SHA"  in 0|1)   ;; *) FORM_SHA=0  ;; esac
    case "$FORM_RATEADAPT" in 0|1) ;; *) FORM_RATEADAPT=1 ;; esac

    # txbf requires mimo — force off if mimo is being disabled
    [ "$FORM_MIMO" = "0" ] && FORM_TXBF=0

    # Fixed TX rate: only 5GHz has a validated 11ac MCS mapping right now.
    # Reject fixed mode (and any unrecognized fixedTxRate value) on any other
    # band rather than risk writing an unverified value — fall back to auto.
    if [ "$FORM_RATEADAPT" = "0" ]; then
        if [ "$BAND" = "5" ] && is_valid_fixedrate_5g "$FORM_FIXEDRATE"; then
            : # keep fixed mode with the validated value
        else
            dbg "save_adv idx=$IDX band=$BAND: rejected fixed_rate='$FORM_FIXEDRATE', forcing rate-adaptive=1"
            FORM_RATEADAPT=1
            FORM_FIXEDRATE=0
        fi
    else
        FORM_FIXEDRATE=0
    fi

    # Short Guard Interval is a radio-wide key with no per-idx variant, so it
    # only ever comes from — and is only ever applied via — the idx=0 (Main
    # AP) form.
    if [ "$IDX" = "0" ]; then
        FORM_SGI=$(pd_int shortgi 0)
        case "$FORM_SGI" in 0|1) ;; *) FORM_SGI=0 ;; esac
    fi

    CUR_DIS=$(get_disabled "$IDX")
    [ -z "$CUR_DIS" ] && CUR_DIS=1

    RP="${RV_PFX}_${IDX}"  # per-interface revert prefix

    # Clear any stale revert state for this interface only — leave other
    # interfaces' pending timers untouched.
    rm -f "${RP}_"*

    # Apply MIMO/txbf in dependency order:
    #   Disable: set txbf_mu=0, then txbf=0 (mimo first, then dependent)
    #   Enable:  set txbf_mu=1, then txbf=N (mimo must be on before txbf)
    if [ "$FORM_MIMO" = "0" ]; then
        mib set "${TBL_PFX}.${IDX}.txbf_mu" 0
        mib set "${TBL_PFX}.${IDX}.txbf"    0
    else
        mib set "${TBL_PFX}.${IDX}.txbf_mu"  1
        mib set "${TBL_PFX}.${IDX}.txbf"     "$FORM_TXBF"
    fi

    mib set "${TBL_PFX}.${IDX}.mc2u_disable"  "$FORM_MC2U"
    mib set "${TBL_PFX}.${IDX}.tx_restrict"   "$FORM_TXR"
    mib set "${TBL_PFX}.${IDX}.rx_restrict"   "$FORM_RXR"
    mib set "${TBL_PFX}.${IDX}.dotIEEE80211W" "$FORM_PMF"
    mib set "${TBL_PFX}.${IDX}.sha256"        "$FORM_SHA"
    mib set "${TBL_PFX}.${IDX}.rateAdaptiveEnabled" "$FORM_RATEADAPT"
    [ "$FORM_RATEADAPT" = "0" ] && mib set "${TBL_PFX}.${IDX}.fixedTxRate" "$FORM_FIXEDRATE"
    [ "$IDX" = "0" ] && mib set "$SGI_KEY" "$FORM_SGI"
    mib commit

    dbg "save_adv idx=$IDX band=$BAND: applied mimo=$FORM_MIMO txbf=$FORM_TXBF mc2u=$FORM_MC2U pmf=$FORM_PMF cur_dis=$CUR_DIS"

    # Skip restart and revert if this interface is already disabled — no radio change needed
    if [ "$CUR_DIS" = "1" ]; then
        dbg "save_adv idx=$IDX: interface disabled, skipping wlan_apply"
        printf "Status: 200 OK\r\n"
        printf "Content-Type: text/plain\r\n\r\n"
        printf "OK"
        exit 0
    fi

    # Interface is enabled — capture OLD live values for rollback (mib get
    # reads the running radio state, which hasn't been updated by wlan_apply yet)
    get_mimo      "$IDX" > "${RP}_mimo"
    get_txbf      "$IDX" > "${RP}_txbf"
    get_mc2u      "$IDX" > "${RP}_mc2u"
    get_txr       "$IDX" > "${RP}_txr"
    get_rxr       "$IDX" > "${RP}_rxr"
    get_pmf       "$IDX" > "${RP}_pmf"
    get_sha256    "$IDX" > "${RP}_sha256"
    get_rateadapt "$IDX" > "${RP}_rateadapt"
    get_fixedrate "$IDX" > "${RP}_fixedrate"
    [ "$IDX" = "0" ] && get_sgi > "${RP}_sgi"
    touch "${RP}_pending"
    date +%s > "${RP}_start"

    # Background revert timer
    (
        sleep $ADV_TIMEOUT
        if [ -f "${RP}_pending" ]; then
            dbg "save_adv idx=$IDX: revert timeout reached, rolling back"
            RB_MIMO=$(cat "${RP}_mimo")
            RB_TXBF=$(cat "${RP}_txbf")
            RB_MC2U=$(cat "${RP}_mc2u")
            RB_TXR=$(cat "${RP}_txr")
            RB_RXR=$(cat "${RP}_rxr")
            RB_PMF=$(cat "${RP}_pmf")
            RB_SHA=$(cat "${RP}_sha256")
            RB_RATEADAPT=$(cat "${RP}_rateadapt")
            RB_FIXEDRATE=$(cat "${RP}_fixedrate")

            if [ "$RB_MIMO" = "0" ]; then
                mib set "${TBL_PFX}.${IDX}.txbf_mu" 0
                mib set "${TBL_PFX}.${IDX}.txbf"    0
            else
                mib set "${TBL_PFX}.${IDX}.txbf_mu"  1
                mib set "${TBL_PFX}.${IDX}.txbf"     "$RB_TXBF"
            fi
            mib set "${TBL_PFX}.${IDX}.mc2u_disable"  "$RB_MC2U"
            mib set "${TBL_PFX}.${IDX}.tx_restrict"   "$RB_TXR"
            mib set "${TBL_PFX}.${IDX}.rx_restrict"   "$RB_RXR"
            mib set "${TBL_PFX}.${IDX}.dotIEEE80211W" "$RB_PMF"
            mib set "${TBL_PFX}.${IDX}.sha256"        "$RB_SHA"
            mib set "${TBL_PFX}.${IDX}.rateAdaptiveEnabled" "${RB_RATEADAPT:-1}"
            if [ "${RB_RATEADAPT:-1}" = "0" ]; then
                mib set "${TBL_PFX}.${IDX}.fixedTxRate" "${RB_FIXEDRATE:-0}"
            fi
            if [ "$IDX" = "0" ] && [ -f "${RP}_sgi" ]; then
                mib set "$SGI_KEY" "$(cat "${RP}_sgi")"
            fi
            mib commit
            wlan_apply restart
            if [ "$IDX" = "5" ]; then
                dbg "save_adv idx=5 revert: also restarting multi-ap agent service"
                sysconf multi_ap_agent_restart
            fi
            rm -f "${RP}_"*
        fi
    ) &

    dbg "save_adv idx=$IDX: launching wlan_apply restart"
    wlan_apply restart
    if [ "$IDX" = "5" ]; then
        dbg "save_adv idx=5: also restarting multi-ap agent service"
        sysconf multi_ap_agent_restart
    fi

    printf "Status: 200 OK\r\n"
    printf "Content-Type: text/plain\r\n\r\n"
    printf "OK"
    exit 0
fi

# Fallback
printf "Status: 302 Found\r\n"
printf "Location: /wlanadvanced.html\r\n\r\n"
