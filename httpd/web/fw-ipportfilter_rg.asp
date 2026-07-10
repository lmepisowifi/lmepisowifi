















































<%SendWebHeadStr(); %>
<title>IP/Port <% multilang("408" "LANG_FILTERING"); %></title>

<script>
function skip () { this.blur(); }

function protocolSelection()
{
	if ( document.formFilterAdd.protocol.selectedIndex == 2 )
	{
		document.formFilterAdd.sfromPort.disabled = true;
		document.formFilterAdd.stoPort.disabled = true;
		document.formFilterAdd.dfromPort.disabled = true;
		document.formFilterAdd.dtoPort.disabled = true;
	}
	else
	{
		document.formFilterAdd.sfromPort.disabled = false;
		document.formFilterAdd.stoPort.disabled = false;
		document.formFilterAdd.dfromPort.disabled = false;
		document.formFilterAdd.dtoPort.disabled = false;
	}
}

function addClick(obj)
{
	if (document.formFilterAdd.sip.value == "" && document.formFilterAdd.smask.value == ""
		&& document.formFilterAdd.dip.value == "" && document.formFilterAdd.dmask.value == ""
		&& document.formFilterAdd.sfromPort.value == "" && document.formFilterAdd.dfromPort.value == "") {		
		alert('<% multilang("2260" "LANG_FILTER_RULES_CAN_NOT_BE_EMPTY"); %>');
		document.formFilterAdd.sip.focus();
		return false;
	}

	//var i;

	if (document.formFilterAdd.sip.value!="") {
		if (!checkHostIP(document.formFilterAdd.sip, 0))
			return false;
		if ( document.formFilterAdd.smask.value != "" ) {
			if (!checkNetmask(document.formFilterAdd.smask, 0))
				return false;
		}
		
	}

	if (document.formFilterAdd.dip.value!="") {
		if (!checkHostIP(document.formFilterAdd.dip, 0))
			return false;
		if ( document.formFilterAdd.dmask.value != "" ) {
			if (!checkNetmask(document.formFilterAdd.dmask, 0))
				return false;
		}
		
	}

	if ( document.formFilterAdd.sfromPort.value!="" ) {
		if ( validateKey( document.formFilterAdd.sfromPort.value ) == 0 ) {
			alert('<% multilang("2210" "LANG_INVALID_SOURCE_PORT"); %>');
			document.formFilterAdd.sfromPort.focus();
			return false;
		}

		d1 = getDigit(document.formFilterAdd.sfromPort.value, 1);
		if (d1 > 65535 || d1 < 1) {
			alert('<% multilang("2211" "LANG_INVALID_SOURCE_PORT_NUMBER"); %>');
			document.formFilterAdd.sfromPort.focus();
			return false;
		}

		if ( document.formFilterAdd.stoPort.value!="" ) {
			if ( validateKey( document.formFilterAdd.stoPort.value ) == 0 ) {
				alert('<% multilang("2210" "LANG_INVALID_SOURCE_PORT"); %>');
				document.formFilterAdd.stoPort.focus();
				return false;
			}

			d1 = getDigit(document.formFilterAdd.stoPort.value, 1);
			if (d1 > 65535 || d1 < 1) {
				alert('<% multilang("2211" "LANG_INVALID_SOURCE_PORT_NUMBER"); %>');
				document.formFilterAdd.stoPort.focus();
				return false;
			}
		}
	}

	if ( document.formFilterAdd.dfromPort.value!="" ) {
		if ( validateKey( document.formFilterAdd.dfromPort.value ) == 0 ) {
			alert('<% multilang("2212" "LANG_INVALID_DESTINATION_PORT"); %>');
			document.formFilterAdd.dfromPort.focus();
			return false;
		}

		d1 = getDigit(document.formFilterAdd.dfromPort.value, 1);
		if (d1 > 65535 || d1 < 1) {
			alert('<% multilang("2213" "LANG_INVALID_DESTINATION_PORT_NUMBER"); %>');
			document.formFilterAdd.dfromPort.focus();
			return false;
		}

		if ( document.formFilterAdd.dtoPort.value!="" ) {
			if ( validateKey( document.formFilterAdd.dtoPort.value ) == 0 ) {
				alert('<% multilang("2212" "LANG_INVALID_DESTINATION_PORT"); %>');
				document.formFilterAdd.dtoPort.focus();
				return false;
			}

			d1 = getDigit(document.formFilterAdd.dtoPort.value, 1);
			if (d1 > 65535 || d1 < 1) {
				alert('<% multilang("2213" "LANG_INVALID_DESTINATION_PORT_NUMBER"); %>');
				document.formFilterAdd.dtoPort.focus();
				return false;
			}
		}
	}

	obj.isclick = 1;
	postTableEncrypt(document.formFilterAdd.postSecurityFlag, document.formFilterAdd);
	
	return true;
}

function disableDelButton()
{
  if (verifyBrowser() != "ns") {
	disableButton(document.formFilterDel.deleteSelFilterIpPort);
	disableButton(document.formFilterDel.deleteAllFilterIpPort);
  }
}

function on_submit(obj)
{
	obj.isclick = 1;
	postTableEncrypt(document.formFilterDefault.postSecurityFlag, document.formFilterDefault);
	return true;
}

function deleteClick(obj)
{
	if ( !confirm('<% multilang("1781" "LANG_CONFIRM_DELETE_ONE_ENTRY"); %>') ) {
		return false;
	}
	else{
		obj.isclick = 1;
		postTableEncrypt(document.formFilterDel.postSecurityFlag, document.formFilterDel);
		return true;
	}
}
        
function deleteAllClick(obj)
{
	if ( !confirm('Do you really want to delete the all entries?') ) {
		return false;
	}
	else{
		obj.isclick = 1;
		postTableEncrypt(document.formFilterDel.postSecurityFlag, document.formFilterDel);
		return true;
	}
}

</script>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title">IP/Port <% multilang("408" "LANG_FILTERING"); %></p>
	<p class="intro_content"> <% multilang("409" "LANG_PAGE_DESC_DATA_PACKET_FILTER_TABLE"); %></p>

</div>


<form action=/boaform/formFilter method=POST name="formFilterDefault">
<div class="data_common data_common_notitle">
	<table>	
		<tr>
			<th width="40%"><% multilang("424" "LANG_DEFAULT_ACTION"); %>:&nbsp;&nbsp;</th>
			<td width="30%">
				<input type="radio" name="outAct" value=0 <% checkWrite("ipf_out_act0"); %>><% multilang("411" "LANG_DENY"); %>&nbsp;&nbsp;
				<input type="radio" name="outAct" value=1 <% checkWrite("ipf_out_act1"); %>><% multilang("412" "LANG_ALLOW"); %>
			</td>		
			<td width="30%">
				<input class="inner_btn" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="setDefaultAction" onClick="return on_submit(this)">
			</td>
		</tr>
		<input type="hidden" value="/fw-ipportfilter_rg.asp" name="submit-url">
		<input type="hidden" name="postSecurityFlag" value="">
	</table>
</div>
</form>

<form action=/boaform/formFilter method=POST name="formFilterAdd">
<div class="data_common data_common_notitle">
	<table>	
		<tr>
			<th width="40%">
				<% multilang("101" "LANG_PROTOCOL"); %>: 
				<select name="protocol" onChange="protocolSelection()">
				<option select value=1>TCP</option>
				<option value=2>UDP</option>
				<option value=3>ICMP</option>
				</select>
			</th>
			<th colspan=2><% multilang("417" "LANG_RULE_ACTION"); %>:&nbsp;&nbsp;
				<input type="radio" name="filterMode" value="Deny" checked><% multilang("411" "LANG_DENY"); %>&nbsp;&nbsp;
				<input type="radio" name="filterMode" value="Allow"><% multilang("412" "LANG_ALLOW"); %>
			</th>
		</tr>
		<tr>
			<th width="40%">
				<% multilang("418" "LANG_SOURCE"); %> <% multilang("94" "LANG_IP_ADDRESS"); %>:  <input type="text" name="sip" size="10" maxlength="15"></th>
			<th width="30%"><% multilang("95" "LANG_SUBNET_MASK"); %>:  <input type="text" name="smask" size="10" maxlength="15"></th>
			<th width="30%"><% multilang("236" "LANG_PORT"); %>: 
				<input type="text" name="sfromPort" size="4" maxlength="5">-
				<input type="text" name="stoPort" size="4" maxlength="5">
			</th>
		</tr>
		<tr>
			<th width="40%"><% multilang("419" "LANG_DESTINATION"); %> <% multilang("94" "LANG_IP_ADDRESS"); %>:  <input type="text" name="dip" size="10" maxlength="15"></th>
			<th width="30%"><% multilang("95" "LANG_SUBNET_MASK"); %>:  <input type="text" name="dmask" size="10" maxlength="15">&nbsp;&nbsp;</th>
			<th width="30%"><% multilang("236" "LANG_PORT"); %>: 
				<input type="text" name="dfromPort" size="4" maxlength="5">-
				<input type="text" name="dtoPort" size="4" maxlength="5">&nbsp;&nbsp;
			</th>
		</tr>
	</table>
</div>
<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("245" "LANG_ADD"); %>" name="addFilterIpPort" onClick="return addClick(this)">
	<input type="hidden" value="/fw-ipportfilter_rg.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
</form>

<form action=/boaform/formFilter method=POST name="formFilterDel">
<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
			<p><% multilang("420" "LANG_CURRENT_FILTER_TABLE"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common data_vertical">
		<table>
			<% ipPortFilterList(); %>
		</table>
	</div>
</div>
<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("248" "LANG_DELETE_SELECTED"); %>" name="deleteSelFilterIpPort" onClick="return deleteClick(this)">&nbsp;&nbsp;
	<input class="link_bg" type="submit" value="<% multilang("249" "LANG_DELETE_ALL"); %>" name="deleteAllFilterIpPort" onClick="return deleteAllClick(this)">&nbsp;&nbsp;&nbsp;
	<input type="hidden" value="/fw-ipportfilter_rg.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
	<script>
		<% checkWrite("ipFilterNum"); %>
	</script>
</form>

</body>
</html>
