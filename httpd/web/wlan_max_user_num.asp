<% SendWebHeadStr();%>
<title><% multilang("3329" "LANG_MAX_USER_NUM"); %></title>
<script src="customprompt.js"></script>
<script language="javascript">

function on_submit()
{
    showLoader('Applying Changes.');
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
</script>
</head>

<body >
<div class="intro_main ">
	<p class="intro_title"><% multilang("3330" "LANG_MAX_USER_NUM_CONFIG"); %></p>
	<p class="intro_content"><% multilang("3331" "LANG_PAGE_DISPLAY_AND_CONFIG_MAX_USER_NUM"); %></p>
	<p class="intro_content">(note: Setting the value to 0 means unlimited users.)</p>
</div>
<form action=/boaform/formMaxUserNum method=post name="formSamba">

<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width=40%><% multilang("3332" "LANG_MAX_USER_NUM_DISPLAY"); %></th>
			<td width=60%>
			 <% checkWrite("max_user_connect"); %>
			</td>
		</tr>
		
		<tbody id="conf">
			<tr >
				<th width=40%><% multilang("3333" "LANG_MAX_USER_NUM_SETUP"); %></th>
				<td width=60%><input type="text" name="MaxUserNum" maxlength="150"></td>
			</tr>
		</tbody>
	</table>
</div>
<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" onClick="return on_submit()">&nbsp;&nbsp;
	<input type="hidden" value="/wlan_max_user_num.asp" name="submit-url"> 
	<input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
<br><br>
</body>
</html>

