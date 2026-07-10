















































<% SendWebHeadStr();%>
<title><% multilang("895" "LANG_BRIDGE_FORWARDING_DATABASE"); %></title>
<SCRIPT>
function on_submit(obj)
{
	obj.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
</SCRIPT>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("895" "LANG_BRIDGE_FORWARDING_DATABASE"); %></p>
	<p class="intro_content"> <% multilang("461" "LANG_PAGE_DESC_MAC_TABLE_INFO"); %></p>
</div>

<form action=/boaform/formRefleshFdbTbl method=POST name="formFdbTbl">
<div class="data_common data_vertical">
	<table>
		<tr> 
			<th width="10%"><% multilang("236" "LANG_PORT"); %></th>
			<th width="20%"><% multilang("97" "LANG_MAC_ADDRESS"); %></th>
			<th width="10%"><% multilang("897" "LANG_IS_LOCAL"); %>?</th>
			<th width="10%"><% multilang("898" "LANG_AGEING_TIMER"); %></th>
		</tr>
		<% bridgeFdbList(); %>
	</table>
</div>
<div class="btn_ctl">
	<input type="hidden" value="/fdbtbl.asp" name="submit-url">
	<input class="link_bg" type="submit" value="<% multilang("463" "LANG_REFRESH"); %>" name="refresh" onClick="return on_submit(this)">&nbsp;&nbsp;
	<input class="link_bg" type="button" value="<% multilang("766" "LANG_CLOSE"); %>" name="close" onClick="javascript: window.close();">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
<br><br>
</body>

</html>
