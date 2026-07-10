















































<%SendWebHeadStr(); %>
<title>IPv6 IP/Port <% multilang("408" "LANG_FILTERING"); %></title>

<script>
function skip () { this.blur(); }

function on_init()
{
	directionSelection();
}

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

function directionSelection()
{
	if ( document.formFilterAdd.dir.selectedIndex == 0 )
	{
		//outgoing
		document.formFilterAdd.sIfId6Start.disabled = false;
		document.formFilterAdd.dIfId6Start.disabled = true;
		document.formFilterAdd.dIfId6Start.value = "";
	}
	else
	{
		//incoming
		document.formFilterAdd.sIfId6Start.disabled = true;
		document.formFilterAdd.sIfId6Start.value = "";
		document.formFilterAdd.dIfId6Start.disabled = false;

	}
}

function addClick(obj)
{
	var ifid_regex = /[0-9A-F]{1,4}:[0-9A-F]{1,4}:[0-9A-F]{1,4}:[0-9A-F]{1,4}/i;  // interface Id is in this format: abcd:1:123:1234 or abcd:1111:2222:3333
	if (document.formFilterAdd.sIfId6Start.value == ""
			&& document.formFilterAdd.dIfId6Start.value == ""
			&& document.formFilterAdd.sfromPort.value == "" && document.formFilterAdd.dfromPort.value == "") {		
		alert('<% multilang("2269" "LANG_INPUT_FILTER_RULE_IS_NOT_VALID"); %>');
		document.formFilterAdd.sIfId6Start.focus();
		return false;
	}

	with ( document.forms[1] )	{
		if(sIfId6Start.value != ""){
			if (!sIfId6Start.value.match(ifid_regex) ){				
				alert('<% multilang("2270" "LANG_INVALID_SOURCE_IPV6_INTERFACE_ID_START_ADDRESS"); %>');
				document.formFilterAdd.sIfId6Start.focus();
				return false;
			}
		}
		if(dIfId6Start.value != ""){
			if (!dIfId6Start.value.match(ifid_regex) ){				
				alert('<% multilang("2265" "LANG_INVALID_DESTINATION_IPV6_START_ADDRESS"); %>');
				document.formFilterAdd.dIfId6Start.focus();
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

<body onLoad="on_init();">
<body>
<div class="intro_main ">
	<p class="intro_title">IPv6 IP/Port <% multilang("408" "LANG_FILTERING"); %></p>
	<p class="intro_content"> <% multilang("409" "LANG_PAGE_DESC_DATA_PACKET_FILTER_TABLE"); %></p>
</div>

<form action=/boaform/formFilterV6 method=POST name="formFilterDefault">
	<div class="data_common data_common_notitle">
		<table>
			<tr>
				<th><% multilang("410" "LANG_OUTGOING_DEFAULT_ACTION"); %>:&nbsp;&nbsp;</th>
				<td><input type="radio" name="outAct" value=0 <% checkWrite("v6_ipf_out_act0"); %>><% multilang("411" "LANG_DENY"); %>&nbsp;&nbsp;
					<input type="radio" name="outAct" value=1 <% checkWrite("v6_ipf_out_act1"); %>><% multilang("412" "LANG_ALLOW"); %>&nbsp;&nbsp;
				</td>
			<tr>
			<tr>
				<th><% multilang("413" "LANG_INCOMING_DEFAULT_ACTION"); %>:&nbsp;&nbsp;</th>
				<td><input type="radio" name="inAct" value=0 <% checkWrite("v6_ipf_in_act0"); %>><% multilang("411" "LANG_DENY"); %>&nbsp;&nbsp;
					<input type="radio" name="inAct" value=1 <% checkWrite("v6_ipf_in_act1"); %>><% multilang("412" "LANG_ALLOW"); %>&nbsp;&nbsp;
				</td>
			</tr>
		</table>
	</div>
	<div class="btn_ctl">
		<input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="setDefaultAction" onClick="return on_submit(this)">&nbsp;&nbsp;
		<input type="hidden" value="/fw-ipportfilter-v6_IfId.asp" name="submit-url">
		<input type="hidden" name="postSecurityFlag" value="">
	</div>
</form>

<form action=/boaform/formFilterV6 method=POST name="formFilterAdd">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%">
				<% multilang("414" "LANG_DIRECTION"); %>: 
			</th>
			<td>
				<select name="dir" onChange="directionSelection()">
					<option select value=0><% multilang("415" "LANG_OUTGOING"); %></option>
					<option value=1><% multilang("416" "LANG_INCOMING"); %></option>
				</select>&nbsp;&nbsp;
			</td>
		</tr>
		<tr>
			<th><% multilang("101" "LANG_PROTOCOL"); %>: </th>
			<td>
				<select name="protocol" onChange="protocolSelection()">
					<option select value=1>TCP</option>
					<option value=2>UDP</option>
					<option value=3>ICMPV6</option>
				</select>&nbsp;&nbsp;
			</td>
		</tr>
		<tr>
			<th><% multilang("417" "LANG_RULE_ACTION"); %>: </th>
			<td>
		   		<input type="radio" name="filterMode" value="Deny" checked>&nbsp;<% multilang("411" "LANG_DENY"); %>
		   		<input type="radio" name="filterMode" value="Allow">&nbsp;&nbsp;<% multilang("412" "LANG_ALLOW"); %>
			</td>
		</tr>
	</table>
	<table>
		<tr>
			<th width="30%"><% multilang("418" "LANG_SOURCE"); %> <% multilang("514" "LANG_INTERFACE_ID"); %>:</th> 
			<td><input type="text" size="16" name="sIfId6Start" style="width:150px"> </td>
		</tr>
		<tr>
			<th><% multilang("419" "LANG_DESTINATION"); %> <% multilang("514" "LANG_INTERFACE_ID"); %>:</th>
			<td><input type="text" size="16" name="dIfId6Start" style="width:150px"> </td>
		</tr>
		<tr>
			<th><% multilang("418" "LANG_SOURCE"); %> <% multilang("236" "LANG_PORT"); %>:</th>
			<td><input type="text" size="6" name="sfromPort" style="width:150px"> - <input type="text" size="6" name="stoPort" style="width:150px"></td>
		</tr>
		<tr>
			<th><% multilang("419" "LANG_DESTINATION"); %> <% multilang("236" "LANG_PORT"); %>:</th>
			<td><input type="text" size="6" name="dfromPort" style="width:150px"> - <input type="text" size="6" name="dtoPort" style="width:150px"></td>
		</tr>
	</table>
</div>

<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("245" "LANG_ADD"); %>" name="addFilterIpPort" onClick="return addClick(this)">
	<input type="hidden" value="/fw-ipportfilter-v6_IfId.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
</form>

<form action=/boaform/formFilterV6 method=POST name="formFilterDel">
<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
			<p><% multilang("420" "LANG_CURRENT_FILTER_TABLE"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common data_vertical">
		<table>
			<% ipPortFilterListV6(); %>
		</table>
	</div>
</div>
<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("248" "LANG_DELETE_SELECTED"); %>" name="deleteSelFilterIpPort" onClick="return deleteClick(this)">&nbsp;&nbsp;
	<input class="link_bg" type="submit" value="<% multilang("249" "LANG_DELETE_ALL"); %>" name="deleteAllFilterIpPort" onClick="return deleteAllClick(this)">&nbsp;&nbsp;&nbsp;
	<input type="hidden" value="/fw-ipportfilter-v6_IfId.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>	
<script>
	<% checkWrite("ipFilterNumV6"); %>
</script>
</form>

</body>
</html>
