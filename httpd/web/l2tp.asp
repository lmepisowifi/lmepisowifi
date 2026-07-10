















































<%SendWebHeadStr(); %>
<title>L2TP VPN <% multilang("262" "LANG_CONFIGURATION"); %></title>

<SCRIPT>
function checkTextStr(str)
{
	for (var i=0; i<str.length; i++) 
	{
		if ( str.charAt(i) == '%' || str.charAt(i) =='&' ||str.charAt(i) =='\\' || str.charAt(i) =='?' || str.charAt(i)=='"') 
			return false;			
	}
	return true;
}

function pppAuthChange()
{
	if (document.l2tp.auth.selectedIndex==3)
	{
		document.l2tp.enctype.disabled = false;
	}
	else
	{
		document.l2tp.enctype.disabled = true;
	}
}

function tunnelAuthChange()
{
	if (document.l2tp.tunnel_auth.checked)
		document.l2tp.tunnel_secret.disabled = false;
	else
		document.l2tp.tunnel_secret.disabled = true;
}

function connTypeChange()
{	
	document.l2tp.defaultgw.checked = false;
	document.l2tp.defaultgw.disabled = false;	
	if(document.l2tp.pppconntype.selectedIndex==1)
	{
		document.l2tp.idletime.disabled=false;		
		document.l2tp.defaultgw.checked = true;
		document.l2tp.defaultgw.disabled = true;
	}else{
		document.l2tp.idletime.disabled=true;		
	}
}

function l2tpSelection()
{
	if (document.l2tp.l2tpen[0].checked) {
		document.l2tp.server.disabled = true;
		document.l2tp.tunnel_auth.disabled = true;
		document.l2tp.tunnel_secret.disabled = true;
		document.l2tp.auth.disabled = true;
		document.l2tp.username.disabled = true;
		document.l2tp.password.disabled = true;
		document.l2tp.pppconntype.disabled = true;
		document.l2tp.idletime.disabled = true;
		document.l2tp.mtu.disabled = true;
		document.l2tp.defaultgw.disabled = true;
		document.l2tp.addL2TP.disabled = true;
		document.l2tp.enctype.disabled = true;
	}
	else {
		document.l2tp.server.disabled = false;
		document.l2tp.tunnel_auth.disabled = false;
		document.l2tp.tunnel_secret.disabled = false;
		document.l2tp.auth.disabled = false;
		document.l2tp.username.disabled = false;
		document.l2tp.password.disabled = false;
		document.l2tp.pppconntype.disabled = false;
		document.l2tp.idletime.disabled = false;
		document.l2tp.mtu.disabled = false;
		document.l2tp.defaultgw.disabled = false;
		document.l2tp.addL2TP.disabled = false;
		document.l2tp.enctype.disabled = false;
	}
	tunnelAuthChange();
	pppAuthChange();
	connTypeChange()
}

function onClickL2TPEnable()
{
	l2tpSelection();
	
	if (document.l2tp.l2tpen[0].checked)
		document.l2tp.lst.value = "disable";
	else
		document.l2tp.lst.value = "enable";
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	document.l2tp.submit();
}

function addL2TPItf(obj)
{
	if(document.l2tp.l2tpen[0].checked)
		return false;
	
	if (document.l2tp.server.value=="") {		
		alert('<% multilang("2312" "LANG_PLEASE_ENTER_L2TP_SERVER_ADDRESS"); %>');
		document.l2tp.server.focus();
		return false;
	}
	
	if(!checkTextStr(document.l2tp.server.value))
	{		
		alert('<% multilang("2313" "LANG_INVALID_VALUE_IN_SERVER_ADDRESS"); %>');
		document.l2tp.server.focus();
		return false;		
	}

	if (document.l2tp.tunnel_auth.checked)
	{
		if (document.l2tp.tunnel_secret.value=="")
		{			
			alert('<% multilang("2314" "LANG_PLEASE_ENTER_L2TP_TUNNEL_AUTHENTICATION_SECRET"); %>');
			document.l2tp.tunnel_secret.focus();
			return false;
		}
		if(!checkTextStr(document.l2tp.tunnel_secret.value))
		{			
			alert('<% multilang("2315" "LANG_INVALID_VALUE_IN_TUNNEL_AUTHENTICATION_SECRET"); %>');
			document.l2tp.tunnel_secret.focus();
			return false;		
		}
	}
	
	if (document.l2tp.auth.selectedIndex!=3)
	{
		if (document.l2tp.username.value=="")
		{			
			alert('<% multilang("2316" "LANG_PLEASE_ENTER_L2TP_CLIENT_USERNAME"); %>');
			document.l2tp.username.focus();
			return false;
		}
		if(!checkTextStr(document.l2tp.username.value))
		{			
			alert('<% multilang("2317" "LANG_INVALID_VALUE_IN_USERNAME"); %>');
			document.l2tp.username.focus();
			return false;		
		}
		if (document.l2tp.password.value=="") {			
			alert('<% multilang("2318" "LANG_PLEASE_ENTER_L2TP_CLIENT_PASSWORD"); %>');
			document.l2tp.password.focus();
			return false;
		}
		if(!checkTextStr(document.l2tp.password.value))
		{			
			alert('<% multilang("2319" "LANG_INVALID_VALUE_IN_PASSWORD"); %>');
			document.l2tp.password.focus();
			return false;		
		}
	}

	if (document.l2tp.pppconntype.selectedIndex==1)
	{
		if (document.l2tp.idletime.value=="")
		{			
			alert('<% multilang("2320" "LANG_PLEASE_ENTER_L2TP_TUNNEL_IDLE_TIME"); %>');
			document.l2tp.idletime.focus();
			return false;
		}
		
		if (document.l2tp.defaultgw.checked==false)
		{			
			alert('<% multilang("2321" "LANG_PLEASE_SELECT_DEFAULT_GATEWAY_FOR_DIAL_ON_DEMAND"); %>');
			document.l2tp.defaultgw.focus();
			return false;
		}
	}

	if (document.l2tp.mtu.value=="")
	{		
		alert('<% multilang("2322" "LANG_PLEASE_ENTER_L2TP_TUNNEL_MTU"); %>');
		document.l2tp.mtu.focus();
		return false;
	}

	obj.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	
	return true;
}

function deleteClick(obj)
{
	if ( !confirm('<% multilang("1781" "LANG_CONFIRM_DELETE_ONE_ENTRY"); %>') ) {
		return false;
	}
	else{
		obj.isclick = 1;
		postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
		return true;
	}
}

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
	<p class="intro_title">L2TP VPN <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content"> <% multilang("735" "LANG_THIS_PAGE_IS_USED_TO_CONFIGURE_THE_PARAMETERS_FOR_L2TP_MODE_VPN"); %></p>
</div>

<form action=/boaform/formL2TP method=POST name="l2tp">
<div class="data_common data_common_notitle">
	<table>
		<tr>
		  <th>L2TP VPN:</th>
		  <td>
		  	<input type="radio" value="0" name="l2tpen" <% checkWrite("l2tpenable0"); %> onClick="onClickL2TPEnable()"><% multilang("271" "LANG_DISABLE"); %>&nbsp;&nbsp;
		 	<input type="radio" value="1" name="l2tpen" <% checkWrite("l2tpenable1"); %> onClick="onClickL2TPEnable()"><% multilang("272" "LANG_ENABLE"); %>
		  </td>
		</tr>
	</table>
	<input type="hidden" id="lst" name="lst" value="">
</div>

<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th><% multilang("96" "LANG_SERVER"); %>:</th>
			<td><input type="text" name="server" size="32" maxlength="256"></td>
		</tr>
		<tr>
			<th><% multilang("736" "LANG_TUNNEL_AUTHENTICATION"); %>:</th>
			<td><input type=checkbox name="tunnel_auth" value=1 onClick=tunnelAuthChange()></td>
		</tr>
		<tr>
			<th><% multilang("737" "LANG_TUNNEL_AUTHENTICATION_SECRET"); %>:</th>
			<td><input type="text" name="tunnel_secret" size="15" maxlength="35"></td>
		</tr>
		<tr>
			<th>PPP <% multilang("225" "LANG_AUTHENTICATION"); %>:</th>
			<td><select name="auth" onChange="pppAuthChange()">
					<option value="0"><% multilang("191" "LANG_AUTO"); %></option>
					<option value="1">PAP</option>
					<option value="2">CHAP</option>
					<option value="3">CHAPMSV2</option>
				</select>
			</td>
		</tr>
		<tr>
			<th>PPP <% multilang("224" "LANG_ENCRYPTION"); %>:</th>
			<td><select name="enctype" >
					<option value="0"><% multilang("373" "LANG_NONE"); %></option>
					<option value="1">MPPE</option>
					<option value="2">MPPC</option>
					<option value="3">MPPE&MPPC</option>
				</select>
			</td>
		</tr>
		<tr>
			<th><% multilang("860" "LANG_USER"); %><% multilang("724" "LANG_NAME"); %>:</th>
			<td><input type="text" name="username" size="15" maxlength="35"></td>
		</tr>
		<tr>
			<th><% multilang("72" "LANG_PASSWORD"); %>:</th>
			<td><input type="text" name="password" size="15" maxlength="35"></td>
		</tr>
		<tr>
			<th>PPP <% multilang("309" "LANG_CONNECTION_TYPE"); %>:</th>
			<td><select name="pppconntype" onChange="connTypeChange()">
					<option value="0"><% multilang("738" "LANG_PERSISTENT"); %></option>
					<option value="1"><% multilang("739" "LANG_DIAL_ON_DEMAND"); %></option>
					<option value="2"><% multilang("493" "LANG_MANUAL"); %></option>
					<option value="3"><% multilang("373" "LANG_NONE"); %></option>
				</select>
			</td>
		</tr>
		<tr>
			<th><% multilang("321" "LANG_IDLE_TIME_SEC"); %>:</td>
			<td><input type="text" name="idletime" size="32" maxlength="256"></td>
		</tr>
		<tr>
			<th>MTU:</th>
			<td><input type="text" name="mtu" size="32" maxlength="256" value="1458"></td>
		</tr>
		<tr>
			<th><% multilang("90" "LANG_DEFAULT_GATEWAY"); %>:</th>
			<td><input type="checkbox" name="defaultgw"></td>
		</tr>
	</table>
</div>

<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="addL2TP" onClick="return addL2TPItf(this)">&nbsp;&nbsp;</td>
</div>

<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
			<p>L2TP <% multilang("357" "LANG_TABLE"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common data_vertical">
		<table>
			<tr>
				<th align=center width="3%"><% multilang("250" "LANG_SELECT"); %></th>
				<th align=center width="5%"><% multilang("75" "LANG_INTERFACE"); %></th>
				<th align=center width="5%"><% multilang("96" "LANG_SERVER"); %></th>
				<th align=center width="5%"><% multilang("736" "LANG_TUNNEL_AUTHENTICATION"); %></th>
				<th align=center width="5%">PPP <% multilang("225" "LANG_AUTHENTICATION"); %></th>
				<th align=center width="5%">MTU</th>
				<th align=center width="5%"><% multilang("90" "LANG_DEFAULT_GATEWAY"); %></th>
				<th align=center width="8%"><% multilang("734" "LANG_ACTION"); %></th>
			</tr>
			<% l2tpList(); %>
		</table>
	</div>
</div>

<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("248" "LANG_DELETE_SELECTED"); %>" name="delSel" onClick="return deleteClick(this)">&nbsp;&nbsp;
	<input type="hidden" value="/l2tp.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
<script>
	l2tpSelection();
</script>
</form>
</body>
</html>
