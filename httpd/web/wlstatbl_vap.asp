















































<% SendWebHeadStr();%>
<meta HTTP-EQUIV='Pragma' CONTENT='no-cache'>
<meta HTTP-equiv="Cache-Control" content="no-cache">
<title>Active Wireless Client Table</title>

<style>
.on {display:on}
.off {display:none}	
</style>
<script language="JavaScript" type="text/javascript">
var vap_num;
var vap_id;

function init()
{
	var url_tmp = location.href;
	var url_tmp_1 = url_tmp.split("?");
	var found = url_tmp_1[1].indexOf("%3D");
	if (found == -1) {
		var id = url_tmp_1[1].split("=");
		vap_id = id[1]*1;
	}
	else
		vap_id = parseInt(url_tmp_1[1].substring(5, 6));

	get_by_id("submit-url").value = "/admin/wlstatbl_vap.asp?id="+vap_id;
}

function on_submit()
{
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
</script>
</head>

<body>
<form action=/boaform/admin/formWirelessVAPTbl method=POST name="formWirelessVAPTbl">
<input type="hidden" value="" id="submit-url" name="submit-url">
<div class="intro_main ">
<p class="intro_title"><% multilang("178" "LANG_ACTIVE_WLAN_CLIENTS"); %> <% multilang("357" "LANG_TABLE"); %>
<script>
	init();
	if (vap_id == 1) {
		document.write(" - AP1");
		vap_num = 1;
	}
	else if (vap_id == 2) {
		document.write(" - AP2");
		vap_num = 2;
	}
	else if (vap_id == 3) {
		document.write(" - AP3");
		vap_num = 3;
	}
	else if (vap_id == 4) {
		document.write(" - AP4");
		vap_num = 4;
	}
	else {
		alert("<% multilang("2558" "LANG_WE_CAN_NOT_PROCESS_AP_THE_WINDOWS_WILL_BE_CLOSED"); %>");
		window.opener=null;   
		window.open("","_self");   
		window.close();
	}
</script>
</p>

<p class="intro_content">
	<% multilang("179" "LANG_THIS_TABLE_SHOWS_THE_MAC_ADDRESS"); %>
</p>
</div>
<div class="data_common data_vertical">
<script> if (vap_num != 1) document.write("</table><span class = \"off\" ><table>"); </script>
<table>
<tr>
	<th width="100"><% multilang("97" "LANG_MAC_ADDRESS"); %></th>
	<th width="60"><% multilang("151" "LANG_MODE"); %></th>
	<th width="60"><% multilang("180" "LANG_TX_PACKETS"); %></th>
	<th width="60"><% multilang("181" "LANG_RX_PACKETS"); %></th>
	<th width="60"><% multilang("182" "LANG_TX_RATE_MBPS"); %></th>
	<th width="60"><% multilang("183" "LANG_POWER_SAVING"); %></th>
	<th width="60"><% multilang("184" "LANG_EXPIRED_TIME_SEC"); %></th>
</tr>
<% wirelessVAPClientList(" ", "1"); %>
<script> if (vap_num != 1) document.write("</table></span><table >"); </script>

<script> if (vap_num != 2) document.write("</table><span class = \"off\" ><table>"); </script>
<tr>
	<th width="100"><% multilang("97" "LANG_MAC_ADDRESS"); %></th>
	<th width="60"><% multilang("151" "LANG_MODE"); %></th>
	<th width="60"><% multilang("180" "LANG_TX_PACKETS"); %></th>
	<th width="60"><% multilang("181" "LANG_RX_PACKETS"); %></th>
	<th width="60"><% multilang("182" "LANG_TX_RATE_MBPS"); %></th>
	<th width="60"><% multilang("183" "LANG_POWER_SAVING"); %></th>
	<th width="60"><% multilang("184" "LANG_EXPIRED_TIME_SEC"); %></th>
</tr>
<% wirelessVAPClientList(" ", "2"); %>
<script> if (vap_num != 2) document.write("</table></span><table >"); </script>

<script> if (vap_num != 3) document.write("</table><span class = \"off\" ><table>"); </script>
<tr>
	<th width="100"><% multilang("97" "LANG_MAC_ADDRESS"); %></th>
	<th width="60"><% multilang("151" "LANG_MODE"); %></th>
	<th width="60"><% multilang("180" "LANG_TX_PACKETS"); %></th>
	<th width="60"><% multilang("181" "LANG_RX_PACKETS"); %></th>
	<th width="60"><% multilang("182" "LANG_TX_RATE_MBPS"); %></th>
	<th width="60"><% multilang("183" "LANG_POWER_SAVING"); %></th>
	<th width="60"><% multilang("184" "LANG_EXPIRED_TIME_SEC"); %></th>
</tr>
<% wirelessVAPClientList(" ", "3"); %>
<script> if (vap_num != 3) document.write("</table></span><table>"); </script>

<script> if (vap_num != 4) document.write("</table><span class = \"off\" ><table>"); </script>
<tr>
	<th width="100"><% multilang("97" "LANG_MAC_ADDRESS"); %></th>
	<th width="60"><% multilang("151" "LANG_MODE"); %></th>
	<th width="60"><% multilang("180" "LANG_TX_PACKETS"); %></th>
	<th width="60"><% multilang("181" "LANG_RX_PACKETS"); %></th>
	<th width="60"><% multilang("182" "LANG_TX_RATE_MBPS"); %></th>
	<th width="60"><% multilang("183" "LANG_POWER_SAVING"); %></th>
	<th width="60"><% multilang("184" "LANG_EXPIRED_TIME_SEC"); %></th>
</tr>
<% wirelessVAPClientList(" ", "4"); %>
<script> if (vap_num != 4) document.write("</table></span><table>"); </script>

</table>
</div>
<div class="btn_ctl">
  <input type="submit" value="<% multilang("463" "LANG_REFRESH"); %>" onClick="return on_submit()" class="link_bg">&nbsp;&nbsp;
  <input type="button" value="<% multilang("766" "LANG_CLOSE"); %>" name="close" onClick="javascript: window.close();" class="link_bg">
  <input type="hidden" name="postSecurityFlag" value="">
 </div> 
</form>
<br><br>
</body>

</html>
