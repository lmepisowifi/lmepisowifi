#!/bin/sh
# Insert Coin CGI backend
# GET ?action=config           → returns enabled status & checks for resume
# GET ?action=start            → locks slot, queues user, or returns SID
# GET ?action=poll&sid=SID     → returns live amount or final result
# GET ?action=cancel&sid=SID   → tells NodeMCU to end session immediately or leaves queue

[ -f /tmp/coin_config.env ] && . /tmp/coin_config.env

printf 'Content-Type: application/json\r\n'
printf 'Cache-Control: no-cache, no-store\r\n'
printf '\r\n'

_err() { printf '{"error":"%s"}\n' "$1"; exit 0; }
_ok()  { printf '%s\n' "$1";           exit 0; }
_md5() { printf '%s' "$1" | md5sum | awk '{print $1}'; }

get_qs() {
    printf '%s' "$QUERY_STRING" | tr '&' '\n' | grep "^${1}=" | sed 's/^[^=]*=//' | head -1
}

ACTION=$(get_qs "action")

# --- Get client MAC from ARP — server-side, client cannot forge this ---
CLIENT_MAC=$(awk -v ip="$REMOTE_ADDR" -v br="$HOTSPOT_BR" \
    '$1==ip && $6==br {print tolower($4); exit}' /proc/net/arp 2>/dev/null)

# config action works regardless of enabled state so the JS can show/hide the button
if [ "$ACTION" = "config" ]; then
    RESUME_FLAG="false"
    PENDING_FLAG="false"

    # Expose to frontend if this user has an ongoing session that survived a page reload
    if [ -n "$CLIENT_MAC" ]; then
        if [ -f /tmp/coin_lock ]; then
            LOCK_MAC=$(awk '{print $3}' /tmp/coin_lock)
            LOCK_STATE=$(awk '{print $4}' /tmp/coin_lock)

            if [ "$LOCK_MAC" = "$CLIENT_MAC" ]; then
                if [ "$LOCK_STATE" = "ACTIVE" ]; then
                    RESUME_FLAG="true"
                elif [ "$LOCK_STATE" = "PENDING" ] || [ "$LOCK_STATE" = "CANCELLING" ]; then
                    # PENDING: the original "start" request (the one talking to
                    # the NodeMCU) is still in flight server-side — most likely
                    # because the page got reloaded right after the button
                    # was clicked, before that request could finish and
                    # flip the lock to ACTIVE. Tell the frontend to retry
                    # shortly instead of silently giving up here, which
                    # used to require a manual second click/reload.
                    # CANCELLING: a cancel/done was just issued and NodeMCU
                    # hasn't confirmed the teardown yet — same "wait a beat
                    # and retry" treatment, so a reload right after closing
                    # the modal doesn't get offered a stale resume.
                    PENDING_FLAG="true"
                fi
            fi
        fi
        # If not actively locked, see if they were in the middle of waiting in the queue
        if [ "$RESUME_FLAG" = "false" ] && [ -f /tmp/coin_queue.txt ]; then
            if $BB grep -q "^$CLIENT_MAC " /tmp/coin_queue.txt 2>/dev/null; then
                RESUME_FLAG="true"
            fi
        fi
    fi

    if [ -f /tmp/coin_enabled ]; then
        SUSPENDED_FLAG="false"
        COOLDOWN_REMAINING=0
        if [ -n "$CLIENT_MAC" ] && [ -f /tmp/coin_strikes.txt ]; then
            SUSP_DATA=$($BB grep "^$CLIENT_MAC " /tmp/coin_strikes.txt 2>/dev/null)
            if [ -n "$SUSP_DATA" ]; then
                SUSP_STRIKES=$(printf '%s' "$SUSP_DATA" | $BB awk '{print $2}')
                SUSP_LAST=$(printf '%s'   "$SUSP_DATA" | $BB awk '{print $3}')
                SUSP_NOW=$(awk '{print int($1)}' /proc/uptime)
                _ST=${COIN_STRIKE_THRESHOLD:-3}
                _CD=${COIN_COOLDOWN:-300}
                if [ "${SUSP_STRIKES:-0}" -ge "$_ST" ]; then
                    _SINCE=$(( SUSP_NOW - SUSP_LAST ))
                    if [ "$_SINCE" -lt "$_CD" ]; then
                        SUSPENDED_FLAG="true"
                        COOLDOWN_REMAINING=$(( _CD - _SINCE ))
                    fi
                fi
            fi
        fi
        _ok "{\"enabled\":true,\"timeout\":${COIN_TIMEOUT},\"rates\":\"${COIN_RATES}\",\"resume\":${RESUME_FLAG},\"pending\":${PENDING_FLAG},\"suspended\":${SUSPENDED_FLAG},\"cooldown_remaining\":${COOLDOWN_REMAINING}}"
    else
        _ok '{"enabled":false}'
    fi
fi

[ -f /tmp/coin_enabled ] || _err "Coin feature not available"
[ -n "$CLIENT_MAC" ] || _err "Cannot identify device"

# --- Greedy time calculator: largest-denomination first ---
_calc_time() {
    printf '%s %s\n' "$COIN_RATES" "$1" | awk '
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
    }'
}

case "$ACTION" in

# ----------------------------------------------------------------
start)
    NOW=$(awk '{print int($1)}' /proc/uptime)
    touch /tmp/coin_strikes.txt

    # --- DoS PREVENTION 3: ANTI-GRIEFING STRIKE SYSTEM ---
    STRIKE_DATA=$($BB grep "^$CLIENT_MAC " /tmp/coin_strikes.txt 2>/dev/null)
    if [ -n "$STRIKE_DATA" ]; then
        STRIKES=$(printf '%s' "$STRIKE_DATA" | $BB awk '{print $2}')
        LAST_STRIKE=$(printf '%s' "$STRIKE_DATA" | $BB awk '{print $3}')
        _ST=${COIN_STRIKE_THRESHOLD:-3}
        _CD=${COIN_COOLDOWN:-300}
        if [ "$STRIKES" -ge "$_ST" ]; then
            _SINCE=$(( NOW - LAST_STRIKE ))
            if [ "$_SINCE" -lt "$_CD" ]; then
                _WAIT_MINS=$(( (_CD - _SINCE + 59) / 60 ))
                _err "Temporarily suspended. Please wait ${_WAIT_MINS} more minute(s)."
            else
                $BB grep -v "^$CLIENT_MAC " /tmp/coin_strikes.txt > /tmp/cs.tmp 2>/dev/null
                $BB mv /tmp/cs.tmp /tmp/coin_strikes.txt
            fi
        fi
    fi

    LOCK_FILE="/tmp/coin_lock"
    QFILE="/tmp/coin_queue.txt"

    # 1. Clean stale queue entries (>10s old)
    if [ -f "$QFILE" ]; then
        $BB awk -v now="$NOW" 'now - $2 < 10 {print $0}' "$QFILE" > "${QFILE}.tmp"
        $BB mv "${QFILE}.tmp" "$QFILE"
    fi

    # 2. Check Lock
    LOCKED=0
    if [ -f "$LOCK_FILE" ]; then
        LOCK_SID=$(awk '{print $1}' "$LOCK_FILE")
        LOCK_TIME=$(awk '{print $2}' "$LOCK_FILE")
        LOCK_MAC=$(awk '{print $3}' "$LOCK_FILE")
        LOCK_STATE=$(awk '{print $4}' "$LOCK_FILE")
        LOCK_AGE=$(( NOW - LOCK_TIME ))

        # A CANCELLING lock should clear itself quickly — NodeMCU normally
        # finalizes within about a second of a cancel/done. Don't make a
        # client who immediately re-clicks "Insert Coin" wait up to
        # COIN_TIMEOUT+15s just because the teardown POST hasn't landed yet
        # (or, if NodeMCU lost power mid-cancel, never will).
        if [ "$LOCK_STATE" = "CANCELLING" ]; then
            STALE_AFTER=10
        else
            STALE_AFTER=$(( COIN_TIMEOUT + 15 ))
        fi

        if [ "$LOCK_AGE" -lt "$STALE_AFTER" ]; then
            if [ "$LOCK_MAC" = "$CLIENT_MAC" ]; then
                if [ "$LOCK_STATE" = "PENDING" ]; then
                    _err "Connecting to coin slot, please wait a moment..."
                elif [ "$LOCK_STATE" = "CANCELLING" ]; then
                    _err "Finishing previous session, please wait a moment..."
                else
                    # It's me, returning my existing confirmed session — but
                    # only if NodeMCU actually still recognizes this sid as
                    # its live, active session. If NodeMCU lost power (or
                    # rebooted, or already tore the session down), it won't
                    # answer with a validly-signed reply, and we must not
                    # hand back a fabricated "resumed" countdown for a coin
                    # slot that isn't actually listening for coins anymore —
                    # drop the stale lock/session and fall through below to
                    # open a brand new one instead.
                    RESUME_AMOUNT=0
                    RESUME_REMAINING=$COIN_TIMEOUT
                    R_VERIFIED=0
                    R_POLL_SIG=$(_md5 "${COIN_PSK}:${LOCK_SID}:poll")
                    R_LIVE=$(wget -q -T 2 -O - \
                        "http://${NODEMCU_IP}:${NODEMCU_PORT}/status?sid=${LOCK_SID}&sig=${R_POLL_SIG}" \
                        2>/dev/null)
                    if [ -n "$R_LIVE" ]; then
                        R_RAW_AMT=$(printf '%s' "$R_LIVE" | grep -o '"amount":[0-9]*' | grep -o '[0-9]*$')
                        R_RAW_SIG=$(printf '%s' "$R_LIVE" | grep -o '"sig":"[^"]*"' | awk -F'"' '{print $4}')
                        R_EXP_SIG=$(_md5 "${COIN_PSK}:${LOCK_SID}:${R_RAW_AMT}:status")
                        if [ -n "$R_RAW_SIG" ] && [ "$R_RAW_SIG" = "$R_EXP_SIG" ]; then
                            R_VERIFIED=1
                            RESUME_AMOUNT=${R_RAW_AMT:-0}
                            R_RAW_REM=$(printf '%s' "$R_LIVE" | grep -o '"remaining":[0-9]*' | grep -o '[0-9]*$')
                            [ -n "$R_RAW_REM" ] && RESUME_REMAINING=$R_RAW_REM
                        fi
                    fi

                    if [ "$R_VERIFIED" -eq 1 ]; then
                        RESUME_MINUTES=$(_calc_time "$RESUME_AMOUNT")
                        _ok "{\"sid\":\"$LOCK_SID\",\"timeout\":$COIN_TIMEOUT,\"remaining\":$RESUME_REMAINING,\"amount\":$RESUME_AMOUNT,\"minutes\":$RESUME_MINUTES,\"resumed\":true}"
                    fi
                    rm -f "$LOCK_FILE" "/tmp/coin_sessions/${LOCK_SID}" \
                        "/tmp/coin_sessions/${LOCK_SID}.miss" "/tmp/coin_sessions/${LOCK_SID}.amt"
                fi
            else
                LOCKED=1
            fi
        else
            rm -f "$LOCK_FILE" "/tmp/coin_sessions/${LOCK_SID}" \
                "/tmp/coin_sessions/${LOCK_SID}.miss" "/tmp/coin_sessions/${LOCK_SID}.amt"
        fi
    fi

    # 3. Check Queue & Determine Flow
    if [ "$LOCKED" -eq 0 ]; then
        # Check if anyone is waiting in line ahead of us
        FIRST_MAC=$($BB head -n 1 "$QFILE" 2>/dev/null | $BB awk '{print $1}')
        if [ -n "$FIRST_MAC" ] && [ "$FIRST_MAC" != "$CLIENT_MAC" ]; then
            LOCKED=1 # Someone else is first in line
        fi
    fi

    if [ "$LOCKED" -eq 1 ]; then
        # Enqueue user / Refresh their spot in line
        $BB grep -v "^$CLIENT_MAC " "$QFILE" > "${QFILE}.tmp" 2>/dev/null
        echo "$CLIENT_MAC $NOW" >> "${QFILE}.tmp"
        $BB mv "${QFILE}.tmp" "$QFILE"
        
        POS=$($BB awk -v mac="$CLIENT_MAC" '$1==mac {print NR}' "$QFILE")
        _ok "{\"queued\":true,\"position\":$POS}"
    fi

    # If I am here, it's my turn. Remove me from queue if I was in it.
    if [ -f "$QFILE" ]; then
        $BB grep -v "^$CLIENT_MAC " "$QFILE" > "${QFILE}.tmp" 2>/dev/null
        $BB mv "${QFILE}.tmp" "$QFILE"
    fi

    # Generate SID: uptime + MAC + PID + random → md5 → first 16 hex chars
    SID=$(printf '%s%s%d%d' \
        "$(awk '{print $1$2}' /proc/uptime)" \
        "$CLIENT_MAC" "$$" "$RANDOM" \
        | md5sum | awk '{print substr($1,1,16)}')

    START_SIG=$(_md5 "${COIN_PSK}:${SID}:start")

    # Bind this SID to the client's MAC + creation time + last-seen heartbeat.
    # last_seen starts equal to creation time and gets refreshed on every poll
    # that gets a verified live response from NodeMCU — this is what lets a
    # rolling (per-coin-reset) session run past the original window without
    # being treated as abandoned.
    printf '%s %s %s\n' "$CLIENT_MAC" "$NOW" "$NOW" > "/tmp/coin_sessions/${SID}"

    # Write a PENDING lock. Prevents parallel requests, but ignores automatic UI page reloads.
    printf '%s %s %s %s\n' "$SID" "$NOW" "$CLIENT_MAC" "PENDING" > "$LOCK_FILE"

    # Contact NodeMCU — it verifies START_SIG before accepting coins
    RESP=$(wget -q -T 5 -O - \
        "http://${NODEMCU_IP}:${NODEMCU_PORT}/start?sid=${SID}&sig=${START_SIG}&timeout=${COIN_TIMEOUT}" \
        2>/dev/null)

    if printf '%s' "$RESP" | grep -q '"ok"'; then
        OK_VAL=$(printf '%s' "$RESP" | grep -o '"ok":[a-z]*' | grep -o '[a-z]*$')
        [ "$OK_VAL" = "true" ] || {
            rm -f "/tmp/coin_sessions/${SID}" "$LOCK_FILE"
            _err "System rejected Insert Coin attempt."
        }
        
        # Success! Upgrade lock to ACTIVE
        printf '%s %s %s %s\n' "$SID" "$NOW" "$CLIENT_MAC" "ACTIVE" > "$LOCK_FILE"
        
        _ok "{\"sid\":\"$SID\",\"timeout\":$COIN_TIMEOUT}"
    else
        rm -f "/tmp/coin_sessions/${SID}" "$LOCK_FILE"
        _err "Coinslot Offline, notify the vendo owner if this persists."
    fi
    ;;

# ----------------------------------------------------------------
poll)
    SID=$(get_qs "sid")
    [ -n "$SID" ] || _err "Missing sid"
    printf '%s' "$SID" | grep -qE '^[0-9a-f]{16}$' || _err "Invalid sid"

    SESSION_PATH="/tmp/coin_sessions/${SID}"
    RESULT_PATH="/tmp/coin_sessions/${SID}.result"
    NOW=$(awk '{print int($1)}' /proc/uptime)

    # NodeMCU already posted the result
    if [ -f "$RESULT_PATH" ]; then
        AMOUNT=$(awk '{print $1}' "$RESULT_PATH")
        MINUTES=$(awk '{print $2}' "$RESULT_PATH")
        _ok "{\"status\":\"complete\",\"amount\":${AMOUNT},\"minutes\":${MINUTES}}"
    fi

    # Session file must exist and belong to this client
    [ -f "$SESSION_PATH" ] || _ok '{"status":"expired","amount":0,"minutes":0}'
    SESSION_MAC=$(awk '{print $1}' "$SESSION_PATH")
    [ "$SESSION_MAC" = "$CLIENT_MAC" ] || _err "Session mismatch"

    CREATED_AT=$(awk '{print $2}' "$SESSION_PATH")
    LAST_SEEN=$(awk '{print ($3==""?$2:$3)}' "$SESSION_PATH")
    SINCE_SEEN=$(( NOW - LAST_SEEN ))

    # Fallback estimate in case NodeMCU doesn't answer this particular poll —
    # overwritten below with NodeMCU's own authoritative value when it does.
    REMAINING=$(( COIN_TIMEOUT - (NOW - CREATED_AT) ))
    [ "$REMAINING" -lt 0 ] && REMAINING=0

    # Hard expiry is based on time-since-last-successful-contact, not time
    # since the session was created. A rolling (per-coin-reset) session can
    # legitimately run far longer than COIN_TIMEOUT as long as NodeMCU keeps
    # answering polls — only give up once contact has actually gone stale.
    if [ "$SINCE_SEEN" -gt $(( COIN_TIMEOUT + 25 )) ]; then
        rm -f "$SESSION_PATH" "/tmp/coin_lock"
        _ok '{"status":"expired","amount":0,"minutes":0}'
    fi

    # Query NodeMCU for live coin count — verify its response signature
    MISS_PATH="${SESSION_PATH}.miss"
    AMT_PATH="${SESSION_PATH}.amt"
    POLL_SIG=$(_md5 "${COIN_PSK}:${SID}:poll")
    LIVE=$(wget -q -T 2 -O - \
        "http://${NODEMCU_IP}:${NODEMCU_PORT}/status?sid=${SID}&sig=${POLL_SIG}" \
        2>/dev/null)

    LIVE_AMOUNT=$(cat "$AMT_PATH" 2>/dev/null)
    LIVE_AMOUNT=${LIVE_AMOUNT:-0}
    LIVE_OK=0
    if [ -n "$LIVE" ]; then
        RAW_AMT=$(printf '%s' "$LIVE" | grep -o '"amount":[0-9]*' | grep -o '[0-9]*$')
        RAW_SIG=$(printf '%s' "$LIVE" | grep -o '"sig":"[^"]*"' | awk -F'"' '{print $4}')
        EXP_SIG=$(_md5 "${COIN_PSK}:${SID}:${RAW_AMT}:status")
        # Only trust the amount if NodeMCU signed it with the PSK
        if [ -n "$RAW_SIG" ] && [ "$RAW_SIG" = "$EXP_SIG" ]; then
            LIVE_OK=1
            LIVE_AMOUNT=${RAW_AMT:-0}
            echo "$LIVE_AMOUNT" > "$AMT_PATH" 2>/dev/null
            # NodeMCU is alive and confirms this session is still active there
            # — refresh the heartbeat so a long rolling session stays open.
            printf '%s %s %s\n' "$SESSION_MAC" "$CREATED_AT" "$NOW" \
                > "/tmp/coin_sessions/${SID}.tmp" 2>/dev/null \
                && mv "/tmp/coin_sessions/${SID}.tmp" "$SESSION_PATH"
            RAW_REM=$(printf '%s' "$LIVE" | grep -o '"remaining":[0-9]*' | grep -o '[0-9]*$')
            [ -n "$RAW_REM" ] && REMAINING=$RAW_REM
        fi
    fi

    if [ "$LIVE_OK" -eq 1 ]; then
        rm -f "$MISS_PATH"
    else
        # NodeMCU didn't answer this poll. Tolerate a few consecutive misses
        # (polling runs about once a second, so ~4s) to absorb a one-off wifi
        # hiccup, but don't wait the full COIN_TIMEOUT+25s window the way the
        # generic staleness check above does — that's exactly what let the
        # coin slot keep looking "active" (and inviting more coins) for up
        # to a minute after it actually lost power.
        MISSES=$(cat "$MISS_PATH" 2>/dev/null)
        MISSES=$(( ${MISSES:-0} + 1 ))
        echo "$MISSES" > "$MISS_PATH" 2>/dev/null
        if [ "$MISSES" -ge 4 ]; then
            rm -f "$SESSION_PATH" "$MISS_PATH" "$AMT_PATH" "/tmp/coin_lock"
            _ok "{\"status\":\"expired\",\"amount\":${LIVE_AMOUNT},\"minutes\":$(_calc_time "$LIVE_AMOUNT")}"
        fi
    fi

    PREVIEW=$(_calc_time "$LIVE_AMOUNT")
    _ok "{\"status\":\"active\",\"amount\":${LIVE_AMOUNT},\"minutes\":${PREVIEW},\"remaining\":${REMAINING}}"
    ;;

# ----------------------------------------------------------------
cancel)
    NOW=$(awk '{print int($1)}' /proc/uptime)

    # Always remove the user from the waiting queue first
    if [ -f "/tmp/coin_queue.txt" ]; then
        $BB grep -v "^$CLIENT_MAC " /tmp/coin_queue.txt > /tmp/cq.tmp 2>/dev/null
        $BB mv /tmp/cq.tmp /tmp/coin_queue.txt
    fi

    SID=$(get_qs "sid")
    if [ -z "$SID" ]; then
        # Request just wanted to leave the queue. Nothing more to cancel.
        _ok '{"ok":true,"msg":"left_queue"}'
    fi

    printf '%s' "$SID" | grep -qE '^[0-9a-f]{16}$' || _err "Invalid sid"
    SESSION_PATH="/tmp/coin_sessions/${SID}"

    # If session already ended (result posted or file gone), that's fine
    [ -f "$SESSION_PATH" ] || _ok '{"ok":true,"msg":"already_ended"}'

    # Only the client who started the session can cancel it
    SESSION_MAC=$(awk '{print $1}' "$SESSION_PATH")
    [ "$SESSION_MAC" = "$CLIENT_MAC" ] || _err "Session mismatch"

    # Signed cancel request — NodeMCU verifies md5(PSK:SID:cancel) before
    # ending the session. The NodeMCU finalizes asynchronously (its own
    # loop() picks this up, not this handler) and POSTs the result to
    # coin_result.sh a moment later — so we deliberately do NOT delete
    # SESSION_PATH/coin_lock here. coin_result.sh is the only place that
    # ever deletes them, on every path (zero-amount and success). Deleting
    # them here would race ahead of that POST and cause "Session not found".
    #
    # We DO flip the lock to CANCELLING right now, though — otherwise a
    # client that closes the modal and immediately hits "Insert Coin" again
    # lands back in the start-action's ACTIVE branch, and NodeMCU can still
    # answer /status validly for a session that's mid-teardown (it only
    # goes quiet once endSession() finishes settling trailing pulses),
    # producing a resumed session with a countdown for something that's
    # actually being cancelled. CANCELLING makes start-action tell the
    # client to wait a beat instead of resuming.
    LOCK_FILE="/tmp/coin_lock"
    if [ -f "$LOCK_FILE" ]; then
        L_SID=$(awk '{print $1}' "$LOCK_FILE")
        [ "$L_SID" = "$SID" ] && \
            printf '%s %s %s %s\n' "$SID" "$NOW" "$CLIENT_MAC" "CANCELLING" > "$LOCK_FILE"
    fi

    CANCEL_SIG=$(_md5 "${COIN_PSK}:${SID}:cancel")
    wget -q -T 5 -O - \
        "http://${NODEMCU_IP}:${NODEMCU_PORT}/cancel?sid=${SID}&sig=${CANCEL_SIG}" \
        2>/dev/null

    _ok '{"ok":true}'
    ;;

# ----------------------------------------------------------------
# NOTE: A "reset" action used to live here (fetch nonce, sign with
# COIN_PSK, tell NodeMCU to wipe its WiFi config and drop back into
# the open PisoWifi-Setup AP). It was removed: this CGI is reachable
# by every connected hotspot client with no session/ownership check
# of any kind, and nothing in the frontend ever called it — so it
# was a zero-benefit, unauthenticated "brick the coin acceptor"
# button sitting on the public captive portal. coin.sh knowing
# COIN_PSK makes it the trusted side of that relationship, not a
# gate — the PSK signs requests *to* NodeMCU, it doesn't verify
# *who's* asking coin.sh to send them. If a reset feature is needed,
# it belongs in the authenticated www2 admin panel (session-checked),
# not here.

*)
    _err "Unknown action"
    ;;
esac