<% SendWebHeadStr();%>
<meta HTTP-EQUIV='Pragma' CONTENT='no-cache'>
<title><% multilang("581" "LANG_PASSWORD_CONFIGURATION"); %></title>
<script src="customprompt.js"></script>
<script type="text/javascript" src="admin/md5.js"></script>
<SCRIPT>

var password_encrypt_flag= <% checkWrite("password_encrypt_flag"); %>;
var realm = <% checkWrite("realm"); %>;
var username = <% checkWrite("username"); %>;
var susername = <% checkWrite("susername"); %>;
var username_cal = "";

function saveChanges(obj)
{


   if ( document.password.newpass.value != document.password.confpass.value) {
	alert("<% multilang("2115" "LANG_PASSWORD_IS_NOT_MATCHED_PLEASE_TYPE_THE_SAME_PASSWORD_BETWEEN_NEW_AND_CONFIRMED_BOX"); %>");
	document.password.newpass.focus();
	return false;
  }

//  if ( document.password.username.value.length > 0 &&
//  		document.password.newpass.value.length == 0 ) {
  if (	document.password.newpass.value.length == 0) {
	alert("<% multilang("2116" "LANG_PASSWORD_CANNOT_BE_EMPTY_PLEASE_TRY_IT_AGAIN"); %>");
	document.password.newpass.focus();
	return false;
  }



  if (includeSpace(document.password.newpass.value)) {
	alert("<% multilang("2119" "LANG_CANNOT_ACCEPT_SPACE_CHARACTER_IN_PASSWORD_PLEASE_TRY_IT_AGAIN"); %>");
	document.password.newpass.focus();
	return false;
  }
  if (checkString(document.password.newpass.value) == 0) {
	alert("<% multilang("2120" "LANG_INVALID_PASSWORD"); %>");
	document.password.newpass.focus();
	return false;
  }
  
  if(password_encrypt_flag)
  {
  	if(document.password.userMode.value == "1")
  	{
		username_cal = username;
	}
	else
  	{
		username_cal = susername;
	}
		
	document.password.oldpass.value = hex_md5(username_cal + ":"  + realm + ":" + document.password.oldpass.value);
	document.password.newpass.value = hex_md5(username_cal + ":"  + realm + ":" + document.password.newpass.value);
	document.password.confpass.value = hex_md5(username_cal + ":"  + realm + ":" + document.password.confpass.value);
  }
	obj.isclick = 1;
	showLoader('Applying Changes.');
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	
  return true;
}

</SCRIPT>
</head>

<BODY>
<div class="intro_main ">
	<p class="intro_title"><% multilang("581" "LANG_PASSWORD_CONFIGURATION"); %></p>
	<p class="intro_content">  <% multilang("577" "LANG_PAGE_DESC_SET_ACCOUNT_PASSWORD"); %></p>
</div>
<form action=/boaform/formPasswordSetup method=POST name="password">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="40%"><% multilang("860" "LANG_USER"); %><% multilang("724" "LANG_NAME"); %>:</th>
			<td><select size="1" name="userMode">
				<% checkWrite("userMode"); %>
				</select>
			</td>
		</tr>
		<tr>
			<th><% multilang("578" "LANG_OLD_PASSWORD"); %>:</th>
			<td><input type="password" name="oldpass" size="20" maxlength="24"></td>
		</tr>
		<tr>
			<th><% multilang("579" "LANG_NEW_PASSWORD"); %>:</th>
			<td><input type="password" name="newpass" size="20" maxlength="24"></td>
		</tr>
		<tr>
			<th><% multilang("580" "LANG_CONFIRMED_PASSWORD"); %>:</th>
			<td><input type="password" name="confpass" size="20" maxlength="24"></td>
		</tr>
	</table>
</div>
<div class="btn_ctl clearfix">
	<input type="hidden" value="/password.asp" name="submit-url">
	<input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="save" onClick="return saveChanges(this)">&nbsp;&nbsp;
	<input class="link_bg" type="reset" value="  <% multilang("246" "LANG_RESET"); %>  " name="reset">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
<br><br>
</body>
</html>


