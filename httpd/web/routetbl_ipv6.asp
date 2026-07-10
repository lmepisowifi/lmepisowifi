















































<% SendWebHeadStr();%>
<title><% multilang("909" "LANG_IP_ROUTE_TABLE"); %></title>

<SCRIPT>
function on_submit()
{
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
</SCRIPT>
</head>

<body>
<div class="intro_main ">
<p class="intro_title"><% multilang("909" "LANG_IP_ROUTE_TABLE"); %></p>
<p class="intro_content"><% multilang("910" "LANG_THIS_TABLE_SHOWS_A_LIST_OF_DESTINATION_ROUTES_COMMONLY_ACCESSED_BY_YOUR_NETWORK"); %></p>
</div>


<form action=/boaform/formIPv6RefleshRouteTbl method=POST name="formIPv6RouteTbl">
<div class="data_common data_vertical">	
	<table border='1' width="80%">
		<% routeIPv6List(); %>
	</table>
</div>
<div class="btn_ctl">
	<input type="hidden" value="/routetbl_ipv6.asp" name="submit-url">
	<input type="submit" value="<% multilang("463" "LANG_REFRESH"); %>" onClick="return on_submit()" class="link_bg">&nbsp;&nbsp;
	<input type="button" value="<% multilang("766" "LANG_CLOSE"); %>" name="close" onClick="javascript: window.close();" class="link_bg">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
<br><br>
</body>

</html>
