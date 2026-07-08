#!/bin/sh

# Delete only this client's session file
BROWSER_SESSION=$(echo "$HTTP_COOKIE" | busybox sed -n 's/.*session=\([^;]*\).*/\1/p' | busybox tr -d '\r\n')
# Sanitize: session IDs are sha256 hex. Strip anything else to block
# path traversal (e.g. Cookie: session=../../config/foo) into rm -f.
BROWSER_SESSION=$(printf '%s' "$BROWSER_SESSION" | busybox tr -cd 'a-fA-F0-9')
if [ -n "$BROWSER_SESSION" ]; then
    rm -f "/tmp/sessions/$BROWSER_SESSION"
fi

printf "Status: 302 Found\r\n"
printf "Set-Cookie: session=; expires=Thu, 01 Jan 1970 00:00:00 UTC; Path=/; HttpOnly\r\n"
printf "Location: /login.html\r\n\r\n"