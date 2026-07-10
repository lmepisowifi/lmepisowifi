















































<% SendWebHeadStr();%>
<title>ACL <% multilang("262" "LANG_CONFIGURATION"); %></title>
<SCRIPT>
var _telnet = 0;
var _ftp = 0;
var _tftp = 0;
var _web = 0;
var _https = 0;
var _snmp = 0;
var _ssh = 0;

function postACL( enable, interface, aclIP )
{
	document.acl.enable.checked = enable;		
	document.acl.interface.value = interface;	
	document.acl.aclIP.value = aclIP;	
}

function addClick(obj)
{
	
	
	<% checkAclItems("if_ip_valid"); %>
	with ( document.forms[0] ) 
	{
		<% checkAclItems("if_service_open"); %>
		if(interface.value == 1)	//wan
		{
			if((_telnet || _ftp || _tftp || _web || _https || _snmp || _ssh || _icmp)==0 )
			{
				alert('please choose service.');
				return false;
			}
		}
	}
	document.forms[0].addIP.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}

function deleteClick()
{
	if ( !confirm('<% multilang("1781" "LANG_CONFIRM_DELETE_ONE_ENTRY"); %>') ) {
		return false;
	}
	else
	{
		document.forms[0].delIP.isclick = 1;
		postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
		return true;
	}
}
	
function disableDelButton()
{
  if (verifyBrowser() != "ns") {
	disableButton(document.acl.delIP);
	//disableButton(document.acl.delAllIP);
  }
}

function intfchange(obj)
{
	with ( document.forms[0] ) 
	{
		if(obj.value == "0")
		{
			if (document.getElementById) {  // DOM3 = IE5, NS6
				document.getElementById('serviceLANID').style.display = '';
				document.getElementById('serviceLANID2').style.display = '';
				document.getElementById('div_lan').style.display = '';
				document.getElementById('serviceWANID').style.display = 'none';
			}
			else {
				if (document.layers == false) { // IE4
					document.all.serviceLANID.style.display = '';
					document.all.serviceLANID2.style.display = '';
					document.all.div_lan.style.display = '';
					document.all.serviceWANID.style.display = 'none';
				}
			}
		}
		else
		{
			if (document.getElementById){ // DOM3 = IE5, NS6
				document.getElementById('serviceLANID').style.display = 'none';
				document.getElementById('serviceLANID2').style.display = 'none';
				document.getElementById('div_lan').style.display = 'none';
				document.getElementById('serviceWANID').style.display = '';
			}
			else {
				if (document.layers == false) { // IE4
					document.all.serviceLANID.style.display = 'none';
					document.all.serviceLANID2.style.display = 'none';
					document.all.div_lan.style.display = 'none';
					document.all.serviceWANID.style.display = '';
				}
			}
		}
	}
}

function serviceChange ()
{	
	
		if (document.acl.l_any.checked)
		{
			if (document.getElementById) {  // DOM3 = IE5, NS6				
				document.getElementById('serviceLANID2').style.display = 'none';
			}
			else {
				if (document.layers == false) { // IE4					
					document.all.serviceLANID2.style.display = 'none';
				}
			}
		}
		else
		{
			if (document.getElementById){ // DOM3 = IE5, NS6				
				document.getElementById('serviceLANID2').style.display = '';
			}
			else {
				if (document.layers == false) { // IE4					
					document.all.serviceLANID2.style.display = '';
				}
			}
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
	<p class="intro_title">ACL <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content"> <% multilang("588" "LANG_THIS_PAGE_IS_USED_TO_CONFIGURE_THE_IP_ADDRESS_FOR_ACCESS_CONTROL_LIST_IF_ACL_IS_ENABLED_ONLY_THE_IP_ADDRESS_IN_THE_ACL_TABLE_CAN_ACCESS_CPE_HERE_YOU_CAN_ADD_DELETE_THE_IP_ADDRESS"); %></p>
</div>
<form action=/boaform/admin/formACL method=POST name="acl">
	<div class="data_common data_common_notitle">
		<table>
			<input type="hidden" name="lan_ip" value=<% getInfo("lan-ip"); %>>
			<input type="hidden" name="lan_mask" value=<% getInfo("lan-subnet"); %>>
				<tr>
					<th width="30%">ACL <% multilang("591" "LANG_CAPABILITY"); %>:</th>
					<td>
						<input type="radio" value="0" name="aclcap" <% checkWrite("acl-cap0"); %>><% multilang("271" "LANG_DISABLE"); %>&nbsp;&nbsp;
						<input type="radio" value="1" name="aclcap" <% checkWrite("acl-cap1"); %>><% multilang("272" "LANG_ENABLE"); %>
					</td>
					<td><input class="inner_btn" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="apply" onClick="return on_submit(this)">&nbsp;&nbsp; </td>
				</tr> 
		</table>
		
		<table> 
			<tr>
				<th width="30%"><% multilang("272" "LANG_ENABLE"); %>:</th>
				<td width="70%"><input type="checkbox" name="enable" value="1" checked></td>
			</tr>	  
			<tr>
				<th><% multilang("75" "LANG_INTERFACE"); %>:</th>
				<td>      
					<select size="1" name="interface" onChange="intfchange(this)"> 
					<option value="0"><% multilang("6" "LANG_LAN"); %></option>
					<option value="1"><% multilang("11" "LANG_WAN"); %></option>
					</select>
				</td>
			</tr>
			<tr>
			<!--<th><% multilang("94" "LANG_IP_ADDRESS"); %>:</th>
				<td><input type="text" name="aclIP" size="15" maxlength="15"></td>
			</tr>  
			<tr>
				<th><% multilang("95" "LANG_SUBNET_MASK"); %>:</th>
				<td><input type="text" name="aclMask" size="15" maxlength="15"></td>      
			</tr>-->
			<!--<th><% multilang("541" "LANG_START"); %> <% multilang("94" "LANG_IP_ADDRESS"); %>:</th>
				<td><input type="text" name="aclstartIP" size="15" maxlength="15"></td>
			</tr>  
			<tr>
				<th><% multilang("648" "LANG_END"); %> <% multilang("94" "LANG_IP_ADDRESS"); %>:</th>
				<td><input type="text" name="aclendIP" size="15" maxlength="15"></td>      
			</tr>-->
			<% checkAclItems("show_input"); %>
		</table>
		<% showLANACLItem(); %>
		<% showWANACLItem(); %>
	</div>
	<div class="btn_ctl">
	   <input class="link_bg" type="submit" value="<% multilang("245" "LANG_ADD"); %>" name="addIP" onClick="return addClick(this)">
	</div>

<!--input type="submit" value="Update" name="updateACL" onClick="return addClick()">&nbsp;&nbsp;
</tr-->

	<div class="column clearfix column_title">
		<div class="column_title_left"></div>
			<p>ACL <% multilang("357" "LANG_TABLE"); %></p>
		<div class="column_title_right"></div>
	</div>	
	<div class="data_common data_vertical">
		<table>
			<% showACLTable(); %>
		</table>
	</div> 	
	<div class="btn_ctl clearfix">
		<input class="link_bg" type="submit" value="<% multilang("248" "LANG_DELETE_SELECTED"); %>" name="delIP" onClick="return deleteClick(this)">    
		<input type="hidden" value="/admin/acl.asp" name="submit-url">
		<input type="hidden" name="postSecurityFlag" value="">
	</div>  
	<script>
		<% checkWrite("aclNum"); %>
	</script>
</form>
</body>
</html>

