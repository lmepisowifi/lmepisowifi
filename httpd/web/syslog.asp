<%SendWebHeadStr(); %>
<title><% multilang("70" "LANG_SYSTEM_LOG"); %></title>
<script src="customprompt.js"></script>
<script language="javascript">
var addr = '<% getInfo("syslog-server-ip"); %>';
var port = '<% getInfo("syslog-server-port"); %>';
function getLogPort() {
	var portNum = parseInt(port);
	if (isNaN(portNum) || portNum == 0)
		portNum = 514; // default system log server port is 514

	return portNum;
}

function hideInfo(hide) {
	var status = 'visible';

	if (hide == 1) {
		status = 'hidden';
		document.forms[0].logAddr.value = '';
		document.forms[0].logPort.value = '';
		changeBlockState('srvInfo', true);
	} else {
		changeBlockState('srvInfo', false);
		document.forms[0].logAddr.value = addr;
		document.forms[0].logPort.value = getLogPort();
	}
}

function hidesysInfo(hide) {
	var status = false;

	if (hide == 1) {
		status = true;
	}
	changeBlockState('sysgroup', status);
}

function changelogstatus() {
	with (document.forms[0]) {
		if (logcap[1].checked) {
			hidesysInfo(0);
			if (logMode.selectedIndex == 0) {
				hideInfo(1);
			} else {
				hideInfo(0);
			}
		} else {
			hidesysInfo(1);
			hideInfo(1);
		}
	}
}

function cbClick(obj) {
	var idx = obj.selectedIndex;
	var val = obj.options[idx].value;
	
	
	if (val == 1)
		hideInfo(1);
	else
		hideInfo(0);
}

function check_enable()
{
	if (document.formSysLog.logcap[0].checked) {
		//disableTextField(document.formSysLog.msg);
		disableButton(document.formSysLog.refresh);		
	}
	else {
		//enableTextField(document.formSysLog.msg);
		enableButton(document.formSysLog.refresh);
	}
}               



function saveClick(obj)
{
	<% RemoteSyslog("check-ip"); %>
//	if (document.forms[0].logAddr.disabled == false && !checkIP(document.formSysLog.logAddr))
//		return false;
//	alert("Please commit and reboot this system for take effect the System log!");
    if (document.forms[0].maxloglen.value > 51200)
    {
        alert("<% multilang("3313" "LANG_MAXLOGLEN_NOTE"); %>");
        return false;
    }
    
	obj.isclick = 1;
	showLoader('Applying Changes.');
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}

function on_submit(obj)
{
	obj.isclick = 1;
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}

</script>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("70" "LANG_SYSTEM_LOG"); %></p>
</div>

<form action=/boaform/admin/formSysLog method=POST name=formSysLog>
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width=30%><% multilang("70" "LANG_SYSTEM_LOG"); %>:&nbsp;</th>
			<td>
				<input type="radio" value="0" name="logcap" onClick='changelogstatus()' <% checkWrite("log-cap0"); %>><% multilang("271" "LANG_DISABLE"); %>&nbsp;&nbsp;
				<input type="radio" value="1" name="logcap" onClick='changelogstatus()' <% checkWrite("log-cap1"); %>><% multilang("272" "LANG_ENABLE"); %>
			</td>
		</tr>    
		<% ShowPPPSyslog("syslogppp"); %>		
		<TBODY id='sysgroup'>
			<tr>
				<th><% multilang("881" "LANG_LOG_LEVEL"); %>:&nbsp;</th>
				<td><select name='levelLog' size="1">
					<% checkWrite("syslog-log"); %>
				</select></td>
			</tr>
			<tr>
				<th><% multilang("882" "LANG_DISPLAY_LEVEL"); %>:&nbsp;</th>
				<td ><select name='levelDisplay' size="1">
					<% checkWrite("syslog-display"); %>
				</select></td>
			</tr>
            <tr>
                <th><% multilang("3312" "LANG_MAXLOGLEN"); %>:&nbsp;</th>
                <td><input type="text" name="maxloglen" size="5" maxlength="5" value="<% getInfo("maxmsglen"); %>"></td>
            </tr>
			<% RemoteSyslog("syslog-mode"); %>
			<tbody id='srvInfo'>
				<% RemoteSyslog("server-info"); %>
			</tbody>
		</TBODY>
	</table>
</div>

<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="apply" onClick="return saveClick(this)">
</div>

<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width=30%><% multilang("886" "LANG_SAVE_LOG_TO_FILE"); %>:</th>
			<td><input class="inner_btn" type="submit" value="<% multilang("887" "LANG_SAVE"); %>..." name="save_log" onClick="return on_submit(this)"></td>
		</tr>
		<tr>
			<th><% multilang("888" "LANG_CLEAR_LOG"); %>:</th>
			<td><input class="inner_btn" type="submit" value="<% multilang("246" "LANG_RESET"); %>" name="clear_log" onClick="return on_submit(this)"></td>
		</tr>
	</table>
</div>


<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
			<p><% multilang("70" "LANG_SYSTEM_LOG"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common">
		<table>
			<% sysLogList(); %>
		</table>
	</div>
</div>

<div class="btn_ctl">
	<input class="link_bg" type="button" value="<% multilang("463" "LANG_REFRESH"); %>" name="refresh" onClick="javascript: window.location.reload()">
	<input type="hidden" value="/admin/syslog.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
<script>
	check_enable();
	//scrollElementToEnd(this.formSysLog.msg);
</script>
</form>
<script>
	<% initPage("syslog"); %>
	<% initPage("pppSyslog"); %>
</script>
</blockquote>
</body>
</html>


