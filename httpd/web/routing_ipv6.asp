















































<%SendWebHeadStr(); %>
<title><% multilang("40" "LANG_ROUTING"); %><% multilang("262" "LANG_CONFIGURATION"); %></title>

<SCRIPT>
function postGW( enable, destNet, nextHop, metric, interface, select )
{
	document.route.enable.checked = enable;
	document.route.destNet.value=destNet;
	document.route.nextHop.value=nextHop;
	document.route.metric.value=metric;
	document.route.interface.value=interface;	
	document.route.select_id.value=select;	
}

function checkDest(ip, mask)
{
	var i, dip, dmask, nip;

	for (i=1; i<=4; i++) {
		dip = getDigit(ip.value, i);
		dmask = getDigit(mask.value,  i);
		nip = dip & dmask;
		if (nip != dip)
			return true;
	}
	return false;
}

function addClick(obj)
{

    //check destination
	if ( validateKeyV6IP( document.route.destNet.value ) == 0 ) {
           if(! validateKeyV6Prefix( document.route.destNet.value) )
           {
				alert("<% multilang("2464" "LANG_DESTNET_IS_NOT_VALID_IPV6_NET"); %>");
				document.route.destNet.focus();
				return false;
		   }
	}
    else if (! isGlobalIpv6Address( document.route.destNet.value) )
	{
		alert("<% multilang("2465" "LANG_DESTNET_IS_NOT_VALID_IPV6_HOST"); %>");
		document.route.destNet.focus();
		return false;
	}

    //check Next Hop
	if (document.route.nextHop.value=="" && document.route.interface.value == 0xffff) {
		alert("<% multilang("2456" "LANG_ENTER_NEXT_HOP_IP_OR_SELECT_A_GW_INTERFACE"); %>");
		document.route.nextHop.focus();
		return false;
	}

	if (document.route.nextHop.value!="") {
		if ( validateKeyV6IP( document.route.nextHop.value ) == 0 ) {
			alert("<% multilang("2457" "LANG_INVALID_NEXT_HOP_VALUE"); %>");
			document.route.nextHop.focus();
			return false;
		}
		else
		{
			if (! isGlobalIpv6Address( document.route.nextHop.value) && !isLinkLocalIpv6Address( document.route.nextHop.value)){
				alert("<% multilang("2466" "LANG_NEXTHOP_IS_NOT_VALID_GLOBAL_AND_UNICAST_IPV6_ADDRESS"); %>");
				document.route.nextHop.focus();
				return false;
			}
		}
	}

	//check metric
	if ( !checkDigitRange(document.route.metric.value,1,0,16) ) {
		alert("<% multilang("2463" "LANG_INVALID_METRIC_RANGE_IT_SHOULD_BE_0_16"); %>");
		document.route.metric.focus();
		return false;
	}
	obj.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}

function routeClick(url)
{
	var wide=600;
	var high=400;
	if (document.all)
		var xMax = screen.width, yMax = screen.height;
	else if (document.layers)
		var xMax = window.outerWidth, yMax = window.outerHeight;
	else
	   var xMax = 640, yMax=480;
	var xOffset = (xMax - wide)/2;
	var yOffset = (yMax - high)/3;

	var settings = 'width='+wide+',height='+high+',screenX='+xOffset+',screenY='+yOffset+',top='+yOffset+',left='+xOffset+', resizable=yes, toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes';

	window.open( url, 'RouteTbl', settings );
}

function deleteClick(obj)
{
	if ( !confirm('<% multilang("1781" "LANG_CONFIRM_DELETE_ONE_ENTRY"); %>') ) {
		return false;
	}
	else{
		obj.isclick = 1;
		postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
		return true;
	}
}
        
function deleteAllClick(obj)
{
	if ( !confirm('Do you really want to delete the all entries?') ) {
		return false;
	}
	else{
		obj.isclick = 1;
		postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
		return true;
	}
}
</SCRIPT>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("5" "LANG_IPV6"); %> <% multilang("511" "LANG_STATIC"); %> <% multilang("40" "LANG_ROUTING"); %> <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content"><% multilang("510" "LANG_THIS_PAGE_IS_USED_TO_CONFIGURE_THE_IPV6_STATIC_ROUTING_INFORMATION_HERE_YOU_CAN_ADD_DELETE_STATIC_IP_ROUTES"); %></p>
</div>

<form action=/boaform/formIPv6Routing method=POST name="route">
<div class="data_common data_common_notitle">
	<table>
  <tr>
      <th width="30%"><% multilang("272" "LANG_ENABLE"); %>:</th>
      <td width="70%"><input type="checkbox" name="enable" value="1" checked></td>
  </tr>
  <tr>
      <th width="30%"><% multilang("419" "LANG_DESTINATION"); %>:</th>
      <td width="70%"><input type="text" name="destNet" size="40" maxlength="40"></td>
  </tr>
  <tr>
      <th width="30%"><% multilang("471" "LANG_NEXT_HOP"); %>:</th>
      <td width="70%"><input type="text" name="nextHop" size="40" maxlength="48"></td>
  </tr>
  <tr>
      <th width="30%"><% multilang("472" "LANG_METRIC"); %>:</th>
      <td width="70%"><input type="text" name="metric" size="5" maxlength="5"></td>
  </tr>
  <tr>
      <th width="30%"><% multilang("75" "LANG_INTERFACE"); %>:</th>
      <td width="70%"><select name="interface">
          <% if_wan_list("rtv6-any-vpn"); %>
      	</select></td>
  </tr>
  <input type="hidden" value="" name="select_id">
</table>
</div>
<div class="btn_ctl">
  <input class="link_bg" type="submit" value="<% multilang("473" "LANG_ADD_ROUTE"); %>" name="addV6Route" onClick="return addClick(this)">&nbsp;&nbsp;
  <input class="link_bg" type="submit" value="<% multilang("474" "LANG_UPDATE"); %>" name="updateV6Route" onClick="return addClick(this)">&nbsp;&nbsp; 
  <input class="link_bg" type="submit" value="<% multilang("248" "LANG_DELETE_SELECTED"); %>" name="delV6Route" onClick="return deleteClick(this)">&nbsp;&nbsp;
  <input class="link_bg" type="submit" value="<% multilang("249" "LANG_DELETE_ALL"); %>" name="delAllV6Route" onClick="return deleteAllClick(this)">&nbsp;&nbsp;
  <input class="link_bg" type="button" value="<% multilang("475" "LANG_SHOW_ROUTES"); %>" name="showV6Route" onClick="routeClick('/routetbl_ipv6.asp')"> 
</div>

<div class="data_common data_common_notitle">
<table>
  <% showIPv6StaticRoute(); %>
</table>
</div>
      <input type="hidden" value="/routing_ipv6.asp" name="submit-url">
      <input type="hidden" name="postSecurityFlag" value="">
</form>

</body>

</html>
