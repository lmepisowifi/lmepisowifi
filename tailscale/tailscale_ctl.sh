#!/bin/sh
# ============================================================
# tailscale_ctl.sh — Tailscale (userspace) lifecycle for lmepisowifi
# Installed by the "tailscale" www2 module (module_ctl.sh) at
#   /lmepisowifi/tailscale/{tailscaled-small,tailscale-small,tailscale_ctl.sh}
#
# This ONT has no /dev/net/tun, so tailscaled runs in userspace-networking
# mode (SOCKS5 + HTTP proxy on 127.0.0.1:1055). It's still perfectly usable as
# a subnet router / SSH target.
#
# Persistence lives on the /config partition (survives reflash + module
# uninstall), NOT under /lmepisowifi:
#   /config/tailscale/config.env   -> TS_ENABLED / TS_ROUTES / TS_SSH
#   /config/tailscale-state        -> tailscaled --statedir (node keys)
#
# When TS_ENABLED=1 a boot line is written into www2/sh/startup.sh between
# BEGIN_TAILSCALE / END_TAILSCALE, so it auto-starts on boot (and the OTA's
# merge_startup_markers carries that across updates). Toggling the switch off
# removes that line.
#
#   tailscale_ctl.sh start | stop | boot | up | status
#   tailscale_ctl.sh set-config <routes> <ssh01>
#   tailscale_ctl.sh set-enabled <01>
#   tailscale_ctl.sh postinstall | preuninstall
# ============================================================

ROOT="/lmepisowifi"
TS_DIR="$ROOT/tailscale"
DAEMON="$TS_DIR/tailscaled-small"
CLI="$TS_DIR/tailscale-small"
CFG_DIR="/config/tailscale"
CFG="$CFG_DIR/config.env"
STATE_DIR="/config/tailscale-state"
SOCK="/tmp/tailscaled.sock"
PIDF="/tmp/tailscaled.pid"
LOGIN_URL_FILE="/tmp/tailscale_login_url"
STARTUP="$ROOT/www2/sh/startup.sh"
BB="busybox"

TS_ENABLED=0
TS_ROUTES=""
TS_SSH=0
[ -f "$CFG" ] && . "$CFG"

json_esc() { printf '%s' "$1" | $BB sed 's/\\/\\\\/g; s/"/\\"/g'; }

save_cfg() {
    mkdir -p "$CFG_DIR" 2>/dev/null
    {
        echo "TS_ENABLED=\"$TS_ENABLED\""
        echo "TS_ROUTES=\"$TS_ROUTES\""
        echo "TS_SSH=\"$TS_SSH\""
    } > "$CFG"
    sync
}

daemon_running() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; }

start_daemon() {
    [ -x "$DAEMON" ] || return 1
    daemon_running && return 0
    mkdir -p "$STATE_DIR" 2>/dev/null
    # Detach so it keeps running after the CGI/boot script that launched it exits.
    ( nohup "$DAEMON" \
        --statedir="$STATE_DIR" \
        --socket="$SOCK" \
        --tun=userspace-networking \
        --socks5-server=127.0.0.1:1055 \
        --outbound-http-proxy-listen=127.0.0.1:1055 \
        >/tmp/tailscaled.log 2>&1 & echo $! > "$PIDF" ) &
    # wait for the control socket to appear
    _i=0; while [ ! -e "$SOCK" ] && [ "$_i" -lt 15 ]; do sleep 1; _i=$((_i + 1)); done
    return 0
}

stop_daemon() {
    "$CLI" --socket="$SOCK" down >/dev/null 2>&1
    [ -f "$PIDF" ] && kill "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null
    rm -f "$PIDF"
    for _p in $($BB ps | $BB grep 'tailscaled-small' | $BB grep -v grep | $BB awk '{print $1}'); do
        kill "$_p" 2>/dev/null
    done
}

# Bring the node up with the current config; scrape the login URL if the node
# still needs to be authenticated (first boot / after logout).
ts_up() {
    daemon_running || start_daemon
    _args="--socket=$SOCK up --reset --accept-dns=false"
    [ -n "$TS_ROUTES" ] && _args="$_args --advertise-routes=$TS_ROUTES"
    [ "$TS_SSH" = "1" ] && _args="$_args --ssh"
    rm -f "$LOGIN_URL_FILE" /tmp/tailscale_up.log
    # `up` blocks until authenticated on first use, so run it detached and
    # harvest the login URL it prints.
    ( "$CLI" $_args >/tmp/tailscale_up.log 2>&1 ) &
    _i=0
    while [ "$_i" -lt 15 ]; do
        _u=$($BB grep -o 'https://login\.tailscale\.com/[A-Za-z0-9/._-]*' /tmp/tailscale_up.log 2>/dev/null | head -1)
        [ -n "$_u" ] && { printf '%s\n' "$_u" > "$LOGIN_URL_FILE"; break; }
        # already authenticated -> `up` exits quickly with no URL
        grep -qi 'Success\|already' /tmp/tailscale_up.log 2>/dev/null && break
        sleep 1; _i=$((_i + 1))
    done
}

# ── boot marker in www2/sh/startup.sh (BEGIN_TAILSCALE / END_TAILSCALE) ──────
_has_anchors() { $BB grep -q 'BEGIN_TAILSCALE' "$STARTUP" 2>/dev/null; }
_set_marker() { # $1 = content line ("" clears)
    [ -f "$STARTUP" ] || return 0
    $BB awk -v line="$1" '
        function norm(s,   t){ t=s; gsub(/[-# \t]/,"",t); return t }
        { m=norm($0)
          if(m=="BEGIN_TAILSCALE"){ print; if(line!="") print line; skip=1; next }
          if(m=="END_TAILSCALE"){ skip=0; print; next }
          if(skip) next
          print }
    ' "$STARTUP" > "$STARTUP.tmp" 2>/dev/null && $BB mv "$STARTUP.tmp" "$STARTUP"
    sync
}
add_boot_marker() {
    [ -f "$STARTUP" ] || return 0
    if _has_anchors; then
        _set_marker '( /lmepisowifi/tailscale/tailscale_ctl.sh boot ) &'
    else
        printf '\n# --- BEGIN_TAILSCALE ---\n( /lmepisowifi/tailscale/tailscale_ctl.sh boot ) &\n# --- END_TAILSCALE ---\n' >> "$STARTUP"
        sync
    fi
}
remove_boot_marker() { [ -f "$STARTUP" ] && _has_anchors && _set_marker ''; }

emit_status() {
    _run="false"; daemon_running && _run="true"
    _en="false";  [ "$TS_ENABLED" = "1" ] && _en="true"
    _ssh="false"; [ "$TS_SSH" = "1" ] && _ssh="true"
    _login=$(cat "$LOGIN_URL_FILE" 2>/dev/null)
    _ip=""; _backend=""
    if daemon_running; then
        _ip=$("$CLI" --socket="$SOCK" ip -4 2>/dev/null | head -1)
        _backend=$("$CLI" --socket="$SOCK" status --json 2>/dev/null | $BB grep -o '"BackendState"[^,]*' | head -1 | $BB sed 's/.*: *"\([^"]*\)".*/\1/')
    fi
    # If the backend is already running we no longer need the stale login URL.
    [ "$_backend" = "Running" ] && _login=""
    printf '{"ok":true,"running":%s,"enabled":%s,"ssh":%s,"routes":"%s","ip":"%s","backend":"%s","login_url":"%s"}\n' \
        "$_run" "$_en" "$_ssh" "$(json_esc "$TS_ROUTES")" "$(json_esc "$_ip")" "$(json_esc "$_backend")" "$(json_esc "$_login")"
}

case "$1" in
    start)
        TS_ENABLED=1; save_cfg; add_boot_marker; start_daemon; ts_up; echo '{"ok":true}' ;;
    stop)
        TS_ENABLED=0; save_cfg; remove_boot_marker; stop_daemon; echo '{"ok":true}' ;;
    boot)
        [ "$TS_ENABLED" = "1" ] || exit 0
        [ -x "$DAEMON" ] || exit 0
        start_daemon; ts_up ;;
    up)
        ts_up; echo '{"ok":true}' ;;
    set-config)
        TS_ROUTES="$2"; [ "$3" = "1" ] && TS_SSH=1 || TS_SSH=0
        save_cfg
        daemon_running && ts_up
        echo '{"ok":true}' ;;
    set-enabled)
        if [ "$2" = "1" ]; then
            TS_ENABLED=1; save_cfg; add_boot_marker; start_daemon; ts_up
        else
            TS_ENABLED=0; save_cfg; remove_boot_marker; stop_daemon
        fi
        echo '{"ok":true}' ;;
    status)
        emit_status ;;
    postinstall)
        mkdir -p "$CFG_DIR" "$STATE_DIR" 2>/dev/null
        [ -f "$CFG" ] || save_cfg
        chmod +x "$DAEMON" "$CLI" 2>/dev/null
        # If it was previously enabled (config persisted on /config), restore the
        # boot hook and start now.
        [ "$TS_ENABLED" = "1" ] && { add_boot_marker; start_daemon; ts_up; }
        echo '{"ok":true}' ;;
    preuninstall)
        remove_boot_marker
        stop_daemon
        # NOTE: /config/tailscale and /config/tailscale-state are intentionally
        # left in place so a reinstall keeps the node identity + settings.
        echo '{"ok":true}' ;;
    *)
        echo "usage: $0 {start|stop|boot|up|status|set-config <routes> <ssh01>|set-enabled <01>|postinstall|preuninstall}" >&2
        exit 2 ;;
esac
