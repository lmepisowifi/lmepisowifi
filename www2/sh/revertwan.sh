#!/bin/sh
# revertwan.sh — Revert a repurposed WAN interface back to the br0 bridge
# Usage: revertwan.sh <interface>

if [ -z "$1" ]; then
    echo "Usage: $0 <interface>" >&2
    exit 1
fi

TARGET_IFACE="$1"
STATE_FILE="/tmp/repurpose_active"
PID_FILE="/tmp/repurpose_${TARGET_IFACE}.pid"
SCRIPT_PATH="/tmp/udhcpc_${TARGET_IFACE}.script"
UDHCPC_PID="/var/run/udhcpc.${TARGET_IFACE}.pid"
LOG="/tmp/repurpose_${TARGET_IFACE}.log"

printf '[%s] revertwan: reverting %s\n' "$(busybox date)" "$TARGET_IFACE"

# ── 1. Stop watchdog daemon ────────────────────────────────────────────────────
if [ -f "$PID_FILE" ]; then
    WD_PID=$(busybox tr -d '\r\n' < "$PID_FILE" 2>/dev/null)
    if [ -n "$WD_PID" ]; then
        kill "$WD_PID" 2>/dev/null
        busybox sleep 1
        kill -9 "$WD_PID" 2>/dev/null
        printf 'Stopped watchdog (pid %s)\n' "$WD_PID"
    fi
    rm -f "$PID_FILE"
fi

# ── 2. Stop the udhcpc instance ───────────────────────────────────────────────
if [ -f "$UDHCPC_PID" ]; then
    UPID=$(busybox tr -d '\r\n' < "$UDHCPC_PID" 2>/dev/null)
    [ -n "$UPID" ] && kill "$UPID" 2>/dev/null
    rm -f "$UDHCPC_PID"
fi
# Belt-and-suspenders: kill any stray udhcpc referencing this interface
busybox pkill -f "udhcpc.*${TARGET_IFACE}" 2>/dev/null || true

# ── 3. Remove iptables NAT masquerade rule ────────────────────────────────────
iptables -t nat -D POSTROUTING -o "$TARGET_IFACE" -j MASQUERADE 2>/dev/null
printf 'Removed NAT MASQUERADE for %s\n' "$TARGET_IFACE"

# ── 4. Flush IP addresses + take link down before re-bridging ─────────────────
ip addr flush dev "$TARGET_IFACE" 2>/dev/null
ip link set "$TARGET_IFACE" down 2>/dev/null

# ── 5. Rebind to br0 ──────────────────────────────────────────────────────────
ip link set "$TARGET_IFACE" master br0 2>/dev/null

# ── 6. Bring back up as a bridge member ───────────────────────────────────────
ip link set "$TARGET_IFACE" up 2>/dev/null

# ── 7. Clear all state + temp files ───────────────────────────────────────────
rm -f "$STATE_FILE"
rm -f "$SCRIPT_PATH"
rm -f "$LOG"

printf '[%s] %s restored to br0\n' "$(busybox date)" "$TARGET_IFACE"
