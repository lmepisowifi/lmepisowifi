#!/bin/sh

BB="busybox"
SESSION_FILE="/tmp/active_sessions.txt"
USERS_FILE="/lmepisowifi/hotspot_data/users.txt"
HOTSPOT_BR="br1"

_unlock() { rmdir /tmp/hotspot_session.lock 2>/dev/null; }
_lock() {
    local i=0
    while ! mkdir /tmp/hotspot_session.lock 2>/dev/null; do
        [ "$i" -gt 50 ] && rmdir /tmp/hotspot_session.lock 2>/dev/null
        $BB sleep 0.1 2>/dev/null || sleep 0.1
        i=$((i + 1))
    done
    trap _unlock EXIT INT TERM
}

$BB echo "Content-type: application/json"
$BB echo "Cache-Control: no-store"
$BB echo ""

CLIENT_IP="$REMOTE_ADDR"
CLIENT_MAC=$(
    $BB cat /proc/net/arp \
    | $BB grep "^$CLIENT_IP " \
    | $BB awk '{print $4}' \
    | $BB head -1
)

if [ -z "$CLIENT_MAC" ] || [ "$CLIENT_MAC" = "00:00:00:00:00:00" ]; then
    $BB echo '{"logged_in":false,"error":"no_mac"}'
    exit 0
fi

# -- CONNECTION DETECTION (Run for everyone regardless of session) --
WLAN_IFACE=""
WLAN_BAND=""
WLAN_RSSI=""
WLAN_SNR=""
MAC_NC=$($BB echo "$CLIENT_MAC" | $BB tr -d ':' | $BB tr 'A-Z' 'a-z')

for ifpath in /sys/class/net/wlan*; do
    [ -e "$ifpath" ] || continue
    iface=$(basename "$ifpath")
    link=$(readlink -f "/sys/class/net/$iface/brport/bridge" 2>/dev/null)
    [ -n "$link" ] && [ "$(basename "$link")" = "$HOTSPOT_BR" ] || continue
    [ -r "/proc/$iface/sta_info" ] || continue

    sta=$($BB awk -v want="$MAC_NC" '
        function flush() { if (ismatch) { print rssi; print snr; found=1 } }
        /^ *[0-9]+: *stat_info/ { flush(); if (found) exit; ismatch=0; rssi=""; snr=""; next }
        /hwaddr:/ { if (index($0, want) > 0) ismatch=1 }
        /rssi:/   { rssi=$2 }
        /snr:/    { snr=$2 }
        END { flush() }
    ' "/proc/$iface/sta_info")

    if [ -n "$sta" ]; then
        WLAN_IFACE="$iface"
        WLAN_RSSI=$($BB echo "$sta" | $BB head -1)
        WLAN_SNR=$($BB echo "$sta" | $BB tail -1)
        case "$iface" in wlan1*) WLAN_BAND="2.4GHz" ;; wlan0*) WLAN_BAND="5GHz" ;; esac
        break
    fi
done

if [ -n "$WLAN_IFACE" ]; then
    CONN_JSON="\"connection\":\"WLAN\",\"wlan_iface\":\"$WLAN_IFACE\",\"band\":\"$WLAN_BAND\",\"rssi\":${WLAN_RSSI:-0},\"snr\":${WLAN_SNR:-0}"
else
    CONN_JSON="\"connection\":\"LAN\""
fi
# -----------------------------------------------------------------

_lock
SESSION=$($BB grep "^$CLIENT_MAC " "$SESSION_FILE" 2>/dev/null | $BB head -1)

if [ -n "$SESSION" ]; then
    EXPIRY=$($BB echo "$SESSION" | $BB awk '{print $2}')
    TOTAL=$($BB echo "$SESSION" | $BB awk '{print $3}')
    NOW=$($BB awk '{print int($1)}' /proc/uptime)
    REMAINING=$(( EXPIRY - NOW ))

    if [ "$REMAINING" -gt 0 ]; then
        # Handle cases where coin_result.sh hasn't appended the total yet
        [ -z "$TOTAL" ] && TOTAL=$REMAINING
        USED=$(( TOTAL - REMAINING ))
        [ "$USED" -lt 0 ] && USED=0

        $BB echo "{\"logged_in\":true,\"mac\":\"$CLIENT_MAC\",\"ip\":\"$CLIENT_IP\",\"remaining\":$REMAINING,\"total\":$TOTAL,\"used\":$USED,${CONN_JSON}}"
        _unlock
        exit 0
    fi
fi

# Find paused entry in the unified users.txt master file
PAUSED=$($BB grep "^$CLIENT_MAC paused " "$USERS_FILE" 2>/dev/null | $BB head -1)
if [ -n "$PAUSED" ]; then
    # Format: MAC STATUS REMAINING TOTAL FMT
    REMAINING=$($BB echo "$PAUSED" | $BB awk '{print $3}')
    TOTAL=$($BB echo "$PAUSED" | $BB awk '{print $4}')
    [ -z "$TOTAL" ] && TOTAL=$REMAINING
    $BB echo "{\"logged_in\":false,\"mac\":\"$CLIENT_MAC\",\"ip\":\"$CLIENT_IP\",\"has_paused\":true,\"remaining\":$REMAINING,\"total\":$TOTAL,${CONN_JSON}}"
else
    $BB echo "{\"logged_in\":false,\"mac\":\"$CLIENT_MAC\",\"ip\":\"$CLIENT_IP\",${CONN_JSON}}"
fi
_unlock
