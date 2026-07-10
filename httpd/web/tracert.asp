















































<% SendWebHeadStr();%>
<title>Tracert <% multilang("46" "LANG_DIAGNOSTICS"); %></title>
<script>
function on_Apply(obj) 
{
	var submit_elm=document.getElementById("tracertSubmit");

	if(document.getElementById('traceAddr').value == "")
	{
		alert("Should input a domain or ip address!");
		document.getElementById('traceAddr').focus();
		return false;
	}

	document.getElementById("status").style.display = "";
	if (submit_elm.value=="<% multilang("541" "LANG_START"); %>")
		document.tracert.tracertAct.value="Start";
	else
		document.tracert.tracertAct.value="Stop";
	document.getElementById("tracertSubmit").value = "<% multilang("834" "LANG_STOP"); %>"

	obj.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}

function on_init(){
	<% clearTracertResult(); %>
}
</script>
</head>

<body onload="on_init();">
<div class="intro_main ">
	<p class="intro_title">Traceroute <% multilang("46" "LANG_DIAGNOSTICS"); %></p>
	<p class="intro_content"><% multilang("522" "LANG_PAGE_DESC_TRACERT_DIAGNOSTIC"); %></p>
</div>
<form id="form" action=/boaform/formTracert method=POST name="tracert">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%"><% multilang("101" "LANG_PROTOCOL"); %>:</th>
			<td width="70%">
				<select name="proto">
					<option value="0">ICMP</option>
					<option value="1">UDP</option>
				</select>
			</td>
		</tr>
		<tr>
			<th width="30%"><% multilang("524" "LANG_HOST_ADDRESS"); %>:</th>
			<td width="70%"><input type="text" id="traceAddr" name="traceAddr" size="30" maxlength="50"></td>
		</tr>
		<tr>
			<th width="30%"><% multilang("3136" "LANG_NUMBER_OF_TRIES"); %>:</th>
			<td width="70%"><input type="text" id="trys" name="trys" size="5" maxlength="5" value="3"></td>
		</tr>
		<tr>
			<th width="30%"><% multilang("3137" "LANG_TIME_OUT"); %>:</th>
			<td width="70%"><input type="text" id="timeout" name="timeout" size="10" maxlength="10" value="5">s</td>
		</tr>
		<tr>
			<th width="30%"><% multilang("3138" "LANG_DATA_SIZE"); %>:</th>
			<td width="70%"><input type="text" id="datasize" name="datasize" size="10" maxlength="10" value="56">Bytes</td>
		</tr>
		<tr>
			<th width="30%"><% multilang("3139" "LANG_DSCP"); %>:</th>
			<td width="70%"><input type="text" id="dscp" name="dscp" size="10" maxlength="10" value="0"></td>
		</tr>
		<tr>
			<th width="30%"><% multilang("3140" "LANG_MAX_HOP_COUNT"); %>:</th>
			<td width="70%"><input type="text" id="maxhop" name="maxhop" size="10" maxlength="10" value="30"></td>
		</tr>
		<tr>
			<th width="30%"><% multilang("454" "LANG_WAN_INTERFACE"); %>: </th>
			<td width="70%"><select name="wanif"><% if_wan_list("rt-any-vpn"); %></select></td>
		</tr>
	</table>
</div>
<div class="data_common data_common_notitle" id="status" style="display:none">
	<iframe src="tracert_result.asp" width="100%" height="100%"></iframe>
</div>
<div class="btn_ctl">
	<input type="hidden" name="tracertAct">
	<input id="tracertSubmit" class="link_bg" type="submit" value="<% multilang("541" "LANG_START"); %>" name="go" onClick="return on_Apply(this)">
	<input type="hidden" value="/tracert.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
<br>
<br>
</body>
</html>
