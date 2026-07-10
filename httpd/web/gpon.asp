















































<% SendWebHeadStr();%>
<title><% multilang("50" "LANG_GPON_SETTINGS"); %></title>

<script>
var pw_length = <% fmgpon_checkWrite("ploam_pw_length"); %>;

function applyclick(obj)
{
	var fieldcheck = 0;
	
	if (document.formgponconf.fmgpon_loid.value=="") {		
		//alert('<% multilang("2289" "LANG_LOID_CANNOT_BE_EMPTY"); %>');
		//document.formgponconf.fmgpon_loid.focus();
		//return false;
		fieldcheck += 1;
	}
	
	if (document.formgponconf.fmgpon_loid_password.value=="") {		
		//alert('<% multilang("2290" "LANG_LOID_PASSWORD_CANNOT_BE_EMPTY"); %>');
		//document.formgponconf.fmgpon_loid_password.focus();
		//return false;
		fieldcheck += 2;
	}
	
	if (document.formgponconf.fmgpon_ploam_password.value=="") {
		//alert('<% multilang("2293" "LANG_PLOAM_PASSWORD_CANNOT_BE_EMPTY"); %>');
		//document.formgponconf.fmgpon_ploam_password.focus();
		//return false;
		fieldcheck += 4;
	}

	if ( fieldcheck == 5 ){ // only fill LOID PASSWORD
		alert('<% multilang("2289" "LANG_LOID_CANNOT_BE_EMPTY"); %>');
		document.formgponconf.fmgpon_loid.focus();
		return false;
	}

	if (includeSpace(document.formgponconf.fmgpon_loid_password.value) && (fieldcheck == 4)) {		
		alert('<% multilang("2291" "LANG_CANNOT_ACCEPT_SPACE_CHARACTER_IN_LOID_PASSWORD"); %>');
		document.formgponconf.fmgpon_loid_password.focus();
		return false;
	}
	if (checkString(document.formgponconf.fmgpon_loid_password.value) == 0 && (fieldcheck == 4)) {		
		alert('<% multilang("2292" "LANG_INVALID_LOID_PASSWORD"); %>');
		document.formgponconf.fmgpon_loid_password.focus();
		return false;
	}

	if (includeSpace(document.formgponconf.fmgpon_ploam_password.value) && (fieldcheck == 3)) {		
		alert('<% multilang("2294" "LANG_CANNOT_ACCEPT_SPACE_CHARACTER_IN_PLOAM_PASSWORD"); %>');
		document.formgponconf.fmgpon_ploam_password.focus();
		return false;
	}
	if (checkString(document.formgponconf.fmgpon_ploam_password.value) == 0 && (fieldcheck == 3)) {		
		alert('<% multilang("2295" "LANG_INVALID_PLOAM_PASSWORD"); %>');
		document.formgponconf.fmgpon_ploam_password.focus();
		return false;
	}
	if( document.formgponconf.fmgpon_ploam_password.value.length>pw_length && (fieldcheck == 3) )
	{		
		alert('<% multilang("2296" "LANG_PLOAM_PASSWORD_SHOULD_BE_10_CHARACTERS"); %>');
		document.formgponconf.fmgpon_ploam_password.focus();
		return false;
	}
		        try {
            const parentDoc = window.parent.document;
            // 2. Show the Loader and Shade
            const loader = parentDoc.getElementById("loadpagediv");
            const shade = parentDoc.getElementById("shade");

            if (loader) {
                loader.style.display = "block";
            }
            if (shade) shade.style.display = "block";
        } catch (e) {
            console.error(e);
        }


	obj.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
</script>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("50" "LANG_GPON_SETTINGS"); %></p>
	<p class="intro_content"><% multilang("560" "LANG_THIS_PAGE_IS_USED_TO_CONFIGURE_THE_PARAMETERS_FOR_YOUR_GPON_NETWORK_ACCESS"); %></p>
</div>
<form action=/boaform/admin/formgponConf method=POST name="formgponconf">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="40%"><% multilang("561" "LANG_LOID"); %>:</th>
			<td><input type="text" name="fmgpon_loid" size="24" maxlength="24" value="<% fmgpon_checkWrite("fmgpon_loid"); %>"></td>
		</tr>
		<tr>
			<th width="40%"><% multilang("562" "LANG_LOID_PASSWORD"); %>:</th>
			<td><input type="text" name="fmgpon_loid_password" size="20" maxlength="12" value="<% fmgpon_checkWrite("fmgpon_loid_password"); %>"></td>
		</tr>
		<tr>
			<th width="40%"><% multilang("563" "LANG_PLOAM_PASSWORD"); %>:</th>
			<td><input type="text" name="fmgpon_ploam_password" size="36" maxlength="36" value="<% fmgpon_checkWrite("fmgpon_ploam_password"); %>" ></td>
		</tr>
		<tr>
			<th><% multilang("564" "LANG_SERIAL_NUMBER"); %>:</th>
			<td><% fmgpon_checkWrite("fmgpon_sn"); %></td>
		</tr>
		<% showOMCI_OLT_mode(); %>
	</table>
</div>
<div class="btn_ctl clearfix">
      <input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="apply" onClick="return applyclick(this)">&nbsp;&nbsp;
      <input type="hidden" value="/gpon.asp" name="submit-url">
      <input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
<br><br>
</body>
</html>
