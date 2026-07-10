<%SendWebHeadStr(); %>
<title><% multilang("29" "LANG_IGMP_PROXY"); %><% multilang("262" "LANG_CONFIGURATION"); %></title>
<script src="customprompt.js"></script>
<SCRIPT>
var multicast_allow=0;
var robust_count=0;
var last_member_query_count=0;
var query_interval=0;
var query_response_interval=0;
var group_leave_delay=0;
var multi_wan_proxy=0;
<% igmpproxyinit(); %>
function on_init()
{
	with(document.forms[0])
	{
		if(multicast_allow == 0)
			igmp_multicast_allow[0].checked = true;
		else
			igmp_multicast_allow[1].checked = true;
		igmp_robust_count.value = robust_count;
		igmp_last_member_query_count.value = last_member_query_count;
		igmp_query_interval.value = query_interval;
		igmp_query_response_interval.value = query_response_interval;
		igmp_group_leave_delay.value = group_leave_delay;
	}
	if(multi_wan_proxy == 1)
	{
	   document.getElementById("proxy_enable").style="display:none";
	   document.getElementById("proxy_intf").style="display:none";
	 }
	 else
	 {
	   document.getElementById("proxy_enable").style="display:";
	   document.getElementById("proxy_intf").style="display:";
	  }
	proxySelection();
}
function proxySelection()
{
	if (document.igmp.proxy[0].checked && multi_wan_proxy == 0) {
		document.igmp.proxy_if.disabled = true;
		document.igmp.igmp_multicast_allow[0].disabled = true;
		document.igmp.igmp_multicast_allow[1].disabled = true;
		document.igmp.igmp_robust_count.disabled = true;
		document.igmp.igmp_last_member_query_count.disabled = true;
		document.igmp.igmp_query_interval.disabled = true;
		document.igmp.igmp_query_response_interval.disabled = true;
		document.igmp.igmp_group_leave_delay.disabled = true;
	}
	else {
		document.igmp.proxy_if.disabled = false;
		document.igmp.igmp_multicast_allow[0].disabled = false;
		document.igmp.igmp_multicast_allow[1].disabled = false;
		document.igmp.igmp_robust_count.disabled = false;
		document.igmp.igmp_last_member_query_count.disabled = false;
		document.igmp.igmp_query_interval.disabled = false;
		document.igmp.igmp_query_response_interval.disabled = false;
		document.igmp.igmp_group_leave_delay.disabled = false;
	}
}

function on_submit()
{
	with(document.forms[0]) {
		if (igmp_query_response_interval.value > 128) {
			alert('<% multilang("3129" "LANG_QUERY_RESPONSE_INTERVAL_NOT_SUPPORT_128"); %>');
			return false;
		}
		else {
		showLoader('Applying Changes.');
			postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
			return true;
		}
	}
}
</SCRIPT>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("29" "LANG_IGMP_PROXY"); %> <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content"> <% multilang("790" "LANG_IGMP_PROXY_ENABLES_THE_SYSTEM_TO_ISSUE_IGMP_HOST_MESSAGES_ON_BEHALF_OF_HOSTS_THAT_THE_SYSTEM_DISCOVERED_THROUGH_STANDARD_IGMP_INTERFACES_THE_SYSTEM_ACTS_AS_A_PROXY_FOR_ITS_HOSTS_WHEN_YOU_ENABLE_IT_BY_DOING_THE_FOLLOWS"); %>:
    <br>. <% multilang("791" "LANG_ENABLE_IGMP_PROXY_ON_WAN_INTERFACE_UPSTREAM_WHICH_CONNECTS_TO_A_ROUTER_RUNNING_IGMP"); %>
    <br>. <% multilang("792" "LANG_ENABLE_IGMP_ON_LAN_INTERFACE_DOWNSTREAM_WHICH_CONNECTS_TO_ITS_HOSTS"); %></p>
</div>

<form action=/boaform/formIgmproxy method=POST name="igmp">
<div class="data_common data_common_notitle">
	<table>
		<tr id="proxy_enable">
			<th><% multilang("29" "LANG_IGMP_PROXY"); %>:</th>
			<td>
				<input type="radio" value="0" name="proxy" <% checkWrite("igmpProxy0"); %> onClick="proxySelection()"><% multilang("271" "LANG_DISABLE"); %>&nbsp;&nbsp;
				<input type="radio" value="1" name="proxy" <% checkWrite("igmpProxy1"); %> onClick="proxySelection()"><% multilang("272" "LANG_ENABLE"); %>
			</td>
		</tr>
		<tr id="proxy_intf">
			<th><% multilang("793" "LANG_PROXY_INTERFACE"); %>:</th>
			<td>
				<select name="proxy_if" <% checkWrite("igmpProxy0d"); %>>
			  		<% if_wan_list("rt"); %>
				</select>
			</td>
		</tr>
		<tr id = "igmp_multicast_allow_id" style="display:none">
			<th><% multilang("3123" "LANG_MULTICAST_ALLOWED"); %>:</th>
			<td>
				<input type="radio" value="0" name="igmp_multicast_allow"><% multilang("271" "LANG_DISABLE"); %>
				<input type="radio" value="1" name="igmp_multicast_allow"><% multilang("272" "LANG_ENABLE"); %>
			</td>
		</tr>
		<tr>
			<th><% multilang("3124" "LANG_IGMP_ROBUST_COUNT"); %>:</th>
			<td>
				<input type="text" name="igmp_robust_count" size="10" maxlength="15">
			</td>
		</tr>
		<tr>
			<th><% multilang("3125" "LANG_IGMP_LAST_MEMBER_QUERY_COUNT"); %>:</th>
			<td>
				<input type="text" name="igmp_last_member_query_count" size="10" maxlength="15">
			</td>
		</tr>
		<tr>
			<th><% multilang("3126" "LANG_IGMP_QUERY_INTERVAL"); %>:</th>
			<td>
				<input type="text" name="igmp_query_interval" size="10" maxlength="15">(seconds)
			</td>
		</tr>
		<tr>
			<th><% multilang("3127" "LANG_IGMP_QUERY_RESPONSE_INTERVAL"); %>:</th>
			<td>
				<input type="text" name="igmp_query_response_interval" size="10" maxlength="15">(*100ms)
			</td>
		</tr>
		<tr>
			<th><% multilang("3128" "LANG_IGMP_GROUP_LEAVE_DELAY"); %>:</th>
			<td>
				<input type="text" name="igmp_group_leave_delay" size="10" maxlength="15">(ms)
			</td>
		</tr>
	</table>
</div>

<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" onClick="return on_submit()">
	<input type="hidden" value="/igmproxy.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
<script>
	ifIdx = <% getInfo("igmp-proxy-itf"); %>;
	if (ifIdx != 255)
		document.igmp.proxy_if.value = ifIdx;
	else
		document.igmp.proxy_if.selectedIndex = 0;
	on_init();
</script>
</form>
</body>

</html>
