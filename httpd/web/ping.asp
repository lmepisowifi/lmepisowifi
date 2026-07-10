















































<% SendWebHeadStr();%>
<title>Ping <% multilang("46" "LANG_DIAGNOSTICS"); %></title>

<SCRIPT>
function goClick()
{
	var submit_elm=document.getElementById("pingSubmit");

	if (document.ping.pingAddr.value=="") {
		alert("Enter host address !");
		document.ping.pingAddr.focus();
		return false;
	}

	document.getElementById("status").style.display = "";
	if (submit_elm.value=="<% multilang("541" "LANG_START"); %>")
		document.ping.pingAct.value="Start";
	else
		document.ping.pingAct.value="Stop";
	document.getElementById("pingSubmit").value = "<% multilang("834" "LANG_STOP"); %>";
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
}

function on_init(){
	<% clearPingResult(); %>
}
</SCRIPT>
</head>

<body onload="on_init();">
<div class="intro_main ">
	<p class="intro_title">Ping <% multilang("46" "LANG_DIAGNOSTICS"); %></p>
	<p class="intro_content">  <% multilang("520" "LANG_PAGE_DESC_ICMP_DIAGNOSTIC"); %></p>
</div>

<form action=/boaform/formPing method=POST name="ping">
<div class="data_common data_common_notitle">
	<table>
	  <tr>
	      <th width="30%"><% multilang("524" "LANG_HOST_ADDRESS"); %>: </th>
	      <td width="70%"><input type="text" name="pingAddr" size="30" maxlength="30"></td>
	  </tr>
	  <tr>
	  	  <th width="30%"><% multilang("454" "LANG_WAN_INTERFACE"); %>: </th>
	  	  <td width="70%"><select name="wanif"><% if_wan_list("rt-any-vpn"); %></select></td>
	  </tr>
	</table>
</div>
<div class="data_common data_common_notitle" id="status" style="display:none">
	<iframe src="ping_result.asp" width="100%" height="100%"></iframe>
</div>
<div class="btn_ctl">
      <input type="hidden" name="pingAct">
      <input id="pingSubmit" class="link_bg" type="submit" value="<% multilang("541" "LANG_START"); %>" onClick="return goClick()">
      <input type="hidden" value="/ping.asp" name="submit-url">
      <input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
<br><br>
</body>
</html>
