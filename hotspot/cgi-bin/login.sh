#!/bin/sh

BB="busybox"
SESSION_FILE="/tmp/active_sessions.txt"
USERS_FILE="/lmepisowifi/hotspot_data/users.txt"
VOUCHER_FILE="/lmepisowifi/hotspot_data/vouchers.txt"

# Customizable Telegram/Discord message templates
[ -f /lmepisowifi/hotspot/notify_templates.sh ] && . /lmepisowifi/hotspot/notify_templates.sh

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
_fmt_secs() {
    local s=$1 d=$(( s / 86400 )) h=$(( (s % 86400) / 3600 )) m=$(( (s % 3600) / 60 ))
    if [ "$d" -gt 0 ]; then printf '%dd %dh %dm' "$d" "$h" "$m"
    elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
    else printf '%dm' "$m"; fi
}

# 1. Parse uptime instantly using zero-fork built-ins (Sets global $NOW)
if [ -f /proc/uptime ]; then
    read -r UP_RAW < /proc/uptime
    NOW=${UP_RAW%%.*}
else
    NOW=$(date +%s)
fi

# 2. Output HTTP Headers EXACTLY ONCE
echo "Content-type: application/json"
echo "Cache-Control: no-store"
echo ""

# 3. Zero-Fork Rate Limiter Interceptor
if [ -n "$REMOTE_ADDR" ]; then
    RATE_FILE="/tmp/hs_rate_${REMOTE_ADDR}"
    if [ -f "$RATE_FILE" ]; then
        read -r LAST_ATTEMPT < "$RATE_FILE"
        if [ -n "$LAST_ATTEMPT" ] && [ "$NOW" -le "$LAST_ATTEMPT" ]; then
            # Headers are already printed; just output JSON and quit instantly
            echo '{"ok":false,"error":"cooldown"}'
            exit 0
        fi
    fi
    echo "$NOW" > "$RATE_FILE"
fi

# 4. DOS Protection: Reject overly large payloads early.
CLEN=$($BB echo "$CONTENT_LENGTH" | $BB tr -dc '0-9')
if [ -n "$CLEN" ] && [ "$CLEN" -gt 256 ]; then
    echo '{"ok":false,"error":"invalid"}'
    exit 0
fi

read -n "$CONTENT_LENGTH" POST_DATA

# 5. Extract inputs securely
VOUCHER=$(
    $BB echo "$POST_DATA" \
    | $BB tr '&' '\n' \
    | $BB grep '^voucher=' \
    | $BB cut -d '=' -f 2- \
    | $BB sed 's/+/ /g; s/%20/ /g' \
    | $BB tr -dc 'a-zA-Z0-9\-_' \
    | $BB tr 'a-z' 'A-Z'
)

RESUME=$(
    $BB echo "$POST_DATA" \
    | $BB tr '&' '\n' \
    | $BB grep '^resume=' \
    | $BB cut -d '=' -f 2- \
    | $BB tr -dc '0-9'
)

CLIENT_IP="$REMOTE_ADDR"
CLIENT_MAC=$(
    $BB cat /proc/net/arp \
    | $BB grep "^$CLIENT_IP " \
    | $BB awk '{print $4}' \
    | $BB head -1
)

if [ -z "$CLIENT_MAC" ] || [ "$CLIENT_MAC" = "00:00:00:00:00:00" ]; then
    echo '{"ok":false,"error":"no_mac"}'
    exit 0
fi

# --- Proceed with Core Logic ---
_lock
EXISTING=$($BB grep "^$CLIENT_MAC " "$SESSION_FILE" 2>/dev/null | $BB head -1)
PAUSED=$($BB grep "^$CLIENT_MAC paused " "$USERS_FILE" 2>/dev/null | $BB head -1)

DURATION=0
TOTAL=0

# Handle Resumes First
if [ -n "$RESUME" ] && [ "$RESUME" = "1" ]; then
    if [ -n "$PAUSED" ]; then
        DURATION=$($BB echo "$PAUSED" | $BB awk '{print $3}')
        TOTAL=$($BB echo "$PAUSED" | $BB awk '{print $4}')
        [ -z "$TOTAL" ] && TOTAL=$DURATION
        
        $BB grep -v "^$CLIENT_MAC " "$USERS_FILE" > "${USERS_FILE}.tmp" 2>/dev/null
        $BB mv "${USERS_FILE}.tmp" "$USERS_FILE"
    elif [ -n "$EXISTING" ]; then
        # Stale "Resume Time" click landing after the session was already
        # activated some other way — most commonly: the user inserted coins
        # while the paused-state Resume button was still visible, and
        # coin_result.sh already merged the paused balance into a fresh
        # active session by the time this request arrives. Nothing is
        # actually being paused→resumed here, so acknowledge with the live
        # numbers but skip the rewrite below and the "Session Resumed"
        # Telegram/Discord notification, since no session was ever paused.
        OLD_EXPIRY=$($BB echo "$EXISTING" | $BB awk '{print $2}')
        OLD_TOTAL=$($BB echo "$EXISTING" | $BB awk '{print $3}')
        ALREADY_REMAINING=$(( OLD_EXPIRY - NOW ))
        if [ "$ALREADY_REMAINING" -gt 0 ]; then
            [ -z "$OLD_TOTAL" ] && OLD_TOTAL=$ALREADY_REMAINING
            echo "{\"ok\":true,\"stacked\":false,\"remaining\":$ALREADY_REMAINING,\"total\":$OLD_TOTAL,\"duration\":0,\"mac\":\"$CLIENT_MAC\"}"
            exit 0
        fi
    fi
    
    if [ "$DURATION" -le 0 ]; then
        echo '{"ok":false,"error":"no_paused_session"}'
        exit 0
    fi
    NEW_EXPIRY=$(( NOW + DURATION ))
    NEW_TOTAL=$TOTAL
else
    # Verify regular voucher inputs
    if [ -z "$VOUCHER" ]; then
        echo '{"ok":false,"error":"no_voucher"}'
        exit 0
    fi

    VOUCHER_LINE=$(
        $BB grep -v "^#" "$VOUCHER_FILE" 2>/dev/null \
        | $BB grep "^$VOUCHER " \
        | $BB head -1
    )

    if [ -z "$VOUCHER_LINE" ]; then
        echo '{"ok":false,"error":"invalid"}'
        exit 0
    fi

    DURATION=$($BB echo "$VOUCHER_LINE" | $BB awk '{print $2}')
    VALID_UNTIL=$($BB echo "$VOUCHER_LINE" | $BB awk '{print $3}')
    # Remember the voucher's own duration before any stacking mutates DURATION
    VOUCHER_TIME=$DURATION

    if [ -n "$VALID_UNTIL" ] && [ "$VALID_UNTIL" != "" ]; then
        NOW_EPOCH=$(date +%s 2>/dev/null)
        if [ -n "$NOW_EPOCH" ] && [ "$NOW_EPOCH" -gt "$VALID_UNTIL" ]; then
            echo '{"ok":false,"error":"expired"}'
            exit 0
        fi
    fi

    $BB grep -v "^$VOUCHER " "$VOUCHER_FILE" > "${VOUCHER_FILE}.tmp"
    $BB mv "${VOUCHER_FILE}.tmp" "$VOUCHER_FILE"
fi

STACKED=false
NEED_FW_RULES=true

if [ -z "$RESUME" ]; then
    if [ -n "$EXISTING" ]; then
        OLD_EXPIRY=$($BB echo "$EXISTING" | $BB awk '{print $2}')
        OLD_TOTAL=$($BB echo "$EXISTING" | $BB awk '{print $3}')
        [ -z "$OLD_TOTAL" ] && OLD_TOTAL=$(( OLD_EXPIRY - NOW ))

        if [ "$OLD_EXPIRY" -gt "$NOW" ]; then
            NEW_EXPIRY=$(( OLD_EXPIRY + DURATION ))
            NEW_TOTAL=$(( OLD_TOTAL + DURATION ))
            STACKED=true
            NEED_FW_RULES=false
        else
            NEW_EXPIRY=$(( NOW + DURATION ))
            NEW_TOTAL=$DURATION
        fi
    else
        VOUCHER_DURATION=$DURATION
        if [ -n "$PAUSED" ]; then
            PAUSED_DURATION=$($BB echo "$PAUSED" | $BB awk '{print $3}')
            PAUSED_TOTAL=$($BB echo "$PAUSED" | $BB awk '{print $4}')
            [ -z "$PAUSED_TOTAL" ] && PAUSED_TOTAL=$PAUSED_DURATION
            
            DURATION=$(( VOUCHER_DURATION + PAUSED_DURATION ))
            NEW_TOTAL=$(( PAUSED_TOTAL + VOUCHER_DURATION ))
            
            $BB grep -v "^$CLIENT_MAC " "$USERS_FILE" > "${USERS_FILE}.tmp" 2>/dev/null
            $BB mv "${USERS_FILE}.tmp" "$USERS_FILE"
            STACKED=true
        else
            NEW_TOTAL=$VOUCHER_DURATION
        fi
        NEW_EXPIRY=$(( NOW + DURATION ))
    fi
fi

$BB grep -v "^$CLIENT_MAC " "$SESSION_FILE" > "${SESSION_FILE}.tmp" 2>/dev/null
$BB mv "${SESSION_FILE}.tmp" "$SESSION_FILE"

# Format: MAC EXPIRY TOTAL
$BB echo "$CLIENT_MAC $NEW_EXPIRY $NEW_TOTAL" >> "$SESSION_FILE"

# Immediately write state to persistent Flash database as 'active'
$BB grep -v "^$CLIENT_MAC " "$USERS_FILE" > "${USERS_FILE}.tmp" 2>/dev/null
$BB mv "${USERS_FILE}.tmp" "$USERS_FILE"
REMAINING_SECS=$(( NEW_EXPIRY - NOW ))
$BB echo "$CLIENT_MAC active $REMAINING_SECS $NEW_TOTAL $(_fmt_secs "$REMAINING_SECS")" >> "$USERS_FILE"

if [ "$NEED_FW_RULES" = "true" ]; then
    iptables -t nat -I HOTSPOT 1 -m mac --mac-source "$CLIENT_MAC" -j RETURN 2>/dev/null
    iptables -t filter -I HOTSPOT_FWD 1 -m mac --mac-source "$CLIENT_MAC" -j ACCEPT 2>/dev/null
fi

REMAINING=$(( NEW_EXPIRY - NOW ))
echo "{\"ok\":true,\"stacked\":$STACKED,\"remaining\":$REMAINING,\"total\":$NEW_TOTAL,\"duration\":$DURATION,\"mac\":\"$CLIENT_MAC\"}"

# --- Notifications (resume / voucher conversion) ---------------------------
# Reached only on success (all failure paths exit earlier). Fire-and-forget.
_fmt_dur() {
    $BB awk -v s="$1" 'BEGIN{
        s=int(s); if(s<0)s=0
        d=int(s/86400); s=s%86400
        h=int(s/3600);  s=s%3600
        m=int(s/60)
        out=""
        if(d>0){ out=out d"d " }
        if(h>0||d>0){ out=out h"h " }
        out=out m"m"
        printf "%s", out
    }'
}
if [ "$RESUME" = "1" ]; then
    _ACTIVE=$($BB grep -c '.' "$SESSION_FILE" 2>/dev/null)
    [ -n "$_ACTIVE" ] || _ACTIVE=0
    N_MSG=$(tpl_render "$TPL_SESSION_RESUMED" \
        remainingtime "$(_fmt_dur ${REMAINING:-0})" totaltime "$(_fmt_dur ${NEW_TOTAL:-0})" \
        mac "$CLIENT_MAC" activeusrcount "${_ACTIVE:-0}")
    ( /lmepisowifi/hotspot/notify.sh "$N_MSG" "" session_resumed "$CLIENT_MAC" >/dev/null 2>&1 </dev/null & )
elif [ -n "$VOUCHER" ]; then
    N_MSG=$(tpl_render "$TPL_VOUCHER_REDEEMED" \
        voucher "$VOUCHER" addedtime "$(_fmt_dur ${VOUCHER_TIME:-0})" \
        totaltime "$(_fmt_dur ${NEW_TOTAL:-0})" remainingtime "$(_fmt_dur ${REMAINING:-0})" mac "$CLIENT_MAC")
    ( /lmepisowifi/hotspot/notify.sh "$N_MSG" "" voucher_redeemed >/dev/null 2>&1 </dev/null & )
fi
# ---------------------------------------------------------------------------
