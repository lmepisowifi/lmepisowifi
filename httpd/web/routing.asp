<% SendWebHeadStr();%>
<title><% multilang("40" "LANG_ROUTING"); %><% multilang("262" "LANG_CONFIGURATION"); %></title>
<script src="customprompt.js"></script>
<SCRIPT>
function postGW( enable, destNet, subMask, nextHop, metric, interface, select )
{
	document.route.enable.checked = enable;
	document.route.destNet.value=destNet;
	document.route.subMask.value=subMask;
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
	
	if (checkDest(document.route.destNet, document.route.subMask) == true) {
		alert("<% multilang("2462" "LANG_THE_SPECIFIED_MASK_PARAMETER_IS_INVALID_DESTINATION_MASK_DESTINATION"); %>");
		document.route.subMask.focus();
		return false;
	}
	if (!checkHostIP(document.route.destNet, 1))
		return false;
	if (!checkNetmask(document.route.subMask, 1))
		return false;
	if (document.route.interface.value==65535) {
		if (document.route.nextHop.value=="" ) {
			alert("<% multilang("2456" "LANG_ENTER_NEXT_HOP_IP_OR_SELECT_A_GW_INTERFACE"); %>");
			document.route.nextHop.focus();
			return false;
		}

		if (!checkHostIP(document.route.nextHop, 0))
			return false;
	}
        if(!checkIPandMask(document.route.destNet,document.route.subMask))
                return false;

	if ( !checkDigitRange(document.route.metric.value,1,0,16) ) {
		alert("<% multilang("2463" "LANG_INVALID_METRIC_RANGE_IT_SHOULD_BE_0_16"); %>");
		document.route.metric.focus();
		return false;
	}

	obj.isclick = 1;
	showLoader('Applying Changes.');
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
		showLoader('Applying Changes.');
		postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
		return true;
	}
}

</SCRIPT>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("40" "LANG_ROUTING"); %> <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content"> <% multilang("470" "LANG_THIS_PAGE_IS_USED_TO_CONFIGURE_THE_ROUTING_INFORMATION_HERE_YOU_CAN_ADD_DELETE_IP_ROUTES"); %></p>
</div>

<form action=/boaform/formRouting method=POST name="route">
<div class="data_common data_common_notitle">
	<table>
		<tr>
		  <th width="30%"><% multilang("272" "LANG_ENABLE"); %>:</th>
		  <td width="70%"><input type="checkbox" name="enable" value="1" checked></td>
		</tr>
		<tr>
		  <th width="30%"><% multilang("419" "LANG_DESTINATION"); %>:</th>
		  <td width="70%"><input type="text" name="destNet" size="15" maxlength="15"></td>
		</tr>
		<tr>
		  <th width="30%"><% multilang("95" "LANG_SUBNET_MASK"); %>:</th>
		  <td width="70%"><input type="text" name="subMask" size="15" maxlength="15"></td>
		</tr>
		<tr>
		  <th width="30%"><% multilang("471" "LANG_NEXT_HOP"); %>:</th>
		  <td width="70%"><input type="text" name="nextHop" size="15" maxlength="15"></td>
		</tr>
		<tr>
		  <th width="30%"><% multilang("472" "LANG_METRIC"); %>:</th>
		  <td width="70%"><input type="text" name="metric" size="5" maxlength="5"></td>
		</tr>
		<tr>
		  <th width="30%"><% multilang("75" "LANG_INTERFACE"); %>:</th>
		  <td width="70%"><select name="interface">
		      <% if_wan_list("rt-any-vpn"); %>
		  	</select></td>
		</tr>
		<input type="hidden" value="" name="select_id">
	</table>
</div>
<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("473" "LANG_ADD_ROUTE"); %>" name="addRoute" onClick="return addClick(this)">&nbsp;&nbsp;
	<input class="link_bg" type="submit" value="<% multilang("474" "LANG_UPDATE"); %>" name="updateRoute" onClick="return addClick(this)">&nbsp;&nbsp;
	<input class="link_bg" type="submit" value="<% multilang("248" "LANG_DELETE_SELECTED"); %>" name="delRoute" onClick="return deleteClick(this)">&nbsp;&nbsp;
	<input class="link_bg" type="button" value="<% multilang("475" "LANG_SHOW_ROUTES"); %>" name="showRoute" onClick="routeClick('/routetbl.asp')">
</div>
<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
		<p><% multilang("476" "LANG_STATIC_ROUTE_TABLE"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common data_vertical">
		<table>
			<% showStaticRoute(); %>
		</table>
	</div>
</div>
<input type="hidden" value="/routing.asp" name="submit-url">
<input type="hidden" name="postSecurityFlag" value="">
</form>
<br>
</body>
</html>
