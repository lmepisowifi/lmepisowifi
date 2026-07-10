<% SendWebHeadStr();%>
<title><% multilang("74" "LANG_TIME_ZONE"); %><% multilang("262" "LANG_CONFIGURATION"); %></title>
<script src="customprompt.js"></script>
<script>
var ntp_zone_index=4;

function ntp_entry(name, value) { 
	this.name = name ;
	this.value = value ;
} 

function setNtpServer(field, ntpServer){
    field.selectedIndex = 0 ;
    for(i=0 ;i < field.options.length ; i++){
    	if(field.options[i].value == ntpServer){
		field.options[i].selected = true;
		break;
	}
    }
}

function checkEmpty(field){
	if(field.value.length == 0){
		alert(field.name + " field can't be empty\n");
		field.value = field.defaultValue;
		field.focus();
		return false;
	}
	else
		return true;
}
function checkNumber(field){
    str =field.value ;
    for (var i=0; i<str.length; i++) {
    	if ( (str.charAt(i) >= '0' && str.charAt(i) <= '9'))
                        continue;
	field.value = field.defaultValue;
        alert("<% multilang("2494" "LANG_IT_SHOULD_BE_IN_NUMBER_0_9"); %>");
        return false;
    }	
	return true;
}
function checkMonth(str) {
  d = parseInt(str, 10);
  if (d < 0 || d > 12)
      	return false;
  return true;
}
function checkDay(str, month) {
  d = parseInt(str, 10);
  m = parseInt (month, 10);
  if (m == 1 || m == 3 || m == 5 || m == 7 || m == 8 || m == 10 || m == 12) {
  	if (d < 0 || d > 31)
      		return false;
  }
  else if (m == 4 || m == 6 || m == 9 || m == 11) {
  	if (d < 0 || d > 31)
      		return false;
  }
  else if (m == 2) {
  	if (d < 0 || d > 29)
      		return false;
  }
  else
  	return false;
  return true;
}
function checkHour(str) {
  d = parseInt(str, 10);
  if (d < 0 || d >= 24)
      	return false;
  return true;
}
function checkTime(str) {
  d = parseInt(str, 10);
  if (d < 0 || d >= 60)
      	return false;
  return true;
}
function saveChanges(form,obj){
	if((checkEmpty(form.year)& checkEmpty(form.month) & checkEmpty(form.hour)
	 & checkEmpty(form.day) &checkEmpty(form.minute) & checkEmpty(form.second))== false)
	 	return false;

	if((checkNumber(form.year)& checkNumber(form.month) & checkNumber(form.hour)
	 & checkNumber(form.day) &checkNumber(form.minute) & checkNumber(form.second))== false)
	 	return false;
	if(form.month.value == '0'){
		form.month.value = form.month.defaultValue;
        	alert("<% multilang("2495" "LANG_INVALID_MONTH_NUMBER_IT_SHOULD_BE_IN_NUMBER_1_9"); %>");
		return false;
	}
	if (!checkMonth(form.month.value)) {
		alert("<% multilang("2496" "LANG_INVALID_MONTH_SETTING"); %>");
		form.month.focus();
		return false;
	}
	if (!checkDay(form.day.value, form.month.value)) {
		alert("<% multilang("2497" "LANG_INVALID_DAY_SETTING"); %>");
		form.day.focus();
		return false;
	}
	if (!checkHour(form.hour.value)) {
		alert("<% multilang("2498" "LANG_INVALID_HOUR_SETTING"); %>");
		form.hour.focus();
		return false;
	}
	if (!checkTime(form.minute.value) || !checkTime(form.second.value)) {
		alert("<% multilang("2499" "LANG_INVALID_TIME_SETTING"); %>");
		return false;
	}
	if (form.ntpServerHost1.value == "" || !checkString(form.ntpServerHost1.value)) {
		alert("<% multilang("2500" "LANG_INVALID_SERVER_STRING"); %>");
		form.ntpServerHost1.value = form.ntpServerHost1.defaultValue;
		form.ntpServerHost1.focus();
		return false;
	}
	if ( form.ntpServerHost2.value != "" && !checkString(form.ntpServerHost2.value)) {
		alert("<% multilang("2500" "LANG_INVALID_SERVER_STRING"); %>");
		form.ntpServerHost2.value = form.ntpServerHost2.defaultValue;
		form.ntpServerHost2.focus();
		return false;
	}	
	obj.isclick = 1;
	showLoader('Applying Changes.');
	postTableEncrypt(document.forms[0].postSecurityFlag, document.forms[0]);
	return true;
}
function updateState(form)
{
	disableTextField(form.year);
	disableTextField(form.month);
	disableTextField(form.day);
	disableTextField(form.hour);
	disableTextField(form.minute);
	disableTextField(form.second);

	if(form.enabled.checked){
		enableTextField(form.ntpServerHost1);
		if(form.ntpServerHost2 != null)
			enableTextField(form.ntpServerHost2);
	}
	else{
		disableTextField(form.ntpServerHost1);
		if(form.ntpServerHost2 != null)
			disableTextField(form.ntpServerHost2);
	}

	
}
</script>
</head>
<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("74" "LANG_TIME_ZONE"); %> <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content">  <% multilang("592" "LANG_YOU_CAN_MAINTAIN_THE_SYSTEM_TIME_BY_SYNCHRONIZING_WITH_A_PUBLIC_TIME_SERVER_OVER_THE_INTERNET"); %></p>
</div>

<form action=/boaform/formNtp method=POST name="time">
<div class="data_common data_common_notitle">
	<table>
		
		<tr>
			<th width ="25%"> <% multilang("594" "LANG_CURRENT_TIME"); %> : </th>
			<td width ="75%">
                <% multilang("601" "LANG_YEAR"); %><input type="text" name="year" value="<% getInfo("year"); %>" size="4" maxlength="4">
                <% multilang("602" "LANG_MONTH"); %><input type="text" name="month" value="<% getInfo("month"); %>" size="2" maxlength="2">
                <% multilang("603" "LANG_DAY"); %><input type="text" name="day" value="<% getInfo("day"); %>" size="2" maxlength="2">
                <% multilang("604" "LANG_HOUR"); %><input type="text" name="hour" value="<% getInfo("hour"); %>" size="2" maxlength="2">
                <% multilang("605" "LANG_MIN"); %><input type="text" name="minute" value="<% getInfo("minute"); %>" size="2" maxlength="2">
                <% multilang("606" "LANG_SEC"); %><input type="text" name="second" value="<% getInfo("second"); %>" size="2" maxlength="2">
	        </td>
		</tr>
		<tr><th width ="25%"><% multilang("595" "LANG_TIME_ZONE_SELECT"); %> : </th>
		    <td width="75%">
	            <select name="timeZone">
		    	<% timeZoneList(); %>
	            </select>
		    </td>
		</tr>
		<tr><th><% multilang("596" "LANG_ENABLE_DAYLIGHT_SAVING_TIME"); %></th>
			<td><input type="checkbox" name="dst_enabled" value="ON">
		    </td>
		</tr>
		<tr><th><% multilang("597" "LANG_ENABLE_SNTP_CLIENT_UPDATE"); %></th>
			<td>
				<input type="checkbox" name="enabled" value="ON" ONCLICK=updateState(document.time)>
		    </td>
		</tr>
		<tr>
			<th width="25%"><% multilang("454" "LANG_WAN_INTERFACE"); %>:</th>
			<td width="75%">
				<select name="ext_if" <% checkWrite("sntp0d"); %>>
					<option value=65535><% multilang("430" "LANG_ANY"); %></option>
					<% if_wan_list("rt"); %>
				</select>
			</td>
		</tr>
		<tr>
			<th width ="25%"> SNTP <% multilang("3283" "LANG_SERVER_1"); %> : </th>
			<td width ="75%">
				<input type="text" name="ntpServerHost1" size="15" maxlength="40" value=<% getInfo("ntpServerHost1"); %>>
			</td>
		</tr>
		<tr>
			<th width ="25%"> SNTP <% multilang("3284" "LANG_SERVER_2"); %> : </th>
			<td width ="75%">
				<input type="text" name="ntpServerHost2" size="15" maxlength="40" value=<% getInfo("ntpServerHost2"); %>>
			</td>
		</tr>
	</table>
</div>
<br>
<div class="adsl clearfix">
	<input type="hidden" value="/tz.asp" name="submit-url">
	<input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="save" onClick="return saveChanges(document.time,this)">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
<script>
	<% initPage("ntp"); %>
	updateState(document.time);

	ifIdx = <% getInfo("ntp-ext-itf"); %>;
	document.time.ext_if.selectedIndex = 0;
	for( i = 1; i < document.time.ext_if.options.length; i++ )
	{
		if( ifIdx == document.time.ext_if.options[i].value )
			document.time.ext_if.selectedIndex = i;
	}
</script>
</form>
</body>

</html>
