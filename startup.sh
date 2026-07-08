#!/bin/sh

(
    # --- STEP 1: Wait for /lmepisowifi/ to be writable ---
    while [ ! -w "/lmepisowifi" ]; do
        sleep 2
    done
    # --- STEP 1.1: Save MAC Address and SN ---
    [ ! -d /lmepisowifi/httpd/configdefault ] && mkdir -p /lmepisowifi//httpd/configdefault
    [ ! -f /lmepisowifi/httpd/configdefault/mac.txt ] && flash get ELAN_MAC_ADDR | awk -F'=' '{print $2}' > /lmepisowifi/httpd/configdefault/mac.txt
    [ ! -f /lmepisowifi/httpd/configdefault/sn.txt ] && flash get GPON_SN | awk -F'=' '{print $2}' > /lmepisowifi//httpd/configdefault/sn.txt
    [ ! -f /lmepisowifi/httpd/configdefault/version.txt ] && cp /etc/version /lmepisowifi/httpd/configdefault/version.txt
    

    # --- STEP 1.2: Run custom admin scripts ---
    if [ -f /lmepisowifi/httpd/run_admin.sh ]; then
        chmod +x /lmepisowifi/httpd/run_admin.sh
        /lmepisowifi/httpd/run_admin.sh
    fi
    if [ -f /lmepisowifi/httpd/run_adminhidden.sh ]; then
        chmod +x /lmepisowifi/httpd/run_adminhidden.sh
        /lmepisowifi/httpd/run_adminhidden.sh
    fi

    # --- STEP 1.3: Restore version.txt bind mount if modified ---
    if [ -f /lmepisowifi/httpd/version.txt ]; then
        grep -q '/etc/version' /proc/mounts || mount --bind /lmepisowifi/httpd/version.txt /etc/version
    fi

    # --- STEP 1.4: Block HTTP from WAN ---
    iptables -I INPUT ! -i br0 -p tcp --dport 80 -j DROP 2>/dev/null
    

    # --- STEP 1.5: Start boa from custom httpd ---
    killall -9 boa
    boa -c /lmepisowifi/httpd &
    sleep 1
    busybox httpd -h /lmepisowifi/www2 -p 8080
    chmod +x /lmepisowifi/lmehspt.sh
    /lmepisowifi/lmehspt.sh &
    /lmepisowifi/www2/sh/startup.sh &

    # --- STEP 1.6: Start crond ---
    # /etc/crontabs is on the read-only squashfs rootfs, so crond is pointed
    # at /config/crontabs instead (writable, persists across reboots).
    # The OTA update check (a long, fixed 6h interval, stateless check) is
    # scheduled here instead of a hand-rolled sleep-loop. Written once;
    # the BEGIN/END marker guards against duplicating the line on every boot.
    mkdir -p /config/crontabs
    touch /config/crontabs/root
    if ! busybox grep -q '^# --- BEGIN_OTA_CRON ---$' /config/crontabs/root 2>/dev/null; then
        {
            echo "# --- BEGIN_OTA_CRON ---"
            echo "0 */6 * * * [ -x /lmepisowifi/ota.sh ] && /lmepisowifi/ota.sh cron >/dev/null 2>&1"
            echo "# --- END_OTA_CRON ---"
        } >> /config/crontabs/root
    fi
    busybox pidof crond >/dev/null || busybox crond -c /config/crontabs -l 8 &
    # SSH (dropbear) lifecycle is managed entirely by ipacl.sh, called via
    # www2/sh/startup.sh → apply_all at boot. It reads ACC_TBL.0.ssh (level)
    # and ACC_TBL.0.ssh_port from the mib and calls dropbear_start /
    # dropbear_stop / dropbear_restart accordingly. An unconditional launch
    # here would ignore the configured access level and port, and race against
    # apply_all — if level=0 (blocked), dropbear would start and then
    # immediately be killed a moment later by apply_all's dropbear_stop.

) &
