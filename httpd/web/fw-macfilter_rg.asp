















































<%SendWebHeadStr(); %>
<title>MAC <% multilang("408" "LANG_FILTERING"); %></title>
<script>
function skip () { this.blur(); }
function addClick(obj)
{
//  if (document.formFilterAdd.srcmac.value=="" )
//	return true;
  if (document.formFilterAdd.srcmac.value==""){ //&& document.formFilterAdd.dstmac.value=="") {
	alert('<% multilang("2276" "LANG_INPUT_MAC_ADDRESS"); %>');
	return false;
  }

	if (document.formFilterAdd.srcmac.value != "") {
		if (!checkMac(document.formFilterAdd.srcmac, 0))
			return false;
	}
	
	obj.isclick = 1;
	postTableEncrypt(document.formFilterAdd.postSecurityFlag, document.formFilterAdd);
	
	return true;

}

function disableDelButton()
{
  if (verifyBrowser() != "ns") {
	disableButton(document.formFilterDel.deleteSelFilterMac);
	disableButton(document.formFilterDel.deleteAllFilterMac);
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
	<p class="intro_title"><% multilang("19" "LANG_MAC_FILTERING"); %></p>
	<p class="intro_content"> <% multilang("423" "LANG_PAGE_DESC_LAN_TO_INTERNET_DATA_PACKET_FILTER_TABLE"); %></p>
</div>

<form action=/boaform/admin/formFilter method=POST name="formFilterDefault">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%"><% multilang("151" "LANG_MODE"); %>:&nbsp;&nbsp;</th>
		   	<td width="40%">
	   			<input type="radio" name="outAct" value=0 <% checkWrite("macf_out_act0"); %>><% multilang("2792" "LANG_WHITE_LIST"); %>&nbsp;&nbsp;
	   			<input type="radio" name="outAct" value=1 <% checkWrite("macf_out_act1"); %>><% multilang("2793" "LANG_BLACK_LIST"); %>&nbsp;&nbsp;</th>
			</td>
			<td>
				<input class="inner_btn" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="setMacDft" onClick="return on_submit(this)">&nbsp;&nbsp;
			</td>
		<tr>
		<input type="hidden" value="/admin/fw-macfilter_rg.asp" name="submit-url">
		<input type="hidden" name="postSecurityFlag" value="">
	</table>
</div>
</form>

<form action=/boaform/admin/formFilter method=POST name="formFilterAdd">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%">
				<% multilang("97" "LANG_MAC_ADDRESS"); %>: 
			</th>
			<td width="40%">
				<input type="text" name="srcmac" size="15" maxlength="12" style="text-transform: uppercase"></input>
			</td>
			<td>
				<input class="inner_btn" type="submit" value="<% multilang("245" "LANG_ADD"); %>" name="addFilterMac" onClick="return addClick(this)">&nbsp;&nbsp;
			</td>
		</tr>
		<input type="hidden" value="/admin/fw-macfilter_rg.asp" name="submit-url">
		<input type="hidden" name="postSecurityFlag" value="">
	</table>
</div>	
</form>


<form action=/boaform/admin/formFilter method=POST name="formFilterDel">
<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
		<p><% multilang("420" "LANG_CURRENT_FILTER_TABLE"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common data_vertical">
		<table>
			<% macFilterList(); %>
		</table>
	</div>
</div>
<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("248" "LANG_DELETE_SELECTED"); %>" name="deleteSelFilterMac" onClick="return deleteClick(this)">&nbsp;&nbsp;
	<input class="link_bg" type="submit" value="<% multilang("249" "LANG_DELETE_ALL"); %>" name="deleteAllFilterMac" onClick="return deleteAllClick(this)">&nbsp;&nbsp;&nbsp;
	<input type="hidden" value="/admin/fw-macfilter_rg.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
<script>
	<% checkWrite("macFilterNum"); %>
</script>
</form>
</body>
</html>
