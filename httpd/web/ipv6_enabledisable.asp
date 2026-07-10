















































<%SendWebHeadStr(); %>
<title>IPv6 Enable/Disable</title>
<title><% multilang("480" "LANG_IPV6_E"); %> <% multilang("262" "LANG_CONFIGURATION"); %></title>

<SCRIPT>
function on_submit()
{
	//obj.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
</SCRIPT>
</HEAD>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("5" "LANG_IPV6"); %> <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content"><% multilang("479" "LANG_THIS_PAGE_BE_USED_TO_CONFIGURE_IPV6_ENABLE_DISABLE"); %></p>
</div>

<form id="form" action=/boaform/admin/formIPv6EnableDisable method=POST name="ipv6enabledisable">			
<div class="data_common data_common_notitle">
	<table border=0 width="500" cellspacing=4 cellpadding=0>		
		<tr>
			<th><% multilang("5" "LANG_IPV6"); %>:</th>
			<td>
				<input type="radio" value="0" name="ipv6switch" <% checkWrite("ipv6enabledisable0"); %> ><% multilang("271" "LANG_DISABLE"); %>&nbsp;&nbsp;
				<input type="radio" value="1" name="ipv6switch"<% checkWrite("ipv6enabledisable1"); %> ><% multilang("272" "LANG_ENABLE"); %>
			</td>
		</tr>
		<tr <% checkWrite("simpleSec_Display"); %>>
			<th>IPV6 Simple Security:</th>
			<td>
				<input type="radio" value="0" name="ipv6SimpleSec" <% checkWrite("ipv6SimpleSec0"); %> ><% multilang("271" "LANG_DISABLE"); %>&nbsp;&nbsp;
				<input type="radio" value="1" name="ipv6SimpleSec" <% checkWrite("ipv6SimpleSec1"); %> ><% multilang("272" "LANG_ENABLE"); %>
			</td>
		</tr>
		<tr <% checkWrite("logoTest_Display"); %>>
			<th>IPV6 Logo Test:</th>
			<td>
				<select name="logoTestMode" id="logoTestMode">
					<OPTION VALUE="0" > None</OPTION>
					<OPTION VALUE="1" > ReadyLogo Router</OPTION>
					<OPTION VALUE="2" > ReadyLogo Host</OPTION>
					<OPTION VALUE="3" > CE-Router</OPTION>
				</select>
			</td>
		</tr>
	</table>
</div>
<div class="btn_ctl">
	<input class="link_bg" type="submit" class="button" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" onClick="return on_submit()">
	<input type="hidden" value="/ipv6_enabledisable.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">		
</div>
<script>
	<% initPage("ipv6_advance"); %>
</script>
</form>
</body>
</html>
