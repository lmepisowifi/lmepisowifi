















































<%SendWebHeadStr(); %>
<title><% multilang("1178" "LANG_BUNDLE_INSTALLATION"); %></title>

<script>
function uploadClick()
{		
   	if (document.saveConfig.binary.value.length == 0) {
		alert('<% multilang("568" "LANG_CHOOSE_FILE"); %>!');
		document.saveConfig.binary.focus();
		return false;
	}
	return true;
}

</script>

</head>
<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("1178" "LANG_BUNDLE_INSTALLATION"); %></p>
	<p class="intro_content"> <% multilang("1179" "LANG_THIS_PAGE_ALLOWS_YOU_TO_INSTALL_NEW_BUNDLE"); %></p>
</div>

<form action=/boaform/formOsgiUpload enctype="multipart/form-data" method=POST name="saveConfig">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th><% multilang("1180" "LANG_INSTALL_BUNDLE_FROM_FILE"); %>:</th>
			<td><input type="file" value="<% multilang("568" "LANG_CHOOSE_FILE"); %>" name="binary" size=24></td>
		</tr>  
	</table>
</div>

<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("1275" "LANG_INSTALL"); %>" name="load" onclick="return uploadClick()"></td>
	<input type="hidden" value="/osgi_bndins.asp" name="submit-url">
</div>  
</form> 
</body>
</html>
