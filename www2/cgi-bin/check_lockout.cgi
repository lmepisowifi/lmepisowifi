#!/bin/sh
# check_lockout.cgi — reports the current global login-lockout state so
# login.html can reflect it even on a fresh page load (no ?locked=/?error=
# query string), e.g. a lockout tripped from a different tab/device.
#
# Output (text/plain): "locked <secs_remaining>" or "ok <attempts_remaining>"

. /lmepisowifi/www2/sh/auth_lockout.sh --lib

printf "Content-Type: text/plain\r\n\r\n"
lockout_status
