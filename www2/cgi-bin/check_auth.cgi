#!/bin/sh

SESSION_TIMEOUT=600

BROWSER_SESSION=$(echo "$HTTP_COOKIE" | busybox sed -n 's/.*session=\([^;]*\).*/\1/p' | busybox tr -d '\r\n')

printf "Content-Type: text/plain\r\n\r\n"

if [ -z "$BROWSER_SESSION" ]; then
    printf "anonymous"
    exit 0
fi

# Sanitize: session IDs are sha256 hex. Strip anything else to block
# path traversal (e.g. Cookie: session=../../config/foo) into rm/mv/cat.
BROWSER_SESSION=$(printf '%s' "$BROWSER_SESSION" | busybox tr -cd 'a-fA-F0-9')
SESSION_FILE="/tmp/sessions/$BROWSER_SESSION"

if [ ! -f "$SESSION_FILE" ]; then
    printf "anonymous"
    exit 0
fi

LAST=$(cat "$SESSION_FILE" 2>/dev/null | busybox tr -d '\r\n')
NOW=$(date +%s)

# Guard: empty file means a concurrent write is in progress or file is corrupt
if [ -z "$LAST" ]; then
    printf "anonymous"
    exit 0
fi

if [ $((NOW - LAST)) -le $SESSION_TIMEOUT ]; then
    # Atomic write — mv is a single rename() syscall, no truncation window
    TMPF=$(mktemp /tmp/sessions/.tmp.XXXXXX)
    echo "$NOW" > "$TMPF"
    mv "$TMPF" "$SESSION_FILE"
    printf "authenticated"
else
    rm -f "$SESSION_FILE"
    printf "anonymous"
fi