#!/bin/sh
# ============================================================
# detect.sh — Captive portal connectivity check responder
#
# Called for all OS connectivity probe URLs:
#   /generate_204, /gen_204          (Android / Chrome)
#   /hotspot-detect.html, /success.* (iOS / macOS)
#   /ncsi.txt                        (Windows NCSI)
#   /connecttest.txt                 (Windows modern)
#   /redirect                        (Windows redirect test)
#   /kindle-wifi/wifistub.html       (Kindle)
#
# Authenticated client  → returns the expected "success" response
#                          so the OS immediately marks internet available
# Unauthenticated/paused → MikroTik-style HTTP 302 + meta-refresh
#                          redirect to the captive portal, passing
#                          the original URL as ?orig= so the portal
#                          can navigate back to it after login,
#                          triggering the final OS connectivity accept.
# ============================================================

BB="busybox"
SESSION_FILE="/lmepisowifi/hotspot_data/active_sessions.txt"
PAUSED_FILE="/lmepisowifi/hotspot_data/paused_sessions.txt"
WHITELIST_FILE="/lmepisowifi/hotspot_data/whitelist.txt"

[ -f /tmp/coin_config.env ] && . /tmp/coin_config.env
PORTAL_IP="${PORTAL_IP:-192.168.99.1}"
PORTAL_PORT="${PORTAL_PORT:-808}"
PORTAL_URL="http://${PORTAL_IP}:${PORTAL_PORT}/"

# ── Identify client ───────────────────────────────────────────
CLIENT_IP="$REMOTE_ADDR"

# Read MAC from ARP cache; /proc/net/arp field 4 is the HW address.
# We only match complete entries (flags field = 0x2 = ATF_COM).
CLIENT_MAC=$(
    $BB awk -v ip="$CLIENT_IP" \
        '$1==ip && $3=="0x2" { print tolower($4); exit }' \
        /proc/net/arp 2>/dev/null
)
# Strip colons for whitelist comparison
CLIENT_MAC_NC=$(printf '%s' "$CLIENT_MAC" | $BB tr -d ':')

# ── Check whitelist ───────────────────────────────────────────
is_whitelisted() {
    [ -n "$CLIENT_MAC_NC" ] || return 1
    [ -f "$WHITELIST_FILE" ] || return 1
    $BB grep -qi "^${CLIENT_MAC_NC}$" "$WHITELIST_FILE"
}

# ── Check active session ──────────────────────────────────────
UPTIME=$($BB awk '{print int($1)}' /proc/uptime)
HAS_SESSION=0
HAS_PAUSED=0

if [ -n "$CLIENT_MAC" ] && [ "$CLIENT_MAC" != "00:00:00:00:00:00" ]; then
    if [ -f "$SESSION_FILE" ]; then
        while read -r mac expiry _rest; do
            [ "$mac" = "$CLIENT_MAC" ] || continue
            [ "$expiry" -gt "$UPTIME" ] && HAS_SESSION=1
            break
        done < "$SESSION_FILE"
    fi
    if [ "$HAS_SESSION" = "0" ] && [ -f "$PAUSED_FILE" ]; then
        $BB grep -q "^$CLIENT_MAC " "$PAUSED_FILE" 2>/dev/null && HAS_PAUSED=1
    fi
    is_whitelisted && HAS_SESSION=1
fi

# ── Determine URI type (strip query string) ───────────────────
URI_PATH=$(printf '%s' "${REQUEST_URI:-/}" | $BB sed 's/?.*//')

# ── Respond ───────────────────────────────────────────────────
if [ "$HAS_SESSION" = "1" ]; then
    # ── AUTHENTICATED: return the exact response each OS expects ──

    case "$URI_PATH" in

        # Android / Chrome OS (expects HTTP 204 No Content)
        */generate_204|*/gen_204|*/generate204)
            printf "Status: 204 No Content\r\n"
            printf "Cache-Control: no-cache, no-store\r\n"
            printf "\r\n"
            ;;

        # Windows NCSI (expects exactly "Microsoft NCSI" plain text)
        */ncsi.txt)
            printf "Status: 200 OK\r\n"
            printf "Content-Type: text/plain\r\n"
            printf "Cache-Control: no-cache, no-store\r\n"
            printf "\r\n"
            printf "Microsoft NCSI"
            ;;

        # Windows modern (expects exactly "Microsoft Connect Test")
        */connecttest.txt)
            printf "Status: 200 OK\r\n"
            printf "Content-Type: text/plain\r\n"
            printf "Cache-Control: no-cache, no-store\r\n"
            printf "\r\n"
            printf "Microsoft Connect Test"
            ;;

        # Windows redirect test (expects a redirect to abswebsite — just 200 is fine)
        */redirect)
            printf "Status: 200 OK\r\n"
            printf "Content-Type: text/plain\r\n"
            printf "Cache-Control: no-cache, no-store\r\n"
            printf "\r\n"
            printf "Microsoft Connect Test"
            ;;

        # iOS / macOS (expects "<HTML><HEAD><TITLE>Success</TITLE>…</HTML>")
        */hotspot-detect.html|*/success.txt|*/success.html|*/library/test/success.html)
            printf "Status: 200 OK\r\n"
            printf "Content-Type: text/html\r\n"
            printf "Cache-Control: no-cache, no-store\r\n"
            printf "\r\n"
            printf "<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>"
            ;;

        # Kindle
        */kindle-wifi/wifistub.html)
            printf "Status: 200 OK\r\n"
            printf "Content-Type: text/html\r\n"
            printf "Cache-Control: no-cache, no-store\r\n"
            printf "\r\n"
            printf "<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>"
            ;;

        # Unknown probe — safe default is 204 (no content = connected)
        *)
            printf "Status: 204 No Content\r\n"
            printf "Cache-Control: no-cache, no-store\r\n"
            printf "\r\n"
            ;;
    esac

else
    # ── UNAUTHENTICATED (or paused): MikroTik-style redirect ──
    #
    # Build the original URL from the HTTP Host header.
    # BusyBox httpd passes the original Host: header in HTTP_HOST even
    # after DNAT, so we can reconstruct "http://clients3.google.com/generate_204"
    # and pass it back to the portal as ?orig=... After the user logs in,
    # the portal navigates to this URL; since the iptables RETURN rule is
    # now in place, the request goes to the real server and returns the
    # correct response (204 / "Success" / etc.), which signals the OS.

    ORIG_HOST="$HTTP_HOST"

    # If Host matches our own portal, skip the orig param (avoid loops)
    if [ -n "$ORIG_HOST" ] && \
       [ "$ORIG_HOST" != "${PORTAL_IP}:${PORTAL_PORT}" ] && \
       [ "$ORIG_HOST" != "$PORTAL_IP" ]; then

        ORIG_URL="http://${ORIG_HOST}${URI_PATH}"

        # Minimal URL-encode for the orig= query parameter
        # (encode chars that would break the query string)
        ORIG_ENC=$(printf '%s' "$ORIG_URL" \
            | $BB sed \
                -e 's/%/%25/g' \
                -e 's/ /%20/g' \
                -e 's/!/%21/g' \
                -e 's/"/%22/g' \
                -e 's/#/%23/g' \
                -e 's/\$/%24/g' \
                -e 's/&/%26/g' \
                -e "s/'/%27/g" \
                -e 's/(/%28/g' \
                -e 's/)/%29/g' \
                -e 's/\*/%2A/g' \
                -e 's/+/%2B/g' \
                -e 's/,/%2C/g' \
                -e 's|/|%2F|g' \
                -e 's/:/%3A/g' \
                -e 's/;/%3B/g' \
                -e 's/=/%3D/g' \
                -e 's/?/%3F/g' \
                -e 's/@/%40/g')

        REDIR_URL="${PORTAL_URL}?orig=${ORIG_ENC}"
    else
        REDIR_URL="${PORTAL_URL}"
    fi

    # Append paused hint so the portal can immediately show resume state
    [ "$HAS_PAUSED" = "1" ] && REDIR_URL="${REDIR_URL}${REDIR_URL##*\?}"
    # (simpler: just let status.sh tell the portal about the paused state on load)

    printf "Status: 302 Found\r\n"
    printf "Location: %s\r\n" "$REDIR_URL"
    printf "Cache-Control: no-cache, no-store\r\n"
    printf "Pragma: no-cache\r\n"
    printf "Expires: -1\r\n"
    printf "\r\n"
    # MikroTik-style HTML body: both the Location header AND meta-refresh
    # so that browsers that don't follow 302 automatically still redirect.
    printf '<html>\r\n'
    printf '<head>\r\n'
    printf '<title>Hotspot redirect</title>\r\n'
    printf '<meta http-equiv="refresh" content="0; url=%s">\r\n' "$REDIR_URL"
    printf '<meta http-equiv="pragma" content="no-cache">\r\n'
    printf '<meta http-equiv="expires" content="-1">\r\n'
    printf '</head>\r\n'
    printf '<body>\r\n'
    printf '<p>Redirecting to hotspot portal...</p>\r\n'
    printf '<p><a href="%s">Click here if not redirected automatically.</a></p>\r\n' "$REDIR_URL"
    printf '</body>\r\n'
    printf '</html>\r\n'
fi
