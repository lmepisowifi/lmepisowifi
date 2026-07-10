<% SendWebHeadStr();%>
<title>PON <% multilang("3" "LANG_STATUS"); %></title>
<script>
function on_submit()
{
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
</script>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title">PON <% multilang("3" "LANG_STATUS"); %></p>
	<p class="intro_content"><% multilang("113" "LANG_PAGE_DESC_PON_STATUS"); %></p>
</div>

<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
			<p><% multilang("1303" "LANG_PON"); %><% multilang("114" "LANG_STATUS_1"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common">
		<table>
			<tr>
				<th width=40%><% multilang("115" "LANG_VENDOR_NAME"); %></th>
				<td width=60%><% ponGetStatus("vendor-name"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("116" "LANG_PART_NUMBER"); %></th>
				<td width=60%><% ponGetStatus("part-number"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("117" "LANG_TEMPERATURE"); %></th>
				<td width=60%><% ponGetStatus("temperature"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("118" "LANG_VOLTAGE"); %></th>
				<td width=60%><% ponGetStatus("voltage"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("119" "LANG_TX_POWER"); %></th>
				<td width=60%><% ponGetStatus("tx-power"); %></td>
			<tr>
				<th width=40%><% multilang("120" "LANG_RX_POWER"); %></th>
				<td width=60%><% ponGetStatus("rx-power"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("122" "LANG_BIAS_CURRENT"); %></th>
				<td width=60%><% ponGetStatus("bias-current"); %></td>
			</tr>
		</table>
	</div>
</div>
<div class="column">
  <% showgpon_status(); %> 
</div>
<div class="column">
  <% showepon_LLID_status(); %> 
</div>
<form action=/boaform/admin/formStatus_pon method=POST name="status_pon">
	<div class="btn_ctl">
		<input type="hidden" value="/status_pon.asp" name="submit-url">
		<input class="link_bg" type="submit" value="<% multilang("463" "LANG_REFRESH"); %>" onClick="return on_submit()">&nbsp;&nbsp;
		<input type="hidden" name="postSecurityFlag" value="">
	</div> 
</form>
<br><br>
</body>
</html>
