#!/bin/sh

export GOMIPS=softfloat
export GOGC=20
export GOMAXPROCS=1

# ============================================================
# tailscale_ctl.sh — Tailscale (userspace) lifecycle for lmepisowifi
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
UPPIDF="/tmp/tailscale_up.pid"
LOGIN_URL_FILE="/tmp/tailscale_login_url"
DAEMON_LOG="/tmp/tailscaled.log"
UP_LOG="/tmp/tailscale_up.log"

STARTUP="$ROOT/www2/sh/startup.sh"
BB="busybox"

LOCKDIR="/tmp/tailscale_ctl.lock"

TS_ENABLED=0
TS_ROUTES=""
TS_SSH=0

[ -f "$CFG" ] && . "$CFG"

json_esc() {
    printf '%s' "$1" | $BB sed 's/\\/\\\\/g; s/"/\\"/g'
}

save_cfg() {
    mkdir -p "$CFG_DIR" 2>/dev/null
    {
        echo "TS_ENABLED=\"$TS_ENABLED\""
        echo "TS_ROUTES=\"$TS_ROUTES\""
        echo "TS_SSH=\"$TS_SSH\""
    } > "$CFG"
    sync
}

lock() {
    _i=0
    while ! mkdir "$LOCKDIR" 2>/dev/null; do
        _i=$((_i + 1))
        if [ "$_i" -gt 30 ]; then
            echo '{"ok":false,"error":"timeout acquiring lock"}' >&2
            exit 1
        fi
        sleep 1
    done
    echo $$ > "$LOCKDIR/pid" 2>/dev/null
}

unlock() {
    rm -rf "$LOCKDIR" 2>/dev/null
}

trap unlock EXIT INT TERM

daemon_pid() {
    [ -f "$PIDF" ] || return 1
    cat "$PIDF" 2>/dev/null
}

up_pid() {
    [ -f "$UPPIDF" ] || return 1
    cat "$UPPIDF" 2>/dev/null
}

daemon_running() {
    _pid="$(daemon_pid)"
    [ -n "$_pid" ] || return 1
    [ -d "/proc/$_pid" ] || return 1
    $BB grep -q 'tailscaled-small' "/proc/$_pid/cmdline" 2>/dev/null || return 1
    [ -e "$SOCK" ] || return 1
    return 0
}

up_running() {
    $BB ps 2>/dev/null | $BB awk '
        /tailscale-small/ && / up( |$)/ { found=1 }
        END { exit !found }
    '
}

query_status_json() {
    $BB timeout 3 "$CLI" --socket="$SOCK" status --json 2>/dev/null
}

cleanup_stray_daemons() {
    _pid="$(daemon_pid)"
    [ -n "$_pid" ] && kill -9 "$_pid" 2>/dev/null

    _upid="$(up_pid)"
    [ -n "$_upid" ] && kill -9 "$_upid" 2>/dev/null

    for _p in $($BB ps 2>/dev/null | $BB awk '
        /tailscaled-small/ || (/tailscale-small/ && / up( |$)/) { print $1 }
    '); do
        kill -9 "$_p" 2>/dev/null
    done

    rm -f "$PIDF" "$UPPIDF" "$SOCK" "$LOGIN_URL_FILE" "$DAEMON_LOG" "$UP_LOG"
}

launch_daemon_once() {
    [ -x "$DAEMON" ] || return 1
    mkdir -p "$STATE_DIR" 2>/dev/null
    rm -f "$DAEMON_LOG" "$PIDF"

    "$DAEMON" \
        --statedir="$STATE_DIR" \
        --socket="$SOCK" \
        --tun=userspace-networking \
        --socks5-server=127.0.0.1:1055 \
        --outbound-http-proxy-listen=127.0.0.1:1055 \
        < /dev/null >"$DAEMON_LOG" 2>&1 &
    _pid=$!
    echo "$_pid" > "$PIDF"
    sleep 1

    kill -0 "$_pid" 2>/dev/null || return 1
    return 0
}

wait_for_daemon_ready() {
    _i=0
    while [ "$_i" -lt 15 ]; do
        if ! [ -e "$SOCK" ]; then
            sleep 1
            _i=$((_i + 1))
            continue
        fi

        _json="$(query_status_json)"
        if [ -n "$_json" ]; then
            return 0
        fi

        if $BB grep -qi 'segmentation fault\|panic\|fatal' "$DAEMON_LOG" 2>/dev/null; then
            return 1
        fi

        sleep 1
        _i=$((_i + 1))
    done
    return 1
}

start_daemon() {
    daemon_running && return 0

    cleanup_stray_daemons

    _try=0
    while [ "$_try" -lt 2 ]; do
        launch_daemon_once || {
            _try=$((_try + 1))
            cleanup_stray_daemons
            continue
        }

        if wait_for_daemon_ready; then
            return 0
        fi

        echo "tailscaled crashed or hung during startup. Attempting recovery..." >&2
        cleanup_stray_daemons
        _try=$((_try + 1))
    done

    return 1
}

stop_daemon() {
    if daemon_running; then
        $BB timeout 3 "$CLI" --socket="$SOCK" down >/dev/null 2>&1
    fi
    cleanup_stray_daemons
}

ts_up() {
    daemon_running || start_daemon || return 1

    if up_running; then
        return 0
    fi

    _args="--socket=$SOCK up --reset --accept-dns=false"
    [ -n "$TS_ROUTES" ] && _args="$_args --advertise-routes=$TS_ROUTES"
    [ "$TS_SSH" = "1" ] && _args="$_args --ssh"

    rm -f "$LOGIN_URL_FILE" "$UP_LOG" "$UPPIDF"

    $BB timeout 30 "$CLI" $_args >"$UP_LOG" 2>&1 &
    _upid=$!
    echo "$_upid" > "$UPPIDF"

    _i=0
    while [ "$_i" -lt 20 ]; do
        _u=$($BB grep -o 'https://login\.tailscale\.com/[A-Za-z0-9/._-]*' "$UP_LOG" 2>/dev/null | $BB head -1)
        if [ -n "$_u" ]; then
            printf '%s\n' "$_u" > "$LOGIN_URL_FILE"
            break
        fi

        if $BB grep -qi 'Success\|already logged in\|logged in' "$UP_LOG" 2>/dev/null; then
            break
        fi

        if ! kill -0 "$_upid" 2>/dev/null; then
            break
        fi

        sleep 1
        _i=$((_i + 1))
    done

    return 0
}

_has_anchors() {
    $BB grep -q 'BEGIN_TAILSCALE' "$STARTUP" 2>/dev/null
}

_set_marker() {
    [ -f "$STARTUP" ] || return 0

    $BB awk -v line="$1" '
        BEGIN { inblk = 0 }
        /BEGIN_TAILSCALE/ {
            print
            if (line != "") print line
            inblk = 1
            next
        }
        /END_TAILSCALE/ {
            inblk = 0
            print
            next
        }
        inblk { next }
        { print }
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

remove_boot_marker() {
    [ -f "$STARTUP" ] || return 0
    _has_anchors || return 0
    _set_marker ''
}

emit_status() {
    _run="false"
    _en="false"
    _ssh="false"
    _ip=""
    _backend=""
    _authurl=""
    _login=""

    [ "$TS_ENABLED" = "1" ] && _en="true"
    [ "$TS_SSH" = "1" ] && _ssh="true"

    if daemon_running; then
        _json="$(query_status_json)"
        if [ -n "$_json" ]; then
            _run="true"
            _ip=$($BB timeout 3 "$CLI" --socket="$SOCK" ip -4 2>/dev/null | $BB head -1)

            _backend=$(printf '%s' "$_json" | $BB sed -n 's/.*"BackendState":[[:space:]]*"\([^"]*\)".*/\1/p' | $BB head -1)
            _authurl=$(printf '%s' "$_json" | $BB sed -n 's/.*"AuthURL":[[:space:]]*"\([^"]*\)".*/\1/p' | $BB head -1 | $BB sed 's#\\/#/#g')
        fi
    fi

    _login="$_authurl"
    [ -z "$_login" ] && _login=$(cat "$LOGIN_URL_FILE" 2>/dev/null)

    if [ "$_backend" = "Running" ]; then
        _login=""
    fi

    printf '{"ok":true,"running":%s,"enabled":%s,"ssh":%s,"routes":"%s","ip":"%s","backend":"%s","login_url":"%s"}\n' \
        "$_run" "$_en" "$_ssh" "$(json_esc "$TS_ROUTES")" "$(json_esc "$_ip")" "$(json_esc "$_backend")" "$(json_esc "$_login")"
}

do_start() {
    TS_ENABLED=1
    save_cfg
    add_boot_marker
    start_daemon || return 1
    ts_up || return 1
    return 0
}

do_stop() {
    TS_ENABLED=0
    save_cfg
    remove_boot_marker
    stop_daemon
    return 0
}

do_boot() {
    [ "$TS_ENABLED" = "1" ] || return 0
    [ -x "$DAEMON" ] || return 0
    start_daemon || return 1
    ts_up || return 1
    return 0
}

do_set_config() {
    TS_ROUTES="$2"
    [ "$3" = "1" ] && TS_SSH=1 || TS_SSH=0
    save_cfg
    daemon_running && ts_up
    return 0
}

do_set_enabled() {
    if [ "$2" = "1" ]; then
        TS_ENABLED=1
        save_cfg
        add_boot_marker
        start_daemon || return 1
        ts_up || return 1
    else
        TS_ENABLED=0
        save_cfg
        remove_boot_marker
        stop_daemon
    fi
    return 0
}

do_postinstall() {
    mkdir -p "$CFG_DIR" "$STATE_DIR" 2>/dev/null
    [ -f "$CFG" ] || save_cfg
    chmod +x "$DAEMON" "$CLI" 2>/dev/null
    if [ "$TS_ENABLED" = "1" ]; then
        add_boot_marker
        start_daemon || return 1
        ts_up || return 1
    fi
    return 0
}

do_preuninstall() {
    remove_boot_marker
    stop_daemon
    return 0
}

case "$1" in
    start)
        lock
        do_start && echo '{"ok":true}' || echo '{"ok":false}'
        ;;
    stop)
        lock
        do_stop && echo '{"ok":true}' || echo '{"ok":false}'
        ;;
    boot)
        lock
        do_boot >/dev/null 2>&1
        ;;
    up)
        lock
        ts_up && echo '{"ok":true}' || echo '{"ok":false}'
        ;;
    set-config)
        lock
        do_set_config "$@" && echo '{"ok":true}' || echo '{"ok":false}'
        ;;
    set-enabled)
        lock
        do_set_enabled "$@" && echo '{"ok":true}' || echo '{"ok":false}'
        ;;
    status)
        emit_status
        ;;
    postinstall)
        lock
        do_postinstall && echo '{"ok":true}' || echo '{"ok":false}'
        ;;
    preuninstall)
        lock
        do_preuninstall && echo '{"ok":true}' || echo '{"ok":false}'
        ;;
    *)
        echo "usage: $0 {start|stop|boot|up|status|set-config <routes> <ssh01>|set-enabled <01>|postinstall|preuninstall}" >&2
        exit 2
        ;;
esac

