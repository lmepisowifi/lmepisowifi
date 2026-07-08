#!/bin/sh
# ============================================================
# ntp_event.sh — busybox ntpd "-S PROG" hook.
#
# busybox calls this as:  ntp_event.sh <action>
#   action = step      -> clock was just stepped (we are in sync)
#   action = periodic  -> fired every ~11 min while synced (slewing)
#   action = unsync    -> all peers became unreachable (lost sync)
#
# We maintain /tmp/ntp_synced (containing the epoch of the last good sync)
# so other scripts — income.sh in particular — can tell whether the wall
# clock is GENUINELY NTP-synced before trusting the date (e.g. to reset
# the daily/monthly/yearly income counters).
# ============================================================

MARK="/tmp/ntp_synced"

case "$1" in
    step|periodic)
        date +%s > "$MARK" 2>/dev/null
        ;;
    unsync)
        rm -f "$MARK" 2>/dev/null
        ;;
esac

exit 0
