#!/bin/sh

# 1. Read POST data
if [ "$REQUEST_METHOD" = "POST" ]; then
    # Clamp body size: reject non-numeric and cap to 64KB to stop a
    # malicious Content-Length from forcing a huge/slow byte-by-byte read (DoS).
    __CL="${CONTENT_LENGTH:-0}"; case "$__CL" in *[!0-9]*|"") __CL=0 ;; esac
    [ "$__CL" -gt 65536 ] && __CL=65536
    POST_DATA=$(busybox dd bs=1 count="$__CL" 2>/dev/null)
fi

# 2. Extract and decode submitted credentials
FORM_USER=$(echo "$POST_DATA" | busybox sed -n 's/.*username=\([^&]*\).*/\1/p')
FORM_PASS=$(echo "$POST_DATA" | busybox sed -n 's/.*password=\([^&]*\).*/\1/p')
FORM_USER=$(busybox httpd -d "$FORM_USER" | busybox tr -d '\r\n')
FORM_PASS=$(busybox httpd -d "$FORM_PASS" | busybox tr -d '\r\n')

# 3. Get real credentials from MIB
REAL_USER=$(mib get SUSER_NAME | grep "SUSER_NAME=" | busybox cut -d'=' -f2 | busybox tr -d '\r\n')
REAL_PASS=$(mib get SUSER_PASSWORD | grep "SUSER_PASSWORD=" | busybox cut -d'=' -f2 | busybox tr -d '\r\n')

# 4. Validate credentials
if [ -n "$FORM_USER" ] && [ "$FORM_USER" = "$REAL_USER" ] && [ "$FORM_PASS" = "$REAL_PASS" ]; then

    # Generate unique session ID
    SESSION_ID=$(printf "%s%s%s" "$(date)" "$RANDOM" "$FORM_USER" | busybox sha256sum | busybox cut -d' ' -f1)

    # Ensure session directory exists and write timestamp for this session
    mkdir -p /tmp/sessions
    date +%s > "/tmp/sessions/$SESSION_ID"

    # Sweep expired sessions (older than 600s) to keep /tmp clean
    NOW=$(date +%s)
    for f in /tmp/sessions/*; do
        [ -f "$f" ] || continue
        LAST=$(cat "$f" 2>/dev/null | busybox tr -d '\r\n')
        [ -z "$LAST" ] && rm -f "$f" && continue
        [ $((NOW - LAST)) -gt 600 ] && rm -f "$f"
    done

    printf "Status: 302 Found\r\n"
    printf "Set-Cookie: session=%s; Path=/; HttpOnly; SameSite=Strict\r\n" "$SESSION_ID"
    printf "Location: /index.html\r\n\r\n"
else
    printf "Status: 302 Found\r\n"
    printf "Location: /login.html?error=1\r\n\r\n"
fi