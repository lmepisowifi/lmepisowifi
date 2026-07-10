var __GLOBAL__ = {
 pageRoot: ''
};
function generateNav() {
 var navs = {
  active: 0,
  items: [
   {
    name: '<% multilang("3" "LANG_STATUS"); %>',
    sub: 0
   },
   {
    name: '<% multilang("6" "LANG_LAN"); %>',
    sub: 2
   },
   {
    name: '<% multilang("8" "LANG_WLAN"); %>',
    sub: 3
   },
   {
    name: '<% multilang("11" "LANG_WAN"); %>',
    sub: 4
   },
   {
    name: '<% multilang("1309" "LANG_SERVICES"); %>',
    sub: 5
   },
            <% CheckMenuDisplay("voip_sub_6"); %>
   {
    name: '<% multilang("1310" "LANG_ADVANCE"); %>',
    sub: 7
   },
   {
    name: '<% multilang("46" "LANG_DIAGNOSTICS"); %>',
    sub: 8
   },
   {
    name: '<% multilang("48" "LANG_ADMIN"); %>',
    sub: 9
   },
   {
    name: '<% multilang("1311" "LANG_STATISTICS"); %>',
    sub: 10
   },
   // ADD THIS NEW ITEM:
   {
    name: 'Mods',
    sub: 11
   }
  ]
 };
 return navs;
}
function renderNav() {
 var nav = generateNav();
 var tpl = $('#nav-tmpl').html();
 var html = juicer(tpl, nav);
 $('#nav').html(html);
}
function generateSide() {
 var side = [];
 var sub0, sub1, sub2, sub3, sub4, sub5, sub6, sub7, sub8, sub9, sub10, sub11,sub12;
 var pageRoot = __GLOBAL__.pageRoot;
 sub0 = {
  key: 0,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("3" "LANG_STATUS"); %>',
    items: [
     {
      name: '<% multilang("4" "LANG_DEVICE"); %>',
      href: pageRoot + 'status.asp'
     }
     ,
     {
      name: '<% multilang("5" "LANG_IPV6"); %>',
      href: pageRoot + 'status_ipv6.asp'
     }
     ,
     {
      name: '<% multilang("1303" "LANG_PON"); %>',
      href: pageRoot + 'status_pon.asp'
     }
     ,
     {
      name: '<% multilang("1304" "LANG_LAN_PORT"); %>',
      href: pageRoot + 'lan_port_status.asp'
     }
                    <% CheckMenuDisplay("voip_status"); %>
    ]
   }
  ]
 };
 sub2={
  key:2,
  active:'0-0',
  items:[
   {
    collapsed: false,
    name: '<% multilang("6" "LANG_LAN"); %>',
    items: [
     {
      name: '<% multilang("123" "LANG_LAN_INTERFACE_SETTINGS"); %>',
      href: pageRoot + 'tcpiplan.asp'
     }
    ]
   }
  ]
 };
 sub3 = {
  key: 3,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("1305" "LANG_WLAN0_5GHZ"); %>',
    items: [
     {
      name: '<% multilang("1292" "LANG_BASIC_SETTINGS"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlbasic.asp&wlan_idx=0'
     },
     {
      name: '<% multilang("9" "LANG_ADVANCED_SETTINGS"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wladvanced.asp&wlan_idx=0'
     },
     {
      name: '<% multilang("1293" "LANG_SECURITY"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlwpa.asp&wlan_idx=0'
     }
     ,
     {
      name: '<% multilang("1295" "LANG_ACCESS_CONTROL"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlactrl.asp&wlan_idx=0'
     }
     ,
     {
      name: '<% multilang("1300" "LANG_SITE_SURVEY"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlsurvey.asp&wlan_idx=0'
     }
     ,
     {
      name: '<% multilang("1301" "LANG_WPS"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlwps.asp&wlan_idx=0'
     }
     ,
     {
      name: '<% multilang("3" "LANG_STATUS"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlstatus.asp&wlan_idx=0'
     }
    ]
   },
   {
    collapsed: true,
    name: '<% multilang("1314" "LANG_WLAN1_2_4GHZ"); %>',
    items: [
     {
      name: '<% multilang("1292" "LANG_BASIC_SETTINGS"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlbasic.asp&wlan_idx=1'
     },
     {
      name: '<% multilang("9" "LANG_ADVANCED_SETTINGS"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wladvanced.asp&wlan_idx=1'
     },
     {
      name: '<% multilang("1293" "LANG_SECURITY"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlwpa.asp&wlan_idx=1'
     }
     ,
     {
      name: '<% multilang("1295" "LANG_ACCESS_CONTROL"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlactrl.asp&wlan_idx=1'
     }
     ,
     {
      name: '<% multilang("1300" "LANG_SITE_SURVEY"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlsurvey.asp&wlan_idx=1'
     }
     ,
     {
      name: '<% multilang("1301" "LANG_WPS"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlwps.asp&wlan_idx=1'
     }
     ,
     {
      name: '<% multilang("3" "LANG_STATUS"); %>',
      href: pageRoot + 'boaform/formWlanRedirect?redirect-url=/wlstatus.asp&wlan_idx=1'
     }
    ]
   }
   ,
   {
    collapsed: true,
    name: '<% multilang("3329" "LANG_MAX_USER_NUM"); %>',
    items: [
     {
      name: '<% multilang("3330" "LANG_MAX_USER_NUM_CONFIG"); %>',
      href: pageRoot + 'wlan_max_user_num.asp'
     }
    ]
   }
   ,
   {
    collapsed: true,
    name: '<% multilang("1298" "LANG_WLAN_EASY_MESH"); %>',
    items: [
     {
      name: '<% multilang("281" "LANG_WLAN_EASY_MESH_INTERFACE_SETUP"); %>',
      href: pageRoot + 'multi_ap_setting_general.asp'
     }
     <% CheckMenuDisplay("map_topology"); %>
     <% CheckMenuDisplay("map_channel_scan"); %>
     <% CheckMenuDisplay("map_vlan"); %>
    ]
   }
  ]
 };
 sub4 = {
  key: 4,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("11" "LANG_WAN"); %>',
    items: [
     <% CheckMenuDisplay("wan_mode"); %>
     {
      name: '<% multilang("1317" "LANG_PON_WAN"); %>',
      href: pageRoot + 'boaform/formWanRedirect?redirect-url=/multi_wan_generic.asp&if=pon'
     }
    ]
   }
  ]
 };
 sub5 = {
  key: 5,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("407" "LANG_SERVICE"); %>',
    items: [
     {
      name: '<% multilang("1320" "LANG_DHCP"); %>',
      href: pageRoot + 'dhcpd.asp'
     }
     ,
     {
      name: '<% multilang("1279" "LANG_DHCPV6"); %>',
      href: pageRoot + 'dhcpdv6.asp'
     }
     ,
     {
      name: '<% multilang("1276" "LANG_DYNAMIC_DNS"); %>',
      href: pageRoot + 'ddns.asp'
     }
     ,
     {
      name: '<% multilang("29" "LANG_IGMP_PROXY"); %>',
      href: pageRoot + 'igmproxy.asp'
     }
     ,
     {
      name: '<% multilang("30" "LANG_UPNP"); %>',
      href: pageRoot + 'upnp.asp'
     }
     ,
     {
      name: '<% multilang("31" "LANG_RIP"); %>',
      href: pageRoot + 'rip.asp'
     }
     ,
     {
      name: '<% multilang("1327" "LANG_SAMBA"); %>',
      href: pageRoot + 'samba.asp'
     }
    ]
   },
   {
    collapsed: true,
    name: '<% multilang("1325" "LANG_FIREWALL"); %>',
    items: [
     {
      name: '<% multilang("1281" "LANG_IP_PORT_FILTERING"); %>',
      href: pageRoot + 'fw-ipportfilter.asp'
     }
     ,
     {
      name: '<% multilang("19" "LANG_MAC_FILTERING"); %>',
      href: pageRoot + 'fw-macfilter.asp'
     }
     ,
     {
      name: '<% multilang("20" "LANG_PORT_FORWARDING"); %>',
      href: pageRoot + 'fw-portfw.asp'
     }
     ,
     {
      name: '<% multilang("1283" "LANG_URL_BLOCKING"); %>',
      href: pageRoot + 'url_blocking.asp'
     }
     ,
     {
      name: '<% multilang("21" "LANG_DOMAIN_BLOCKING"); %>',
      href: pageRoot + 'domainblk.asp'
     }
     ,
     {
      name: '<% multilang("1284" "LANG_DMZ"); %>',
      href: pageRoot + 'fw-dmz.asp'
     }
    ]
   }
  ]
 };
 sub6 = {
  key: 6,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("33" "LANG_VOIP"); %>',
    items: [
     {
      name: '<% multilang("1352" "LANG_PORT1"); %>',
      href: pageRoot + 'voip_general_new_web.asp?port=0'
     }
     ,
     {
      name: '<% multilang("1310" "LANG_ADVANCE"); %>',
      href: pageRoot + 'voip_advanced_new_web.asp'
     }
     ,
     {
      name: '<% multilang("34" "LANG_TONE"); %>',
      href: pageRoot + 'voip_tone_new_web.asp'
     }
     ,
     {
      name: '<% multilang("35" "LANG_OTHER"); %>',
      href: pageRoot + 'voip_other_new_web.asp'
     }
     ,
     {
      name: '<% multilang("1356" "LANG_NETWORK"); %>',
      href: pageRoot + 'voip_network_new_web.asp'
     }
     ,
     {
      name: '<% multilang("1273" "LANG_VOIP_CALLHISTORY"); %>',
      href: pageRoot + 'voip_callhistory_new_web.asp'
     }
     ,
     {
      name: '<% multilang("961" "LANG_REGISTER_STATUS"); %>',
      href: pageRoot + 'voip_sip_status_new_web.asp'
     }
    ]
   }
  ]
 };
 sub7 = {
  key: 7,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("1310" "LANG_ADVANCE"); %>',
    items: [
     {
      name: '<% multilang("37" "LANG_ARP_TABLE"); %>',
      href: pageRoot + 'arptable.asp'
     }
     ,
     {
      name: '<% multilang("39" "LANG_BRIDGING"); %>',
      href: pageRoot + 'bridging.asp'
     }
     ,
     {
      name: '<% multilang("3197" "LANG_LOOP_DETECTION"); %>',
      href: pageRoot + 'lbd.asp'
     }
     ,
     {
      name: '<% multilang("40" "LANG_ROUTING"); %>',
      href: pageRoot + 'routing.asp'
     }
     ,
     {
      name: '<% multilang("45" "LANG_REMOTE_ACCESS"); %>',
      href: pageRoot + 'rmtacc.asp'
     }
    ]
   }
   ,
   {
    collapsed: true,
    name: '<% multilang("1330" "LANG_IP_QOS"); %>',
    items: [
     {
      name: '<% multilang("1287" "LANG_QOS_POLICY"); %>',
      href: pageRoot + 'net_qos_imq_policy.asp'
     },
     {
      name: '<% multilang("1286" "LANG_QOS_CLASSIFICATION"); %>',
      href: pageRoot + 'net_qos_cls.asp'
     },
     {
      name: '<% multilang("44" "LANG_TRAFFIC_SHAPING"); %>',
      href: pageRoot + 'net_qos_traffictl.asp'
     }
    ]
   }
   ,
   {
    collapsed: true,
    name: '<% multilang("5" "LANG_IPV6"); %>',
    items: [
     {
      name: '<% multilang("5" "LANG_IPV6"); %> <% multilang("272" "LANG_ENABLE"); %>/<% multilang("271" "LANG_DISABLE"); %>',
      href: pageRoot + 'ipv6_enabledisable.asp'
     }
     ,
     {
      name: '<% multilang("1278" "LANG_RADVD"); %>',
      href: pageRoot + 'radvdconf.asp'
     }
     ,
     {
      name: '<% multilang("26" "LANG_MLD_PROXY"); %>',
      href: pageRoot + 'app_mldProxy.asp'
     }
     ,
     {
      name: '<% multilang("28" "LANG_MLD_SNOOPING"); %>',
      href: pageRoot + 'app_mld_snooping.asp'
     }
     ,
     {
      name: '<% multilang("1280" "LANG_IPV6_ROUTING"); %>',
      href: pageRoot + 'routing_ipv6.asp'
     }
     ,
     {
      name: '<% multilang("1281" "LANG_IP_PORT_FILTERING"); %>',
      href: pageRoot + 'fw-ipportfilter-v6.asp'
     }
     ,
     {
      name: '<% multilang("1346" "LANG_IPV6_ACL"); %>',
      href: pageRoot + 'aclv6.asp'
     }
    ]
   }
  ]
 };
 sub8 = {
  key: 8,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("46" "LANG_DIAGNOSTICS"); %>',
    items: [
     {
      name: '<% multilang("919" "LANG_PING"); %>',
      href: pageRoot + 'ping.asp'
     }
     ,
     {
                        name: '<% multilang("919" "LANG_PING"); %>6',
                        href: pageRoot + 'ping6.asp'
                    }
                    ,
                    {
                        name: '<% multilang("920" "LANG_TRACERT"); %>',
                        href: pageRoot + 'tracert.asp'
                    }
     ,
                    {
                        name: '<% multilang("920" "LANG_TRACERT"); %>6',
                        href: pageRoot + 'tracert6.asp'
                    }
    ]
   }
  ]
 };
 sub9 = {
  key: 9,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("48" "LANG_ADMIN"); %>',
    items: [
     <% CheckMenuDisplay("pon_settings"); %>
     <% CheckMenuDisplay("omci_info"); %>
     {
      name: '<% multilang("1341" "LANG_COMMIT_REBOOT"); %>',
      href: pageRoot + 'reboot.asp'
     }
     ,
     {
      name: '<% multilang("1343" "LANG_BACKUP_RESTORE"); %>',
      href: pageRoot + 'saveconf.asp'
     }
     ,
     {
      name: '<% multilang("70" "LANG_SYSTEM_LOG"); %>',
      href: pageRoot + 'syslog.asp'
     }
     ,
     {
      name: '<% multilang("72" "LANG_PASSWORD"); %>',
      href: pageRoot + 'password.asp'
     }
     ,
     {
      name: '<% multilang("1345" "LANG_ACL"); %>',
      href: pageRoot + 'acl.asp'
     }
     ,
     {
      name: '<% multilang("74" "LANG_TIME_ZONE"); %>',
      href: pageRoot + 'tz.asp'
     }
     ,
     {
      name: '<% multilang("1347" "LANG_TR_069"); %>',
      href: pageRoot + 'tr069config.asp'
     }
    ]
   }
  ]
 };
 sub10 = {
  key: 10,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: '<% multilang("1311" "LANG_STATISTICS"); %>',
    items: [
     {
      name: '<% multilang("75" "LANG_INTERFACE"); %>',
      href: pageRoot + 'stats.asp'
     }
     ,
     {
      name: '<% multilang("927" "LANG_PON_STATISTICS"); %>',
      href: pageRoot + '/admin/pon-stats.asp'
     }
    ]
   }
  ]
 };
 sub11 = {
  key: 11,
  active: '0-0',
  items: [
   {
    collapsed: false,
    name: 'Hardware Mods',
    items: [
     {
      name: 'Change Serial/Mac and etc.',
      href: pageRoot + 'vermod.asp'
     },
     {
      name: 'Web Terminal',
      href: pageRoot + 'terminal.asp'
     },
     {
      name: 'MIB',
      href: pageRoot + 'mib.asp'
     },
     {
      name: 'Custom Script & Configuration',
      href: pageRoot + 'customconf.asp'
     },
     {
      name: 'Firmware',
      href: pageRoot + 'firmw.asp'
     },
     {
      name: 'About Mod',
      href: pageRoot + 'aboutmod.asp'
     }
    ]
   }
  ]
 };
 side.push(sub0);
 side.push(sub2);
 side.push(sub3);
 side.push(sub4);
 side.push(sub5);
    <% CheckMenuDisplay("voip_sub6"); %>
 side.push(sub7);
 side.push(sub8);
 side.push(sub9);
 side.push(sub10);
 side.push(sub11);
 return side;
}
function adaptNav(side, key) {
    key = (key - 0)
        || 0;
    var sideObj = {};
    for (var i = 0; i < side.length; i++) {
        if (side[i] && side[i].key === key) {
            sideObj.active = side[i].active;
            sideObj.items = side[i].items;
            for (var j = 0; j < sideObj.items.length; j++) {
                sideObj.items[j].index = j;
            }
            return sideObj;
        }
    }
}
function renderSide(key) {
    var side = adaptNav(generateSide(), key);
    var tpl = $('#side-tmpl').html();
    var html = juicer(tpl, side);
    $('#side').html(html);
}
function setActive(items, current) {
    $(items).removeClass('active');
    $(current).addClass('active');
}
function setAccordion(item) {
    var $item = $(item);
    var className = 'collapsed';
    var $currentLi = $item.parents('li');
    var $allLi = $item.parents('#side').children('li');
    var $currentContent = $currentLi.children('ul');
    $allLi.addClass(className);
    $currentLi.removeClass(className);
}
