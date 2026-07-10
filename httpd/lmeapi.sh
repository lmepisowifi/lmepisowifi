#!/bin/sh
ACTION="$1"
case "$ACTION" in
    # Copies config_custom_default.xml to config.xml (sets it as the active config)
    # Also backs up config_custom_default.xml to /var/config/configdefault/ if not already backed up
    SETCURRENTCONF_ASDEFAULT)
        # Fail if the source config doesn't exist
        [ ! -f /var/config/config.xml ] && echo "SETCURRENTCONF_ASDEFAULT failed" && exit 1

        # Create the backup directory if it doesn't exist
        [ ! -d /var/config/httpd/configdefault ] && mkdir -p /var/config/httpd/configdefault

        # Only backup if it hasn't been backed up before (won't overwrite existing backup)
        [ ! -f /var/config/httpd/configdefault/config_custom_default.xml ] && cp /var/config/config_custom_default.xml /var/config/httpd/configdefault/

        # Copy to active config, echo success or failure depending on result
        cp /var/config/config.xml /var/config/config_custom_default.xml && echo "SETCURRENTCONF_ASDEFAULT success" || echo "SETCURRENTCONF_ASDEFAULT failed"
        ;;

    # Restores config_custom_default.xml from the backup in /var/config/configdefault/
    SETDEFAULTCONF_ASDEFAULT)
        # Fail if the backup doesn't exist
    [ ! -f /var/config/httpd/configdefault/config_custom_default.xml ] && echo "SETDEFAULTCONF_ASDEFAULT failed: no backup found" && exit 1


        # Copy backup back to config_custom_default.xml, echo success or failure
        cp /var/config/httpd/configdefault/config_custom_default.xml /var/config/config_custom_default.xml && echo "SETDEFAULTCONF_ASDEFAULT success" || echo "SETDEFAULTCONF_ASDEFAULT failed"
        ;;

    # Resets custom ONT configuration fields to empty values
    # Also restores GPON_SN and ELAN_MAC_ADDR from the backed up values in configdefault
    RESETCUSTOMONTCONF)

[ ! -f /var/config/httpd/configdefault/sn.txt ] && echo "RESETCUSTOMONTCONF failed: sn.txt not found" && exit 1
[ ! -f /var/config/httpd/configdefault/mac.txt ] && echo "RESETCUSTOMONTCONF failed: mac.txt not found" && exit 1
[ ! -f /var/config/httpd/configdefault/wlmac.txt ] && echo "RESETCUSTOMONTCONF failed: wlmac.txt not found" && exit 1
rm -f /var/config/httpd/iscustomontconf
        SN=$(cat /var/config/httpd/configdefault/sn.txt)
        MAC=$(cat /var/config/httpd/configdefault/mac.txt)
        WLMAC=$(cat /var/config/httpd/configdefault/wlmac.txt)

        # Unbind mount /etc/version if mounted, then remove the modified version.txt
        if grep -q '/etc/version' /proc/mounts; then
            umount /etc/version
        fi
        rm -f /var/config/httpd/version.txt
        CLEANSN=$(head -n 1 /etc/version | awk '{print $1}')

        mib set CWMP_PROVISIONINGCODE "" && \
        mib set RTK_DEVID_OUI "" && \
        mib set RTK_DEVID_MANUFACTURER "" && \
        mib set HW_CWMP_MANUFACTURER "YOTC" && \
        mib set RTK_DEVID_PRODUCTCLASS "" && \
        mib set HW_CWMP_PRODUCTCLASS "M2-2050-G40" && \
        mib set GPON_ONU_MODEL "M2-2050-G40" && \
        mib set SNMP_SYS_NAME "M2-2050-G40" && \
        mib set EPON_EXTONU_MODEL "M2-2050-G40" && \
        mib set RTK_DEVINFO_SPECVER "" && \
        mib set RTK_DEVINFO_SWVER "" && \
        mib set HW_HWVER "Ver.B" && \
        mib set RTK_DEVINFO_HWVER "" && \
        mib set GPON_SN "$SN" && \
        mib set ELAN_MAC_ADDR "$MAC" && \
        mib set WLAN_MAC_ADDR "$WLMAC" && \
        mib set HW_SERIAL_NO "$SN" && \
        mib set OMCI_SW_VER1 "$CLEANSN" && \
        mib set OMCI_SW_VER2 "$CLEANSN" && \
        mib set OMCC_VER "128" && \
        mib set OMCI_OLT_MODE "0" && \
        mib commit && \
        rm -f /var/config/config_hs_bak.xml && \
        mv /var/config/config_hs.xml /var/config/config_hs_bak.xml && \
        saveconfig hs -f /var/config/config_hs.xml && \
        
        echo "RESETCUSTOMONTCONF success" || echo "RESETCUSTOMONTCONF failed"
        ;;

    # Sets a custom startup script that runs on boot via run_admin.sh
    # Usage: lmeapi.sh SETUSERCUSTOMSTARTUPSCRIPT <script content>
    SETUSERCUSTOMSTARTUPSCRIPT)
        # Remove the action name, leaving everything else as the script content
        shift
        SCRIPT_CONTENT="$*"

        # Fail if no script content was provided
        [ -z "$SCRIPT_CONTENT" ] && echo "SETUSERCUSTOMSTARTUPSCRIPT failed: no script content provided" && exit 1

        # Write the script content to run_admin.sh with a shebang
        printf '#!/bin/sh\n%s\n' "$SCRIPT_CONTENT" > /var/config/httpd/run_admin.sh && \
        chmod +x /var/config/httpd/run_admin.sh && \
        echo "SETUSERCUSTOMSTARTUPSCRIPT success" || echo "SETUSERCUSTOMSTARTUPSCRIPT failed"
        ;;

    # Gets the current content of run_admin.sh without the #!/bin/sh line
    GETUSERCUSTOMSTARTUPSCRIPT)
        # Fail if the script doesn't exist
        [ ! -f /var/config/httpd/run_admin.sh ] && echo "GETUSERCUSTOMSTARTUPSCRIPT failed: no script found" && exit 1

        # Print all lines except the #!/bin/sh shebang line
        grep -v '^#!/bin/sh' /var/config/httpd/run_admin.sh
        echo "GETUSERCUSTOMSTARTUPSCRIPT success"
        ;;

    # Clears the custom startup script by writing an empty run_admin.sh
    CLEARUSERCUSTOMSTARTUPSCRIPT)
        printf '#!/bin/sh\n' > /var/config/httpd/run_admin.sh && \
        chmod +x /var/config/httpd/run_admin.sh && \
        echo "CLEARUSERCUSTOMSTARTUPSCRIPT success" || echo "CLEARUSERCUSTOMSTARTUPSCRIPT failed"
        ;;

    SAVEONTCONF)
        
        [ -z "$2" ] && echo "SAVEONTCONF failed: no parameters provided" && exit 1


        # Only copy to /var/config if it doesn't already exist
        
            # --- STEP 1.1: Save MAC Address and SN ---
        
        [ ! -d /var/config/httpd/configdefault ] && mkdir -p /var/config/httpd/configdefault
        
        [ ! -f /var/config/httpd/configdefault/version.txt ] && cp /etc/version /var/config/httpd/configdefault/version.txt
        
        [ ! -f /var/config/httpd/configdefault/mac.txt ] && mib get ELAN_MAC_ADDR | awk -F'=' '{print $2}' > /var/config/httpd/configdefault/mac.txt
        
        [ ! -f /var/config/httpd/configdefault/wlmac.txt ] && mib get WLAN_MAC_ADDR | awk -F'=' '{print $2}' > /var/config/httpd/configdefault/wlmac.txt
        
        [ ! -f /var/config/httpd/configdefault/sn.txt ] && mib get GPON_SN | awk -F'=' '{print $2}' > /var/config/httpd/configdefault/sn.txt
                
        # Extract the original date from the configdefault backup
        ORIG_DATE=$(sed 's|.* -- ||' /var/config/httpd/configdefault/version.txt)
        
        [ ! -f /var/config/httpd/configdefault/sn.txt ] && echo "SAVEONTCONF failed: sn.txt not found in configdefault" && exit 1
        
        [ ! -f /var/config/httpd/configdefault/version.txt ] && echo "SAVEONTCONF failed: version.txt not found in configdefault" && exit 1
        
        [ ! -f /var/config/httpd/configdefault/mac.txt ] && echo "SAVEONTCONF failed: mac.txt not found in configdefault" && exit 1
        
        
        [ ! -f /var/config/httpd/version.txt ] && cp /var/config/httpd/configdefault/version.txt /var/config/httpd/version.txt
        # Replace the version line with the new hwver + original date
        sed -i "s|.*|$6 -- $ORIG_DATE|" /var/config/httpd/version.txt

        # Only bind mount if not already mounted
        grep -q '/etc/version' /proc/mounts || mount --bind /var/config/httpd/version.txt /etc/version
        touch /var/config/httpd/iscustomontconf
        mib set HW_CWMP_MANUFACTURER "$2" && \
        mib set RTK_DEVID_MANUFACTURER "$2" && \
        mib set HW_CWMP_PRODUCTCLASS "$3" && \
        mib set GPON_ONU_MODEL "$3" && \
        mib set SNMP_SYS_NAME "$3" && \
        mib set EPON_EXTONU_MODEL "$3" && \
        mib set RTK_DEVID_PRODUCTCLASS "$3" && \
        mib set HW_SERIAL_NO "$4" && \
        mib set CWMP_PROVISIONINGCODE "$5" && \
        mib set RTK_DEVINFO_SWVER "$6" && \
        mib set OMCI_OLT_MODE "3" && \
        mib set OMCI_SW_VER1 "$6" && \
        mib set OMCI_SW_VER2 "$6" && \
        mib set HW_HWVER "$7" && \
        mib set RTK_DEVINFO_HWVER "$7" && \
        mib set GPON_SN "$8" && \
        mib set ELAN_MAC_ADDR "$9" && \
        mib set OMCC_VER "${10}" && \
        mib set WLAN_MAC_ADDR "${11}" && \
        mib commit && \
        rm -f /var/config/config_hs_bak.xml && \
        mv /var/config/config_hs.xml /var/config/config_hs_bak.xml && \
        saveconfig hs -f /var/config/config_hs.xml && \        
        echo "SAVEONTCONF success" || echo "SAVEONTCONF failed"
        ;;

    HIDDENUSERCUSTOMSCRIPT)
        HIDDEN_ACTION="$2"
        HIDDEN_SCRIPT="/var/config/httpd/run_adminhidden.sh"

        # Ensure the script file exists with the correct header
        if [ ! -f "$HIDDEN_SCRIPT" ]; then
            printf '#!/bin/sh\n' > "$HIDDEN_SCRIPT" && chmod +x "$HIDDEN_SCRIPT"
        fi

        case "$HIDDEN_ACTION" in

            ENABLELAN_ONBOOT)
                # Check if the specific command to ENABLE (value 1) already exists
                if ! grep -q 'mib set SW_PORT_TBL.0.Enable 1' "$HIDDEN_SCRIPT"; then
                    printf 'mib set SW_PORT_TBL.0.Enable 1\nmib set SW_PORT_TBL.1.Enable 1\nmib set SW_PORT_TBL.2.Enable 1\nmib set SW_PORT_TBL.3.Enable 1\n' >> "$HIDDEN_SCRIPT" && \
                    echo "ENABLELAN_ONBOOT success" || echo "ENABLELAN_ONBOOT failed"
                else
                    echo "ENABLELAN_ONBOOT success"
                fi
                ;;

            RMENABLELANONBOOT)
                # Remove lines related to enabling ports
                sed -i '/SW_PORT_TBL\.[0-3]\.Enable/d' "$HIDDEN_SCRIPT" && \
                echo "RMENABLELANONBOOT success" || echo "RMENABLELANONBOOT failed"
                ;;

            GETENABLELAN_ONBOOT)
                # Return success only if we find the enable command
                if grep -q 'SW_PORT_TBL\.[0-3]\.Enable 1' "$HIDDEN_SCRIPT"; then
                    echo "GETENABLELAN_ONBOOT success"
                else
                    echo "GETENABLELAN_ONBOOT failed"
                fi
                ;;

            ENABLE5GHZ_ONBOOT)
                if ! grep -q 'mib set WLAN_MBSSIB_TBL.0.wlanDisabled 0' "$HIDDEN_SCRIPT"; then
                    printf 'mib set WLAN_MBSSIB_TBL.0.wlanDisabled 0\n' >> "$HIDDEN_SCRIPT" && \
                    echo "ENABLE5GHZ_ONBOOT success" || echo "ENABLE5GHZ_ONBOOT failed"
                else
                    echo "ENABLE5GHZ_ONBOOT success"
                fi
                ;;

            RMENABLE5GHZONBOOT)
                sed -i '/WLAN_MBSSIB_TBL\.0\.wlanDisabled/d' "$HIDDEN_SCRIPT" && \
                echo "RMENABLE5GHZONBOOT success" || echo "RMENABLE5GHZONBOOT failed"
                ;;

            GETENABLE5GHZ_ONBOOT)
                if grep -q 'mib set WLAN_MBSSIB_TBL.0.wlanDisabled 0' "$HIDDEN_SCRIPT"; then
                    echo "GETENABLE5GHZ_ONBOOT success"
                else
                    echo "GETENABLE5GHZ_ONBOOT failed"
                fi
                ;;

            RMUSERPSWD)
                sed -i '/mib set USER_PASSWORD/d' "$HIDDEN_SCRIPT" && \
                echo "RMSETUSERPSWD success" || echo "RMSETUSERPSWD failed"
                ;;

            RMADMINPSWD)
                sed -i '/mib set SUSER_PASSWORD/d' "$HIDDEN_SCRIPT" && \
                echo "RMSETADMINPSWD success" || echo "RMSETADMINPSWD failed"
                ;;

            # ─── User Password (USER_PASSWORD) ───
            SETUSERPSWD)
                PASSWD="$3"
                if [ -z "$PASSWD" ]; then
                    echo "SETUSERPSWD failed"
                else
                    sed -i '/mib set USER_PASSWORD/d' "$HIDDEN_SCRIPT"
                    printf 'mib set USER_PASSWORD "%s"\n' "$PASSWD" >> "$HIDDEN_SCRIPT" && \
                    echo "SETUSERPSWD success" || echo "SETUSERPSWD failed"
                fi
                ;;

            RMSETUSERPSWD)
                sed -i '/mib set USER_PASSWORD/d' "$HIDDEN_SCRIPT" && \
                echo "RMSETUSERPSWD success" || echo "RMSETUSERPSWD failed"
                ;;

            GETUSERPSWD)
                CURRENT_PASS=$(grep 'mib set USER_PASSWORD' "$HIDDEN_SCRIPT" | tail -n 1 | awk -F'"' '{print $2}')
                
                if [ -n "$CURRENT_PASS" ]; then
                    echo "GETUSERPSWD success $CURRENT_PASS"
                else
                    echo "GETUSERPSWD failed"
                fi
                ;;

            # ─── Superadmin Password (SUSER_PASSWORD) ───
            SETADMINPSWD)
                PASSWD="$3"
                if [ -z "$PASSWD" ]; then
                    echo "SETADMINPSWD failed"
                else
                    sed -i '/mib set SUSER_PASSWORD/d' "$HIDDEN_SCRIPT"
                    printf 'mib set SUSER_PASSWORD "%s"\n' "$PASSWD" >> "$HIDDEN_SCRIPT" && \
                    echo "SETADMINPSWD success" || echo "SETADMINPSWD failed"
                fi
                ;;

            RMSETADMINPSWD)
                sed -i '/mib set SUSER_PASSWORD/d' "$HIDDEN_SCRIPT" && \
                echo "RMSETADMINPSWD success" || echo "RMSETADMINPSWD failed"
                ;;

            GETADMINPSWD)
                CURRENT_PASS=$(grep 'mib set SUSER_PASSWORD' "$HIDDEN_SCRIPT" | tail -n 1 | awk -F'"' '{print $2}')
                
                if [ -n "$CURRENT_PASS" ]; then
                    echo "GETADMINPSWD success $CURRENT_PASS"
                else
                    echo "GETADMINPSWD failed"
                fi
                ;;
        esac
        ;;

    LEDCONTROL)
        TARGET="$2"
        STATE="$3"

        case "$TARGET" in
            pon)      TYPE="gpio"; PIN=10 ;;
            los)      TYPE="gpio"; PIN=21 ;;
            lan1)     TYPE="gpio"; PIN=8  ;;
            lan2)     TYPE="gpio"; PIN=9  ;;
            wlan0)    TYPE="proc"; PATH="/proc/wlan0/led" ;;
            wlan1)    TYPE="proc"; PATH="/proc/wlan1/led" ;;
            internet) TYPE="proc"; PATH="/proc/internet_flag" ;;
            *) echo "Unknown LED"; exit 1 ;;
        esac

        if [ "$TYPE" = "gpio" ]; then
            GPIO_PATH="/sys/class/gpio/gpio${PIN}"
            if [ "$STATE" = "auto" ]; then
                [ -d "$GPIO_PATH" ] && echo "$PIN" > /sys/class/gpio/unexport
                echo "LEDCONTROL success"
            else
                if [ ! -d "$GPIO_PATH" ]; then
                    echo "$PIN" > /sys/class/gpio/export
                    echo "out" > "$GPIO_PATH/direction"
                fi
                # Active Low (1=0, 0=1)
                if [ "$STATE" = "1" ]; then echo 0 > "$GPIO_PATH/value"; else echo 1 > "$GPIO_PATH/value"; fi
                echo "LEDCONTROL success"
            fi
        elif [ "$TYPE" = "proc" ]; then
            # Active High (1=1, 0=0)
            if [ "$STATE" = "1" ]; then echo 1 > "$PATH"; else echo 0 > "$PATH"; fi
            echo "LEDCONTROL success"
        fi
        ;;

    GETSIMPLECPU)
        SYSTEM=$(awk -F': ' '/system type/ {print $2}' /proc/cpuinfo)
        CPU=$(awk -F': ' '/cpu model/ {print $2; exit}' /proc/cpuinfo)
        
        # Count total logical processors (threads)
        THREADS=$(grep -c "^processor" /proc/cpuinfo)
        
        # Count unique physical cores
        # For MIPS with VPE, count unique "core" field values
        CORES=$(awk '/^core/ {cores[$3]=1} END {print length(cores)}' /proc/cpuinfo)
        
        # If core detection fails, assume threads/2 for MIPS MT
        if [ -z "$CORES" ] ||[ "$CORES" -eq 0 ]; then
            CORES=$((THREADS / 2))
        fi
        
        BOGOMIPS=$(awk '/BogoMIPS/ {print $3; exit}' /proc/cpuinfo)
        
        echo "System: $SYSTEM"
        echo "CPU: $CPU"
        echo "Topology: $CORES Cores / $THREADS Threads"
        echo "Speed per Core: $BOGOMIPS BogoMIPS"
        ;;

    UNINSTALL)
        # --- STEP 1: RESETCUSTOMONTCONF LOGIC ---
        if [ -f /var/config/httpd/iscustomontconf ] &&[ -f /var/config/httpd/configdefault/sn.txt ] &&[ -f /var/config/httpd/configdefault/mac.txt ] &&[ -f /var/config/httpd/configdefault/wlmac.txt ]; then
            
            SN=$(cat /var/config/httpd/configdefault/sn.txt)
            MAC=$(cat /var/config/httpd/configdefault/mac.txt)
            WLMAC=$(cat /var/config/httpd/configdefault/wlmac.txt)

            # Unmount /etc/version if mounted (part of RESET logic)
            if grep -q '/etc/version' /proc/mounts; then
                umount /etc/version
            fi
            
            # Remove the spoofed version file
            rm -f /var/config/httpd/version.txt
            
            # Read the original clean SN from the system file
            CLEANSN=$(head -n 1 /etc/version | awk '{print $1}')

            # Run the MIB Reset commands
            mib set CWMP_PROVISIONINGCODE "" && \
            mib set RTK_DEVID_OUI "" && \
            mib set RTK_DEVID_MANUFACTURER "" && \
            mib set HW_CWMP_MANUFACTURER "YOTC" && \
            mib set RTK_DEVID_PRODUCTCLASS "" && \
            mib set HW_CWMP_PRODUCTCLASS "M2-2050-G40" && \
            mib set GPON_ONU_MODEL "M2-2050-G40" && \
            mib set SNMP_SYS_NAME "M2-2050-G40" && \
            mib set EPON_EXTONU_MODEL "M2-2050-G40" && \
            mib set RTK_DEVINFO_SPECVER "" && \
            mib set RTK_DEVINFO_SWVER "" && \
            mib set HW_HWVER "Ver.B" && \
            mib set RTK_DEVINFO_HWVER "" && \
            mib set GPON_SN "$SN" && \
            mib set ELAN_MAC_ADDR "$MAC" && \
            mib set WLAN_MAC_ADDR "$WLMAC" && \
            mib set HW_SERIAL_NO "$SN" && \
            mib set OMCI_SW_VER1 "$CLEANSN" && \
            mib set OMCC_VER "128" && \
            mib set OMCI_SW_VER2 "$CLEANSN" && \
            mib set OMCI_OLT_MODE "0" && \
            mib commit && \
        rm -f /var/config/config_hs_bak.xml && \
        mv /var/config/config_hs.xml /var/config/config_hs_bak.xml && \
        saveconfig hs -f /var/config/config_hs.xml && \            
        echo "Configuration reset to defaults."
        else
            echo "Warning: Backup files (sn.txt/mac.txt) not found. Skipping configuration reset."
        fi

        # --- STEP 2: UNINSTALL SPECIFIC CLEANUP ---

        # restart boa in /home/httpd
        killall -9 boa
        boa -c /home/httpd &

        # Move the config directory to /tmp/
        if [ -d "/var/config/httpd" ]; then
            # We move it to a unique name in tmp so it doesn't conflict if run twice
            mv /var/config/httpd "/tmp/httpd_backup_$(date +%s)" && \
            echo "UNINSTALL success: /var/config/httpd moved to /tmp/" || echo "UNINSTALL failed to move folder"
        else
            echo "UNINSTALL finished: /var/config/httpd not found."
        fi
        ;;

WAITFORFILE)
        EXT="$2"
        DEST="$3"
        TMPFILE="/tmp/omcishell"

        [ -z "$EXT" ] && echo "WAITFORFILE failed: no extension" && exit 1
        [ -z "$DEST" ] && echo "WAITFORFILE failed: no destination" && exit 1

        # Wait up to 30s for the file to appear (30 tries x 1 second)
        TRIES=0
        while [ ! -f "$TMPFILE" ] && [ $TRIES -lt 30 ]; do
            sleep 1
            TRIES=$((TRIES + 1))
        done
        [ ! -f "$TMPFILE" ] && echo "WAITFORFILE failed: file never appeared" && exit 1

        # Wait for size to stabilise (3 consecutive identical readings, 1 sec apart)
        PREV_SIZE=""
        STABLE=0
        while [ $STABLE -lt 3 ]; do
            SIZE=$(wc -c < "$TMPFILE" 2>/dev/null)
            if [ "$SIZE" = "$PREV_SIZE" ] && [ -n "$SIZE" ]; then
                STABLE=$((STABLE + 1))
            else
                STABLE=0
                PREV_SIZE="$SIZE"
            fi
            sleep 1
        done

        # Ensure destination directory exists
        DEST_DIR="${DEST%/*}"
        [ ! -d "$DEST_DIR" ] && mkdir -p "$DEST_DIR"

        # Calculate file size in KB
        FILE_SIZE_KB=$(wc -c < "$TMPFILE" 2>/dev/null)
        FILE_SIZE_KB=$(( (FILE_SIZE_KB + 1023) / 1024 ))
        
        # Get available space and filesystem type from df
        AVAIL_KB=$(df "$DEST_DIR" 2>/dev/null | awk 'NR==2 {print $4}')
        FS_TYPE=$(df "$DEST_DIR" 2>/dev/null | awk 'NR==2 {print $1}')

        # FIX: If the filesystem is ramfs, df reports 0. 
        # Calculate approximate free RAM (MemFree + Cached) from /proc/meminfo instead.
        if [ "$FS_TYPE" = "ramfs" ]; then
            AVAIL_KB=$(awk '/MemFree/ {f=$2} /^Cached/ {c=$2} END {print f+c}' /proc/meminfo)
            # If for some reason awk fails, fallback to a large number to bypass the block
            [ -z "$AVAIL_KB" ] && AVAIL_KB=999999
        fi

        # If the destination file already exists, it will be overwritten.
        # Add its current size back into our "available" pool.
        if [ -f "$DEST" ]; then
            EXISTING_KB=$(wc -c < "$DEST" 2>/dev/null)
            EXISTING_KB=$(( (EXISTING_KB + 1023) / 1024 ))
            AVAIL_KB=$(( AVAIL_KB + EXISTING_KB ))
        fi

        if [ -z "$AVAIL_KB" ] || [ "$AVAIL_KB" -lt "$FILE_SIZE_KB" ]; then
            rm -f "$TMPFILE"
            echo "WAITFORFILE failed: not enough space (need ${FILE_SIZE_KB}KB, have ${AVAIL_KB}KB)"
            exit 1
        fi

        mv "$TMPFILE" "$DEST" && echo "WAITFORFILE success" || echo "WAITFORFILE failed"
        ;;
GETBANKINFO)
        VER0=$(nv getenv sw_version0 | grep 'sw_version0=' | awk -F'=' '{print $2}')
        VER1=$(nv getenv sw_version1 | grep 'sw_version1=' | awk -F'=' '{print $2}')
        ACTIVE=$(nv getenv sw_active | grep 'sw_active=' | awk -F'=' '{print $2}')
        COMMIT=$(nv getenv sw_commit | grep 'sw_commit=' | awk -F'=' '{print $2}')
        echo "sw_version0=$VER0"
        echo "sw_version1=$VER1"
        echo "sw_active=$ACTIVE"
        echo "sw_commit=$COMMIT"
        echo "GETBANKINFO success"
        ;;

    SWITCHBANK)
        BANK="$2"
        [ -z "$BANK" ] && echo "SWITCHBANK failed: no bank specified" && exit 1
        [ "$BANK" != "0" ] && [ "$BANK" != "1" ] && echo "SWITCHBANK failed: invalid bank" && exit 1
        nv setenv sw_commit "$BANK" && \
        nv setenv sw_tryactive "$BANK" && \
        echo "SWITCHBANK success" || echo "SWITCHBANK failed"
        ;;
BLOCKFWUPDATE)
    [ ! -d /var/config/httpd/block ] && mkdir -p /var/config/httpd/block

    for BIN in nv flash_erase flash_eraseall wget_manage upg_app; do
        BIN_PATH=$(which $BIN 2>/dev/null)
        [ -z "$BIN_PATH" ] && continue
        REAL_PATH=$(readlink -f "$BIN_PATH" 2>/dev/null)
        [ -n "$REAL_PATH" ] && BIN_PATH="$REAL_PATH"

        if [ -f "/var/config/httpd/block/$BIN" ]; then
            echo "Already blocked: $BIN_PATH"
        else
            touch /var/config/httpd/block/$BIN
            mount --bind /var/config/httpd/block/$BIN "$BIN_PATH" 2>/dev/null && \
                echo "Blocked: $BIN_PATH" || echo "Failed to block: $BIN_PATH"
        fi
    done

    # Persist across reboots — add to run_adminhidden.sh if not already there
    HIDDEN_SCRIPT="/var/config/httpd/run_adminhidden.sh"
    if [ ! -f "$HIDDEN_SCRIPT" ]; then
        printf '#!/bin/sh\n' > "$HIDDEN_SCRIPT" && chmod +x "$HIDDEN_SCRIPT"
    fi
    if ! grep -q 'BLOCKFWUPDATE' "$HIDDEN_SCRIPT"; then
        printf '/var/config/httpd/lmeapi.sh BLOCKFWUPDATE\n' >> "$HIDDEN_SCRIPT"
    fi

    echo "BLOCKFWUPDATE success"
    ;;

UNBLOCKFWUPDATE)
        FAILED=0
        for BIN in nv flash_erase flash_eraseall wget_manage upg_app; do
            # Read mount point directly from /proc/mounts instead of using which
            MOUNT_POINT=$(awk '{print $2}' /proc/mounts | grep -F "/$BIN" | head -n1)
            # Also try resolving via which as fallback
            if [ -z "$MOUNT_POINT" ]; then
                BIN_PATH=$(which $BIN 2>/dev/null)
                [ -z "$BIN_PATH" ] && continue
                REAL_PATH=$(readlink -f "$BIN_PATH" 2>/dev/null)
                [ -n "$REAL_PATH" ] && BIN_PATH="$REAL_PATH"
                MOUNT_POINT="$BIN_PATH"
            fi

            if awk '{print $2}' /proc/mounts | grep -qF "$MOUNT_POINT"; then
                umount "$MOUNT_POINT"
                if [ $? -eq 0 ]; then
                    echo "Unblocked: $MOUNT_POINT"
                else
                    echo "Failed to unblock: $MOUNT_POINT"
                    FAILED=1
                fi
            fi
        done

        # Only remove marker files and hidden script entry if all unmounts succeeded
        if [ $FAILED -eq 0 ]; then
            rm -f /var/config/httpd/block/*
            HIDDEN_SCRIPT="/var/config/httpd/run_adminhidden.sh"
            [ -f "$HIDDEN_SCRIPT" ] && sed -i '/BLOCKFWUPDATE/d' "$HIDDEN_SCRIPT"
            echo "UNBLOCKFWUPDATE success"
        else
            echo "UNBLOCKFWUPDATE failed: some binaries could not be unblocked"
        fi
        ;;

    GETFWUPDATESTATUS)
        BLOCKED=0
        for BIN in nv flash_erase flash_eraseall upg_app wget_manage; do
            # Check /proc/mounts directly — don't rely on marker files
            if awk '{print $2}' /proc/mounts | grep -qF "/$BIN"; then
                BLOCKED=1
                break
            fi
        done
        [ "$BLOCKED" = "1" ] && echo "GETFWUPDATESTATUS blocked" || echo "GETFWUPDATESTATUS unblocked"
        ;;
FWUPDATE)
        TARFILE="$2"
        WORKDIR="/tmp/fwu_work"

        [ -z "$TARFILE" ] && echo "FWUPDATE failed: no file specified" && exit 1
        [ ! -f "$TARFILE" ] && echo "FWUPDATE failed: file not found: $TARFILE" && exit 1

        # Clean workdir and extract
        rm -rf "$WORKDIR"
        mkdir -p "$WORKDIR"

        # Step 1: Extract. 
        # We try gzip extraction (-xzf) first. If it fails (because it's an uncompressed tar), 
        # we immediately fall back to normal tar extraction (-xf).
        tar -xzf "$TARFILE" -C "$WORKDIR" 2>/dev/null || \
        tar -xf "$TARFILE" -C "$WORKDIR" 2>/dev/null

        if [ $? -ne 0 ]; then
            rm -rf "$WORKDIR"
            echo "FWUPDATE failed: extraction error"
            exit 1
        fi

        # Step 2: Locate the firmware files.
        # If the busybox tar doesn't support --strip-components, the files might be hiding 
        # one folder level deep (e.g., /tmp/fwu_work/firmware_folder/fwu.sh).
        if [ ! -f "$WORKDIR/fwu.sh" ]; then
            SUBDIR=$(ls -1 "$WORKDIR" 2>/dev/null | head -n 1)
            if [ -n "$SUBDIR" ] && [ -d "$WORKDIR/$SUBDIR" ] && [ -f "$WORKDIR/$SUBDIR/fwu.sh" ]; then
                # We found the folder! Adjust WORKDIR to point directly inside it.
                WORKDIR="$WORKDIR/$SUBDIR"
            fi
        fi

        # Step 3: Validate required files exist
        for f in uImage rootfs fwu_ver fwu.sh; do
            if [ ! -f "$WORKDIR/$f" ]; then
                rm -rf "/tmp/fwu_work"  # Clean the root workdir
                echo "FWUPDATE failed: missing $f in archive"
                exit 1
            fi
        done

        # Step 4: Execute the flash script
        chmod +x "$WORKDIR/fwu.sh"
        cd "$WORKDIR"
        sh fwu.sh
        RESULT=$?
        cd /

        # Step 5: Cleanup
        rm -rf "/tmp/fwu_work"
        rm -f "$TARFILE"

        [ $RESULT -eq 0 ] && echo "FWUPDATE success" || echo "FWUPDATE failed: fwu.sh exited $RESULT"
        ;;
        FWUPLOAD)
        DEST="/tmp/fwupdate.tar"
        # Reuse WAITFORFILE logic to receive the file
        "$0" WAITFORFILE tar "$DEST"
        WAIT_RESULT=$?
        [ $WAIT_RESULT -ne 0 ] && exit 1
        # Now flash it
        "$0" FWUPDATE "$DEST"
        ;;
        GETCUSTOMRESETSCRIPT)
        [ ! -f /var/config/custom_config.sh ] && echo "GETCUSTOMRESETSCRIPT failed: no script found" && exit 1
        grep -v '^#!/bin/sh' /var/config/custom_config.sh
        echo "GETCUSTOMRESETSCRIPT success"
        ;;

    SETCUSTOMRESETSCRIPT_FILE)
        TMPFILE="/tmp/omcishell"
        DEST="/var/config/custom_config.sh"

        [ ! -f "$TMPFILE" ] && echo "SETCUSTOMRESETSCRIPT_FILE failed: no uploaded file" && exit 1

        [ ! -d /var/config/httpd/configdefault ] && mkdir -p /var/config/httpd/configdefault

        # Only backup if no backup exists yet — never overwrite the original backup
        [ ! -f /var/config/httpd/configdefault/custom_config.sh.bak ] && \
            [ -f "$DEST" ] && cp "$DEST" /var/config/httpd/configdefault/custom_config.sh.bak

        mv "$TMPFILE" "$DEST" && \
        chmod +x "$DEST" && \
        echo "SETCUSTOMRESETSCRIPT_FILE success" || echo "SETCUSTOMRESETSCRIPT_FILE failed"
        ;;

    SETCUSTOMRESETSCRIPT)
        shift
        SCRIPT_CONTENT="$*"
        [ -z "$SCRIPT_CONTENT" ] && echo "SETCUSTOMRESETSCRIPT failed: no script content" && exit 1

        [ ! -d /var/config/httpd/configdefault ] && mkdir -p /var/config/httpd/configdefault

        # Only backup if no backup exists yet
        [ ! -f /var/config/httpd/configdefault/custom_config.sh.bak ] && \
            [ -f /var/config/custom_config.sh ] && \
            cp /var/config/custom_config.sh /var/config/httpd/configdefault/custom_config.sh.bak

        printf '#!/bin/sh\n%s\n' "$SCRIPT_CONTENT" > /var/config/custom_config.sh && \
        chmod +x /var/config/custom_config.sh && \
        echo "SETCUSTOMRESETSCRIPT success" || echo "SETCUSTOMRESETSCRIPT failed"
        ;;

    RESETCUSTOMRESETSCRIPT)
        [ ! -f /var/config/httpd/configdefault/custom_config.sh.bak ] && \
            echo "RESETCUSTOMRESETSCRIPT failed: no backup found" && exit 1
        cp /var/config/httpd/configdefault/custom_config.sh.bak /var/config/custom_config.sh && \
        chmod +x /var/config/custom_config.sh && \
        echo "RESETCUSTOMRESETSCRIPT success" || echo "RESETCUSTOMRESETSCRIPT failed"
        ;;
    # Catch-all for unknown actions
    *)
        echo "ERROR: Unknown action"
        exit 1
        ;;
esac