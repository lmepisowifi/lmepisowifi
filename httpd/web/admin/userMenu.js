












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
    name: '<% multilang("46" "LANG_DIAGNOSTICS"); %>',
    sub: 7
   },
   {
    name: '<% multilang("48" "LANG_ADMIN"); %>',
    sub: 8
   }
   ,
   {
    name: '<% multilang("1311" "LANG_STATISTICS"); %>',
    sub: 9
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
 var sub0, sub1, sub2, sub3, sub4, sub5, sub6, sub7, sub8, sub9;
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
                        href: pageRoot + 'admin/status.asp'
                    }
     ,
                    {
                        name: '<% multilang("5" "LANG_IPV6"); %>',
                        href: pageRoot + 'admin/status_ipv6.asp'
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
 sub2 = {
  key: 2,
  active: '0-0',
  items: [
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
     { name: '<% multilang("1292" "LANG_BASIC_SETTINGS"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlbasic.asp&wlan_idx=0' },
     { name: '<% multilang("9" "LANG_ADVANCED_SETTINGS"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wladvanced.asp&wlan_idx=0' },
     { name: '<% multilang("1293" "LANG_SECURITY"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlwpa.asp&wlan_idx=0' },
     { name: '<% multilang("1295" "LANG_ACCESS_CONTROL"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlactrl.asp&wlan_idx=0' },
     { name: '<% multilang("1300" "LANG_SITE_SURVEY"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlsurvey.asp&wlan_idx=0' },
     { name: '<% multilang("1301" "LANG_WPS"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlwps.asp&wlan_idx=0' },
     { name: '<% multilang("3" "LANG_STATUS"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlstatus.asp&wlan_idx=0' }
    ]
   },   // ← closes 5GHz block
   {
    collapsed: true,
    name: '<% multilang("1314" "LANG_WLAN1_2_4GHZ"); %>',
    items: [
     { name: '<% multilang("1292" "LANG_BASIC_SETTINGS"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlbasic.asp&wlan_idx=1' },
     { name: '<% multilang("9" "LANG_ADVANCED_SETTINGS"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wladvanced.asp&wlan_idx=1' },
     { name: '<% multilang("1293" "LANG_SECURITY"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlwpa.asp&wlan_idx=1' },
     { name: '<% multilang("1295" "LANG_ACCESS_CONTROL"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlactrl.asp&wlan_idx=1' },
     { name: '<% multilang("1300" "LANG_SITE_SURVEY"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlsurvey.asp&wlan_idx=1' },
     { name: '<% multilang("1301" "LANG_WPS"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlwps.asp&wlan_idx=1' },
     { name: '<% multilang("3" "LANG_STATUS"); %>', href: pageRoot + '../boaform/admin/formWlanRedirect?redirect-url=/admin/wlstatus.asp&wlan_idx=1' }
    ]
   },   // ← closes 2.4GHz block
   {
    collapsed: true,
    name: '<% multilang("3329" "LANG_MAX_USER_NUM"); %>',
    items: [
     {
      name: '<% multilang("3330" "LANG_MAX_USER_NUM_CONFIG"); %>',
      href: pageRoot + 'wlan_max_user_num.asp'
     }
    ]
   }    // ← Max User Num is a sibling, not inside 2.4GHz
   <% CheckMenuDisplay("factory_config_ver"); %>
  ]
 };
 sub7 = {
  key: 7,
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
     ,
     {
      name: '<% multilang("3197" "LANG_LOOP_DETECTION"); %>',
      href: pageRoot + 'lbd.asp'
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
                name: '<% multilang("48" "LANG_ADMIN"); %>',
                items: [
     {
      name: '<% multilang("1341" "LANG_COMMIT_REBOOT"); %>',
      href: pageRoot + 'admin/reboot.asp'
     }
     ,
     {
      name: '<% multilang("1342" "LANG_MULTI_LINGUAL_SETTINGS"); %>',
      href: pageRoot + 'multi_lang.asp'
     }
     ,
     {
      name: '<% multilang("70" "LANG_SYSTEM_LOG"); %>',
      href: pageRoot + 'admin/syslog.asp'
     }
     ,
     {
      name: '<% multilang("72" "LANG_PASSWORD"); %>',
      href: pageRoot + '/admin/user-password.asp'
     }
     ,
     {
      name: '<% multilang("1345" "LANG_ACL"); %>',
      href: pageRoot + 'admin/acl.asp'
     }
     ,
     {
      name: '<% multilang("74" "LANG_TIME_ZONE"); %>',
      href: pageRoot + 'admin/tz.asp'
     }
     ,
     {
      name: '<% multilang("69" "LANG_LOGOUT"); %>',
      href: pageRoot + '/admin/logout.asp'
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
    side.push(sub0);
 side.push(sub2);
    side.push(sub3);
 side.push(sub7);
 side.push(sub8);
 side.push(sub9);
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
