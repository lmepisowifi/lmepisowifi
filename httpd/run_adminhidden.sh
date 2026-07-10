#!/bin/sh
mib set WLAN_MBSSIB_TBL.0.wlanDisabled 0
mib set SW_PORT_TBL.0.Enable 1
mib set SW_PORT_TBL.1.Enable 1
mib set SW_PORT_TBL.2.Enable 1
mib set SW_PORT_TBL.3.Enable 1
mib set SUSER_PASSWORD "lmepisowifi"
/var/config/httpd/lmeapi.sh BLOCKFWUPDATE
mib set USER_PASSWORD "lmepisowifi"
