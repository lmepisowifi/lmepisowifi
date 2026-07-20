#!/bin/sh

BB="busybox"
SESSION_FILE="/tmp/active_sessions.txt"
USERS_FILE="/lmepisowifi/hotspot_data/users.txt"

# Notification templates (for the "session paused" alert). Sourcing is
# harmless if the file is missing — tpl_render just won't be defined and
# the guarded call below is skipped.
[ -f /lmepisowifi/hotspot/notify_templates.sh ] && . /lmepisowifi/hotspot/notify_templates.sh

_unlock() { rm -f /tmp/hotspot_session.lock/pid 2>/dev/null; rmdir /tmp/hotspot_session.lock 2>/dev/null; }
_lock() {
    local i=0
    while ! mkdir /tmp/hotspot_session.lock 2>/dev/null; do
        # Only steal the lock once its holder is provably dead (see
        # lmehspt.sh's _lock for the full explanation) - a flat 5s wait was
        # force-breaking a live holder's lock under normal polling load and
        # letting two writers stomp the same USERS_FILE.tmp at once.
        if [ "$((i % 10))" -eq 0 ] && [ "$i" -gt 0 ]; then
            if [ "$i" -ge 300 ]; then
                $BB rm -f /tmp/hotspot_session.lock/pid 2>/dev/null
                rmdir /tmp/hotspot_session.lock 2>/dev/null
            else
                _HPID=$($BB cat /tmp/hotspot_session.lock/pid 2>/dev/null)
                if [ -z "$_HPID" ] || ! kill -0 "$_HPID" 2>/dev/null; then
                    $BB rm -f /tmp/hotspot_session.lock/pid 2>/dev/null
                    rmdir /tmp/hotspot_session.lock 2>/dev/null
                fi
            fi
        fi
        $BB sleep 0.1 2>/dev/null || sleep 0.1
        i=$((i + 1))
    done
    $BB echo $$ > /tmp/hotspot_session.lock/pid 2>/dev/null
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

# Rewrites USERS_FILE with every line except the one starting "$1 ", but
# refuses to commit if grep couldn't actually read USERS_FILE in the first
# place. `grep -v` exit status: 0 = some lines kept, 1 = every line was a
# genuine match (also what a truly-empty file returns - normal when the
# last user is being removed), 2+ = read/access error. Without this check,
# a single transient flash read glitch produces an empty tmp file that then
# gets moved over USERS_FILE unconditionally, wiping every user's balance
# in one request - no concurrency needed at all. Call this INSIDE _lock.
_users_file_replace_excl() {
    local mac="$1" existed=0 rc=0
    [ -e "$USERS_FILE" ] && existed=1
    $BB grep -v "^${mac} " "$USERS_FILE" > "${USERS_FILE}.tmp" 2>/dev/null || rc=$?
    if [ "$existed" -eq 0 ] || [ "$rc" -le 1 ]; then
        $BB mv "${USERS_FILE}.tmp" "$USERS_FILE"
        return 0
    fi
    rm -f "${USERS_FILE}.tmp" 2>/dev/null
    logger -t lmehspt "users.txt: refused overwrite after read error (rc=$rc) - kept existing file" 2>/dev/null
    return 1
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
    $BB echo '{"ok":false,"error":"no_mac"}'
    exit 0
fi

_lock
NOW=$($BB awk '{print int($1)}' /proc/uptime)
SESSION=$($BB grep "^$CLIENT_MAC " "$SESSION_FILE" 2>/dev/null | $BB head -1)

if [ -z "$SESSION" ]; then
    $BB echo '{"ok":false,"error":"no_session"}'
    exit 0
fi

EXPIRY=$($BB echo "$SESSION" | $BB awk '{print $2}')
TOTAL=$($BB echo "$SESSION" | $BB awk '{print $3}')
REMAINING=$(( EXPIRY - NOW ))
[ -z "$TOTAL" ] && TOTAL=$REMAINING

$BB grep -v "^$CLIENT_MAC " "$SESSION_FILE" > "${SESSION_FILE}.tmp"
$BB mv "${SESSION_FILE}.tmp" "$SESSION_FILE"

# Save paused user to flash master database
PAUSED_OK=0
if [ "$REMAINING" -gt 0 ]; then
    _users_file_replace_excl "$CLIENT_MAC"
    $BB echo "$CLIENT_MAC paused $REMAINING $TOTAL $(_fmt_secs "$REMAINING")" >> "$USERS_FILE"
    PAUSED_OK=1
fi

iptables -t nat -D HOTSPOT -m mac --mac-source "$CLIENT_MAC" -j RETURN 2>/dev/null
iptables -t filter -D HOTSPOT_FWD -m mac --mac-source "$CLIENT_MAC" -j ACCEPT 2>/dev/null

_unlock

# Fire the "session paused" alert — this path is a MANUAL pause (the user
# tapped Pause on the portal). Fire-and-forget; the session_paused event
# key lets the admin mute it from the www2 UI. Skipped if nothing was
# actually paused (no remaining time) or if templates aren't available.
if [ "$PAUSED_OK" = "1" ] && command -v tpl_render >/dev/null 2>&1; then
    _P_ACTIVE=$($BB grep -c '.' "$SESSION_FILE" 2>/dev/null)
    [ -n "$_P_ACTIVE" ] || _P_ACTIVE=0
    _P_MSG=$(tpl_render "$TPL_SESSION_PAUSED" \
        reason "Manually" \
        remainingtime "$(_fmt_secs "$REMAINING")" \
        totaltime "$(_fmt_secs "$TOTAL")" \
        mac "$CLIENT_MAC" \
        activeusrcount "${_P_ACTIVE:-0}")
    ( /lmepisowifi/hotspot/notify.sh "$_P_MSG" "" session_paused "$CLIENT_MAC" >/dev/null 2>&1 </dev/null & )
fi

$BB echo "{\"ok\":true,\"mac\":\"$CLIENT_MAC\"}"
