#!/bin/sh
# Called by NodeMCU via HTTP POST when a coin session ends (normal timeout or cancel).
# Verifies PSK signature + MAC, calculates time, grants or extends session.

# --- 1. Load configuration so environment variables are populated ---
[ -f /tmp/coin_config.env ] && . /tmp/coin_config.env

# --- 2. Fallback definitions in case they are missing from env ---
SESSION_FILE="${SESSION_FILE:-/tmp/active_sessions.txt}"
USERS_FILE="${USERS_FILE:-/lmepisowifi/hotspot_data/users.txt}"

# --- 2b. Customizable Telegram/Discord message templates ---
[ -f /lmepisowifi/hotspot/notify_templates.sh ] && . /lmepisowifi/hotspot/notify_templates.sh

# --- 3. Define response and processing helpers ---
_err() { printf '{"error":"%s"}\n' "$1"; exit 0; }
_ok()  { printf '%s\n' "$1";           exit 0; }
_md5() { printf '%s' "$1" | md5sum | awk '{print $1}'; }

_unlock() { rmdir /tmp/hotspot_session.lock 2>/dev/null; }
_lock() {
    local i=0
    while ! mkdir /tmp/hotspot_session.lock 2>/dev/null; do
        [ "$i" -gt 50 ] && rmdir /tmp/hotspot_session.lock 2>/dev/null
        sleep 0.1 2>/dev/null || sleep 1
        i=$((i + 1))
    done
    trap _unlock EXIT INT TERM
}

_fmt_secs() {
    # Guard against blank or empty variables
    local s="${1:-0}"
    
    # Strip negative signs if present
    s="${s#-}"
    
    # Force to 0 if containing non-numeric characters
    case "$s" in
        ""|*[!0-9]*) s=0 ;;
    esac

    local d=$(( s / 86400 )) 
    local h=$(( (s % 86400) / 3600 )) 
    local m=$(( (s % 3600) / 60 )) 
    
    if [ "$d" -gt 0 ]; then printf '%dd %dh %dm' "$d" "$h" "$m"
    elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
    else printf '%dm' "$m"; fi
}

# --- 4. Send Correct HTTP Headers ---
printf 'Content-Type: application/json\r\n'
printf 'Cache-Control: no-cache, no-store\r\n'
printf '\r\n'

# --- Guard 1: Only requests from NODEMCU_IP are processed ---
[ "$REMOTE_ADDR" = "$NODEMCU_IP" ] || _err "Forbidden"

# --- Guard 2: Verify NodeMCU MAC via ARP (fail closed) ---
EXPECTED_MAC=$(printf '%s' "$NODEMCU_MAC" | tr -d ':' | tr 'A-F' 'a-f' | \
    sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/')
CALLER_MAC=$(awk -v ip="$NODEMCU_IP" '$1==ip {print tolower($4); exit}' /proc/net/arp 2>/dev/null)
if [ -z "$CALLER_MAC" ]; then
    # Cache miss (e.g. stale/expired ARP entry) — force a resolution
    # attempt before deciding anything. Silently falling through to
    # Guard 1's source-IP-only check here would make this endpoint
    # spoofable by anyone on the shared LAN segment; a missing ARP
    # entry must be treated the same as a mismatched one, not skipped.
    ping -c 1 -W 1 "$NODEMCU_IP" >/dev/null 2>&1
    CALLER_MAC=$(awk -v ip="$NODEMCU_IP" '$1==ip {print tolower($4); exit}' /proc/net/arp 2>/dev/null)
fi
[ -n "$CALLER_MAC" ] && [ "$CALLER_MAC" = "$EXPECTED_MAC" ] || _err "MAC mismatch"

[ "$REQUEST_METHOD" = "POST" ] || _err "POST required"

BODY=""
[ -n "$CONTENT_LENGTH" ] && [ "$CONTENT_LENGTH" -gt 0 ] 2>/dev/null && \
    BODY=$(head -c "$CONTENT_LENGTH")
[ -n "$BODY" ] || _err "Empty body"

_post() {
    printf '%s' "$BODY" | tr '&' '\n' | grep "^${1}=" | sed 's/^[^=]*=//' | head -1
}

SID=$(_post "sid")
AMOUNT=$(_post "amount")
SIG=$(_post "sig")

[ -n "$SID" ] && [ -n "$AMOUNT" ] && [ -n "$SIG" ] || _err "Missing params"
printf '%s' "$SID"    | grep -qE '^[0-9a-f]{16}$' || _err "Invalid sid"
printf '%s' "$AMOUNT" | grep -qE '^[0-9]+$'        || _err "Invalid amount"

# --- Guard 3: Verify PSK-based signature ---
EXP_SIG=$(_md5 "${COIN_PSK}:${SID}:${AMOUNT}:end")
[ "$SIG" = "$EXP_SIG" ] || _err "Bad sig"

SESSION_PATH="/tmp/coin_sessions/${SID}"
RESULT_PATH="/tmp/coin_sessions/${SID}.result"

[ -f "$SESSION_PATH" ] || _err "Session not found"

if [ -f "$RESULT_PATH" ]; then
    PREV_MIN=$(awk '{print $2}' "$RESULT_PATH")
    _ok "{\"ok\":true,\"minutes\":${PREV_MIN},\"duplicate\":true}"
fi

# --- Guard 4: Reject stale replays ---
NOW=$(awk '{print int($1)}' /proc/uptime)
LAST_SEEN=$(awk '{print ($3==""?$2:$3)}' "$SESSION_PATH")
SESSION_AGE=$(( NOW - LAST_SEEN ))
[ "$SESSION_AGE" -le $(( COIN_TIMEOUT + 30 )) ] || _err "Session expired"

CLIENT_MAC=$(awk '{print $1}' "$SESSION_PATH")

if [ "${AMOUNT:-0}" -eq 0 ]; then
    STRIKES=$($BB grep "^$CLIENT_MAC " /tmp/coin_strikes.txt 2>/dev/null | $BB awk '{print $2}')
    STRIKES=$(( ${STRIKES:-0} + 1 ))
    $BB grep -v "^$CLIENT_MAC " /tmp/coin_strikes.txt > /tmp/cs.tmp 2>/dev/null
    printf '%s %s %s\n' "$CLIENT_MAC" "$STRIKES" "$NOW" >> /tmp/cs.tmp
    $BB mv /tmp/cs.tmp /tmp/coin_strikes.txt

    # Notify once when suspension is first triggered (strikes exactly == threshold)
    _ST=${COIN_STRIKE_THRESHOLD:-3}
    _CD=${COIN_COOLDOWN:-300}
    if [ "$STRIKES" -eq "$_ST" ]; then
        _CD_MINS=$(( _CD / 60 ))
        _SUSP_MSG=$(tpl_render "$TPL_ANTI_TROLL" \
            mac "$CLIENT_MAC" strikes "$STRIKES" strikemax "$_ST" cooldownmins "$_CD_MINS")
        ( /lmepisowifi/hotspot/notify.sh "$_SUSP_MSG" "" anti_troll >/dev/null 2>&1 </dev/null & )
    fi

    printf '0 0\n' > "$RESULT_PATH"
    rm -f "$SESSION_PATH" "${SESSION_PATH}.miss" "${SESSION_PATH}.amt" "/tmp/coin_lock"
    _ok '{"ok":true,"amount":0,"minutes":0}'
fi

MINUTES=$(printf '%s %s\n' "$COIN_RATES" "$AMOUNT" | awk '
{
    amt=$NF; n=NF-1
    for(i=1;i<=n;i++){split($i,a,":");pesos[i]=a[1]+0;mins[i]=a[2]+0}
    for(i=1;i<n;i++) for(j=i+1;j<=n;j++)
        if(pesos[j]>pesos[i]){
            tp=pesos[i];pesos[i]=pesos[j];pesos[j]=tp
            tm=mins[i]; mins[i]=mins[j]; mins[j]=tm
        }
    rem=amt+0; total=0
    for(i=1;i<=n;i++) if(pesos[i]>0){
        c=int(rem/pesos[i]); total+=c*mins[i]; rem-=c*pesos[i]
    }
    print total
}')

# --- Grant or extend session (3-COLUMN AWARE) ---
if [ "${MINUTES:-0}" -gt 0 ]; then
    _lock
    $BB grep -v "^$CLIENT_MAC " /tmp/coin_strikes.txt > /tmp/cs.tmp 2>/dev/null
    $BB mv /tmp/cs.tmp /tmp/coin_strikes.txt

    SECS=$(( MINUTES * 60 ))
    EXISTING=$(grep "^$CLIENT_MAC " "$SESSION_FILE" 2>/dev/null | head -1)
    PAUSED=$(grep "^$CLIENT_MAC paused " "$USERS_FILE" 2>/dev/null | head -1)

    if [ -n "$EXISTING" ]; then
        OLD_EXP=$(printf '%s' "$EXISTING" | awk '{print $2}')
        OLD_TOTAL=$(printf '%s' "$EXISTING" | awk '{print $3}')
        [ -z "$OLD_TOTAL" ] && OLD_TOTAL=$(( OLD_EXP - NOW ))

        if [ "$OLD_EXP" -gt "$NOW" ]; then
            NEW_EXP=$(( OLD_EXP + SECS ))
            NEW_TOTAL=$(( OLD_TOTAL + SECS ))
        else
            NEW_EXP=$(( NOW + SECS ))
            NEW_TOTAL=$SECS
        fi
        grep -v "^$CLIENT_MAC " "$SESSION_FILE" > "${SESSION_FILE}.tmp" 2>/dev/null
        printf '%s %s %s\n' "$CLIENT_MAC" "$NEW_EXP" "$NEW_TOTAL" >> "${SESSION_FILE}.tmp"
        mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
    else
        # Correctly stack coin time onto paused sessions
        if [ -n "$PAUSED" ]; then
            PAUSED_REM=$(printf '%s' "$PAUSED" | awk '{print $3}')
            PAUSED_TOT=$(printf '%s' "$PAUSED" | awk '{print $4}')
            [ -z "$PAUSED_TOT" ] && PAUSED_TOT=$PAUSED_REM

            SECS=$(( SECS + PAUSED_REM ))
            NEW_TOTAL=$(( PAUSED_TOT + (MINUTES * 60) ))

            grep -v "^$CLIENT_MAC " "$USERS_FILE" > "${USERS_FILE}.tmp" 2>/dev/null
            mv "${USERS_FILE}.tmp" "$USERS_FILE"
        else
            NEW_TOTAL=$SECS
        fi

        NEW_EXP=$(( NOW + SECS ))
        printf '%s %s %s\n' "$CLIENT_MAC" "$NEW_EXP" "$NEW_TOTAL" >> "$SESSION_FILE"
        iptables -t nat -I HOTSPOT 1 -m mac --mac-source "$CLIENT_MAC" -j RETURN 2>/dev/null
        iptables -t filter -I HOTSPOT_FWD 1 -m mac --mac-source "$CLIENT_MAC" -j ACCEPT 2>/dev/null
    fi

    # Immediately write state to persistent Flash database as 'active'
    grep -v "^$CLIENT_MAC " "$USERS_FILE" > "${USERS_FILE}.tmp" 2>/dev/null
    mv "${USERS_FILE}.tmp" "$USERS_FILE"
    N_REMAIN=$(( NEW_EXP - NOW ))
    printf '%s active %s %s %s\n' "$CLIENT_MAC" "$N_REMAIN" "$NEW_TOTAL" "$(_fmt_secs "$N_REMAIN")" >> "$USERS_FILE"
    _unlock
fi

# --- Income tracking + coin-sale notification ----------------------------
if [ "${AMOUNT:-0}" -gt 0 ]; then
    # Record revenue first so income.sh get returns updated totals
    /lmepisowifi/hotspot/income.sh add "$AMOUNT" >/dev/null 2>&1

    # Format seconds as Xd Xh Xm (omit leading zero components)
    _fmt_dhm() {
        awk -v s="$1" 'BEGIN{
            s=int(s); if(s<0)s=0
            d=int(s/86400); s=s%86400
            h=int(s/3600);  s=s%3600
            m=int(s/60)
            out=""; sep=""
            if(d>0){out=out sep d"d"; sep=" "}
            if(h>0||d>0){out=out sep h"h"; sep=" "}
            out=out sep m"m"
            print out
        }'
    }

    if [ "${MINUTES:-0}" -gt 0 ]; then
        # Fetch updated income totals
        _INCOME=$(/lmepisowifi/hotspot/income.sh get 2>/dev/null)
        _I_D=$(printf '%s' "$_INCOME" | awk -F'"daily":'   '{split($2,a,"[,}]"); print a[1]+0}')
        _I_M=$(printf '%s' "$_INCOME" | awk -F'"monthly":' '{split($2,a,"[,}]"); print a[1]+0}')
        _I_Y=$(printf '%s' "$_INCOME" | awk -F'"yearly":'  '{split($2,a,"[,}]"); print a[1]+0}')

        # Active sessions count (includes this session, already written)
        _ACTIVE=$($BB grep -c '.' "$SESSION_FILE" 2>/dev/null)
        [ -n "$_ACTIVE" ] || _ACTIVE=0

        # NTP-synced system time
        _DT=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)

        N_REMAIN=$(( NEW_EXP - NOW ))
        N_MSG=$(tpl_render "$TPL_NEW_SALE" \
            totaltime "$(_fmt_dhm ${NEW_TOTAL:-0})" \
            addedtime "$(_fmt_dhm $(( MINUTES * 60 )))" \
            remainingtime "$(_fmt_dhm ${N_REMAIN:-0})" \
            insertcoinamt "$AMOUNT" \
            mac "$CLIENT_MAC" \
            activeusrcount "${_ACTIVE:-0}" \
            dailyamt "${_I_D:-0}" \
            monthlyamt "${_I_M:-0}" \
            yearlyamt "${_I_Y:-0}" \
            date "$_DT")
        N_EVT="new_sale"
    else
        N_MSG=$(tpl_render "$TPL_COINS_INSERTED" insertcoinamt "$AMOUNT" mac "$CLIENT_MAC")
        N_EVT="coins_inserted"
    fi
    ( /lmepisowifi/hotspot/notify.sh "$N_MSG" "" "$N_EVT" >/dev/null 2>&1 </dev/null & )
fi
# -------------------------------------------------------------------------

printf '%s %s\n' "$AMOUNT" "$MINUTES" > "$RESULT_PATH"
rm -f "$SESSION_PATH" "${SESSION_PATH}.miss" "${SESSION_PATH}.amt" "/tmp/coin_lock"

_ok "{\"ok\":true,\"amount\":${AMOUNT},\"minutes\":${MINUTES}}"