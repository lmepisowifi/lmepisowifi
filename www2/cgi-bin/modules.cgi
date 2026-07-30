#!/bin/sh

SESSION_TIMEOUT=600

# ---------------------------------------------------------------
# Auth gate — same pattern as hotspot.cgi / lme.cgi
# ---------------------------------------------------------------
BROWSER_SESSION=$(echo "$HTTP_COOKIE" | busybox sed -n 's/.*session=\([^;]*\).*/\1/p' | busybox tr -d '\r\n')
BROWSER_SESSION=$(echo "$BROWSER_SESSION" | busybox tr -cd 'a-fA-F0-9')
SESSION_FILE="/tmp/sessions/$BROWSER_SESSION"

if [ -z "$BROWSER_SESSION" ] || [ ! -f "$SESSION_FILE" ]; then
    printf "Status: 302 Found\r\n"
    printf "Location: /login.html\r\n\r\n"
    exit 0
fi

LAST=$(cat "$SESSION_FILE" 2>/dev/null | busybox tr -d '\r\n')
NOW=$(date +%s)
[ -z "$LAST" ] && LAST=$NOW
if [ $((NOW - LAST)) -gt $SESSION_TIMEOUT ]; then
    rm -f "$SESSION_FILE"
    printf "Status: 302 Found\r\n"
    printf "Location: /login.html\r\n\r\n"
    exit 0
fi
_SESS_TMP=$(mktemp /tmp/sessions/.tmp.XXXXXX)
echo "$NOW" > "$_SESS_TMP"
busybox mv "$_SESS_TMP" "$SESSION_FILE"

case "${CONTENT_LENGTH:-0}" in *[!0-9]*|"") CONTENT_LENGTH=0 ;; esac
[ "$CONTENT_LENGTH" -gt 4096 ] && CONTENT_LENGTH=4096

BB="busybox"
MC="/lmepisowifi/module_ctl.sh"
[ -x "$MC" ] || $BB chmod +x "$MC" 2>/dev/null

ok_json()  { printf "Status: 200 OK\r\nContent-Type: application/json\r\n\r\n%s" "$1"; exit 0; }
err_json() { printf "Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{\"ok\":false,\"error\":\"%s\"}" "$1"; exit 0; }

QS="$QUERY_STRING"
ACT=$(echo "$QS" | $BB grep -o 'action=[^&]*' | $BB sed 's/action=//')

# Read + whitelist the module id from a POST body (only known ids allowed).
post_id() {
    read -n "$CONTENT_LENGTH" BODY
    _v=$(printf '%s' "$BODY" | $BB tr '&' '\n' | $BB grep '^id=' | $BB sed 's/^id=//' | $BB tr -cd 'a-z0-9_-')
    printf '%s' "$_v"
}

[ -x "$MC" ] || err_json "module_ctl_missing"

case "$ACT" in
    list)
        OUT=$("$MC" list 2>/dev/null)
        [ -n "$OUT" ] && ok_json "$OUT" || err_json "list_failed"
        ;;
    status)
        ID=$(echo "$QS" | $BB grep -o 'id=[^&]*' | $BB sed 's/id=//' | $BB tr -cd 'a-z0-9_-')
        [ -z "$ID" ] && ID=hotspot
        OUT=$("$MC" status "$ID" 2>/dev/null)
        [ -n "$OUT" ] && ok_json "$OUT" || err_json "status_failed"
        ;;
    install)
        ID=$(post_id)
        # Any id in module_ctl.sh's own $MODULES list is valid — hardcoding
        # "hotspot" here was a leftover from before tailscale existed as a
        # second module, and silently rejected every other install. Only
        # reject empty (a malformed/missing POST body); module_ctl.sh does
        # the real $MODULES-based validation and returns this same
        # unknown_module error for any id it doesn't recognize.
        [ -n "$ID" ] || err_json "unknown_module"
        # Downloads a (possibly multi-MB) tarball from GitHub — run it in the
        # background and let the page poll action=install_status so the request
        # never blocks long enough to hit a proxy/browser timeout.
        printf 'running' > /tmp/module_status
        rm -f /tmp/module_result 2>/dev/null
        ( "$MC" install "$ID" > /tmp/module_result 2>/dev/null; printf 'done' > /tmp/module_status ) &
        ok_json '{"ok":true,"started":true}'
        ;;
    install_status)
        ST=$(cat /tmp/module_status 2>/dev/null); [ -z "$ST" ] && ST="idle"
        RES=$(cat /tmp/module_result 2>/dev/null)
        case "$RES" in {*}) : ;; *) RES="null" ;; esac
        ok_json "{\"ok\":true,\"status\":\"$ST\",\"result\":$RES}"
        ;;
    uninstall)
        ID=$(post_id)
        # Same fix as install above — defer id validation to module_ctl.sh.
        [ -n "$ID" ] || err_json "unknown_module"
        OUT=$("$MC" uninstall "$ID" 2>/dev/null)
        [ -n "$OUT" ] && ok_json "$OUT" || err_json "uninstall_failed"
        ;;
    *)
        err_json "unknown_action"
        ;;
esac
