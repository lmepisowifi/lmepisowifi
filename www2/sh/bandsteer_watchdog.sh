#!/bin/sh
# ---------------------------------------------------------------------------
# Band Steering Watchdog
# Installed at: /lmepisowifi/www2/sh/bandsteer_watchdog.sh
#
# WHY THIS EXISTS
#   The web UI (wlanadvanced.cgi > save_bandsteer) writes the global MIB key
#   WIFI_STA_CONTROL and runs `wlan_apply restart`:
#       0 = disabled
#       1 = enabled, 5GHz preferred
#       3 = enabled, 2.4GHz preferred
#   On restart, libmib.so translates that key into per-radio iwpriv calls
#   INCORRECTLY (the inverted-preference bug). Observed broken driver state:
#
#     WIFI_STA_CONTROL=1 (want 5GHz)  -> wlan0 prefer_band=01, wlan1=00
#     WIFI_STA_CONTROL=3 (want 2.4G)  -> wlan0 prefer_band=00, wlan1=01
#
#   Neither is right: the driver's global target IDs are 1=2.4GHz, 2=5GHz and
#   BOTH radios must be told the same target. This script detects the bad live
#   state and re-asserts the correct iwpriv values.
#
# ASSUMPTIONS (matches the rest of www2: wlanbasic.cgi / wan-repurpose.cgi)
#   wlan0 = 5GHz radio
#   wlan1 = 2.4GHz radio
#
# USAGE
#   bandsteer_watchdog.sh once            # check + fix a single time
#   bandsteer_watchdog.sh monitor [secs]  # re-check every <secs> (default 60)
# ---------------------------------------------------------------------------

IF5="wlan0"    # 5GHz
IF24="wlan1"   # 2.4GHz

LOG="/tmp/bandsteer_watchdog.log"
log() {
    printf '[%s] bandsteer_watchdog: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
        >> "$LOG" 2>/dev/null
}

# Read the committed global steering mode from the MIB (same parse the CGI uses).
get_mode() {
    mib get WIFI_STA_CONTROL \
        | busybox grep "=" \
        | busybox cut -d'=' -f2- \
        | busybox tr -d '\r\n'
}

# Read a single-byte iwpriv MIB (e.g. stactrl_prefer_band) as a 2-hex-digit,
# lowercased value like "00" / "01" / "02". iwpriv prints:
#     wlanX     get_mib:
#     01
# so we grab the last 2-hex-digit token on its own.
get_pref_band() {
    iwpriv "$1" get_mib stactrl_prefer_band 2>/dev/null \
        | busybox grep -Eo '[0-9a-fA-F][0-9a-fA-F]' \
        | busybox tr 'A-F' 'a-f' \
        | busybox tail -n1
}

# Apply the CORRECT per-radio driver state for a given steering mode.
# These are the exact iwpriv values the hardware requires (target IDs:
# 1=2.4GHz, 2=5GHz), applied to BOTH radios, with RSSI kick thresholds
# (stactrl_param_1) tuned so one radio kicks clients while the other holds them.
apply_prefer_5g() {
    # Scenario A: Prefer 5GHz (Smart Connect)
    iwpriv "$IF5"  set_mib stactrl_prefer_band=2   # 5G radio -> target 5G
    iwpriv "$IF24" set_mib stactrl_prefer_band=2   # 2.4G radio -> target 5G
    iwpriv "$IF5"  set_mib stactrl_param_1=15      # 5G stays sticky; rarely kicks
    iwpriv "$IF24" set_mib stactrl_param_1=45      # 2.4G kicks early to force 5G
    log "applied Prefer-5GHz (A): $IF5/$IF24 prefer_band=2, param_1 15/45"
}

apply_prefer_24g() {
    # Scenario B: Prefer 2.4GHz
    iwpriv "$IF5"  set_mib stactrl_prefer_band=1   # 5G radio -> target 2.4G
    iwpriv "$IF24" set_mib stactrl_prefer_band=1   # 2.4G radio -> target 2.4G
    iwpriv "$IF5"  set_mib stactrl_param_1=64      # 5G kicks clients quickly (64 hex = 100 dec)
    iwpriv "$IF24" set_mib stactrl_param_1=15      # 2.4G stays sticky; rarely kicks
    log "applied Prefer-2.4GHz (B): $IF5/$IF24 prefer_band=1, param_1 64/15"
}

# One detect-and-correct pass. Returns 0 when the state is (now) correct,
# 1 when steering is disabled / not applicable.
check_once() {
    MODE=$(get_mode)
    case "$MODE" in
        1) WANT="02" ;;   # Prefer 5GHz  -> both radios prefer_band=2
        3) WANT="01" ;;   # Prefer 2.4GHz-> both radios prefer_band=1
        *)
            # 0 or anything unexpected: steering is off, nothing to enforce.
            log "steering disabled or unknown (WIFI_STA_CONTROL='$MODE'), skipping"
            return 1
            ;;
    esac

    # Both radios must be reachable before we can read/set the driver.
    if ! ifconfig "$IF5" >/dev/null 2>&1 || ! ifconfig "$IF24" >/dev/null 2>&1; then
        log "radios not ready ($IF5/$IF24), skipping this pass"
        return 1
    fi

    CUR5=$(get_pref_band "$IF5")
    CUR24=$(get_pref_band "$IF24")

    # Already correct on BOTH radios? Leave it alone (this is the "check whether
    # it is currently broken before setting it" guard).
    if [ "$CUR5" = "$WANT" ] && [ "$CUR24" = "$WANT" ]; then
        return 0
    fi

    log "broken state detected (mode=$MODE want=$WANT $IF5=$CUR5 $IF24=$CUR24), correcting"
    if [ "$MODE" = "1" ]; then
        apply_prefer_5g
    else
        apply_prefer_24g
    fi
    return 0
}

case "$1" in
    monitor)
        INTERVAL="$2"
        case "$INTERVAL" in ''|*[!0-9]*) INTERVAL=60 ;; esac
        log "monitor started (interval ${INTERVAL}s)"
        while :; do
            check_once
            sleep "$INTERVAL"
        done
        ;;
    once|"")
        check_once
        ;;
    *)
        echo "usage: $0 {once|monitor [seconds]}" >&2
        exit 1
        ;;
esac
