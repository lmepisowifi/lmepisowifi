















































<%SendWebHeadStr(); %>
<title><% multilang("28" "LANG_MLD_SNOOPING"); %><% multilang("262" "LANG_CONFIGURATION"); %></title>
<SCRIPT>
function on_submit(obj)
{
	obj.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
</SCRIPT>
</HEAD>


<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("28" "LANG_MLD_SNOOPING"); %> <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content"><% multilang("455" "LANG_THIS_PAGE_BE_USED_TO_CONFIGURE_MLD_SNOOPING"); %></p>
</div>

<form id="form" action=/boaform/formMLDSnooping method=POST name="mldsnoop">				
	<div class="data_common data_common_notitle">				
		<table>
			<tr>
				<th width="30%"><% multilang("28" "LANG_MLD_SNOOPING"); %>:</th>
				<td>
					<input type="radio" name="snoop" value=0><% multilang("271" "LANG_DISABLE"); %>&nbsp;&nbsp;
					<input type="radio" name="snoop" value=1><% multilang("272" "LANG_ENABLE"); %>
				</td>
			</tr>
		</table>
	</div>	
	<div class="btn_ctl">			
		<input class="link_bg" type="submit" name="apply" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" onClick="return on_submit(this)"> 
		<input type="hidden" name="submit-url" value="/app_mld_snooping.asp">
		<input type="hidden" name="postSecurityFlag" value="">
	</div>	
	<script>
		<% initPage("mldsnooping"); %>	
	</script>			
</form>
<br><br>
</body>
</html>
