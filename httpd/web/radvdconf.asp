















































<% SendWebHeadStr();%>
<title>RADVD <% multilang("262" "LANG_CONFIGURATION"); %></title>

<SCRIPT>
function resetClick()
{
	document.radvd.reset;
}

function saveChanges()
{
	if (document.radvd.MaxRtrAdvIntervalAct.value.length !=0) {
		if ( checkDigit(document.radvd.MaxRtrAdvIntervalAct.value) == 0) {
			alert("<% multilang("2415" "LANG_INVALID_MAXRTRADVINTERVAL_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
			document.radvd.MaxRtrAdvIntervalAct.focus();
			return false;
		}
	}
	
	MaxRAI = parseInt(document.radvd.MaxRtrAdvIntervalAct.value, 10);
	if ( MaxRAI < 4 || MaxRAI > 1800 ) {
		alert("<% multilang("2416" "LANG_MAXRTRADVINTERVAL_MUST_BE_NO_LESS_THAN_4_SECONDS_AND_NO_GREATER_THAN_1800_SECONDS"); %>");
		document.radvd.MaxRtrAdvIntervalAct.focus();
		return false;
	}
		
	if (document.radvd.MinRtrAdvIntervalAct.value.length !=0) {
		if ( checkDigit(document.radvd.MinRtrAdvIntervalAct.value) == 0) {
			alert("<% multilang("2417" "LANG_INVALID_MINRTRADVINTERVAL_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
			document.radvd.MinRtrAdvIntervalAct.focus();
			return false;
		}
	}
	
	MinRAI = parseInt(document.radvd.MinRtrAdvIntervalAct.value, 10);
	MaxRAI075 = 0.75 * MaxRAI;
	if ( MinRAI < 3 || MinRAI > MaxRAI075 ) {
		alert("<% multilang("2418" "LANG_MINRTRADVINTERVAL_MUST_BE_NO_LESS_THAN_3_SECONDS_AND_NO_GREATER_THAN_0_75_MAXRTRADVINTERVAL"); %>");
		document.radvd.MinRtrAdvIntervalAct.focus();
		return false;
	}
	
	if (document.radvd.AdvCurHopLimitAct.value.length !=0) {
		if ( checkDigit(document.radvd.AdvCurHopLimitAct.value) == 0) {
			alert("<% multilang("2419" "LANG_INVALID_ADVCURHOPLIMIT_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
			document.radvd.AdvCurHopLimitAct.focus();
			return false;
		}
	} 
	
	if (document.radvd.AdvDefaultLifetimeAct.value.length !=0) {
		if ( checkDigit(document.radvd.AdvDefaultLifetimeAct.value) == 0) {
			alert("<% multilang("2420" "LANG_INVALID_ADVDEFAULTLIFETIME_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
			document.radvd.AdvDefaultLifetimeAct.focus();
			return false;
		}
	}
	
	dlt = parseInt(document.radvd.AdvDefaultLifetimeAct.value, 10);	
	if ( dlt != 0 && (dlt < MaxRAI || dlt > 9000) ) {
		alert("<% multilang("2421" "LANG_ADVDEFAULTLIFETIME_MUST_BE_EITHER_ZERO_OR_BETWEEN_MAXRTRADVINTERVAL_AND_9000_SECONDS"); %>");
		document.radvd.AdvDefaultLifetimeAct.focus();
		return false;
	}
	
	if (document.radvd.AdvReachableTimeAct.value.length !=0) {
		if ( checkDigit(document.radvd.AdvReachableTimeAct.value) == 0) {
			alert("<% multilang("2422" "LANG_INVALID_ADVREACHABLETIME_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
			document.radvd.AdvReachableTimeAct.focus();
			return false;
		}
	}
	
	if (document.radvd.AdvRetransTimerAct.value.length !=0) {
		if ( checkDigit(document.radvd.AdvRetransTimerAct.value) == 0) {
			alert("<% multilang("2423" "LANG_INVALID_ADVRETRANSTIMER_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
			document.radvd.AdvRetransTimerAct.focus();
			return false;
		}
	}
	
	if (document.radvd.AdvLinkMTUAct.value.length !=0) {
		if ( checkDigit(document.radvd.AdvLinkMTUAct.value) == 0) {
			alert("<% multilang("2424" "LANG_INVALID_ADVLINKMTU_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
			document.radvd.AdvLinkMTUAct.focus();
			return false;
		}
	}
	
	lmtu= parseInt(document.radvd.AdvLinkMTUAct.value, 10);	
	if ( lmtu != 0 && (lmtu < 1280 || lmtu > 1500) ) {
		alert("<% multilang("2425" "LANG_ADVLINKMTU_MUST_BE_EITHER_ZERO_OR_BETWEEN_1280_AND_1500"); %>");
		document.radvd.AdvLinkMTUAct.focus();
		return false;
	}	


    if(document.radvd.EnableULA[1].checked){
		if (!document.radvd.ULAPrefixRandom.checked){
			if (document.radvd.ULAPrefix.value == "")
			{
				alert("<% multilang("2426" "LANG_ULA_PREFIX_IP_ADDRESS_CANNOT_BE_EMPTY_FORMAT_IS_IPV6_ADDRESS_FOR_EXAMPLE_FD01"); %>");
				document.radvd.ULAPrefix.focus();
				return false;
			}
			if ( !isUnicastIpv6Address(document.radvd.ULAPrefix.value) ) {
				alert("<% multilang("2427" "LANG_INVALID_ULA_PREFIX_IP_FOR_EXAMPLE_FD01"); %>");
				document.radvd.prefix_ip.focus();
				return false;
			}
			if (!isULAipv6Address(document.radvd.ULAPrefix.value) ) {
				alert("<% multilang("2427" "LANG_INVALID_ULA_PREFIX_IP_FOR_EXAMPLE_FD01"); %>");
				document.radvd.ULAPrefix.focus();
				return false;
			}
		}
		
	   if (document.radvd.ULAPrefixlen.value =="") {
			alert("<% multilang("2428" "LANG_ULA_PREFIX_LENGTH_CANNOT_BE_EMPTY_FOR_EXAMPLE_64"); %>");
			document.radvd.ULAPrefixlen.focus();
			return false;
		} else {
			if ( checkDigit(document.radvd.ULAPrefixlen.value) == 0) {
				alert("<% multilang("2429" "LANG_INVALID_ULA_PREFIX_LENGTH_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
				document.radvd.ULAPrefixlen.focus();
				return false;
			}else {
				ULAprefixlen= parseInt(document.radvd.ULAPrefixlen.value, 10);
				if (ULAprefixlen <48 || ULAprefixlen>64){
					alert("<% multilang("2430" "LANG_INVALID_ULA_PREFIX_LENGTH_IT_SHOULD_BE_48_64"); %>");
					document.radvd.ULAPrefixlen.focus();
					return false;
				}
			}
		}
		
		if (document.radvd.ULAPrefixValidTime.value =="") {
			alert("<% multilang("2431" "LANG_ULA_PREFIX_VALID_TIME_CANNOT_BE_EMPTY_VALID_RANGE_IS_600_4294967295"); %>");
			document.radvd.ULAPrefixlen.focus();
			return false;
		} else if ( checkDigit(document.radvd.ULAPrefixValidTime.value) == 0) {
				alert("<% multilang("2432" "LANG_INVALID_ULAPREFIXVALIDTIME_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
				document.radvd.ULAPrefixValidTime.focus();
				return false;
		}
		
		if (document.radvd.ULAPrefixPreferedTime.value =="") {
			alert("<% multilang("2431" "LANG_ULA_PREFIX_VALID_TIME_CANNOT_BE_EMPTY_VALID_RANGE_IS_600_4294967295"); %>");
			document.radvd.ULAPrefixlen.focus();
			return false;
		} else if ( checkDigit(document.radvd.ULAPrefixPreferedTime.value) == 0) {
				alert("<% multilang("2433" "LANG_INVALID_ULAPREFIXPREFEREDTIME_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
				document.radvd.ULAPrefixPreferedTime.focus();
				return false;
		}
    }
	
	if (document.radvd.PrefixMode.value == 1) {
		if (document.radvd.prefix_ip.value =="") {
			alert("<% multilang("2434" "LANG_PREFIX_IP_ADDRESS_CANNOT_BE_EMPTY_FORMAT_IS_IPV6_ADDRESS_FOR_EXAMPLE_3FFE_501_FFFF_100"); %>");
			document.radvd.prefix_ip.value = document.radvd.prefix_ip.defaultValue;
			document.radvd.prefix_ip.focus();
			return false;
		} else {
			if ( validateKeyV6IP(document.radvd.prefix_ip.value) == 0) {
				alert("<% multilang("2435" "LANG_INVALID_PREFIX_IP"); %>");
				document.radvd.prefix_ip.focus();
				return false;
			}
		}
		
		if (document.radvd.prefix_len.value =="") {
			alert("<% multilang("2436" "LANG_PREFIX_LENGTH_CANNOT_BE_EMPTY"); %>");
			document.radvd.prefix_len.value = document.radvd.prefix_len.defaultValue;
			document.radvd.prefix_len.focus();
			return false;
		} else {
			if ( checkDigit(document.radvd.prefix_len.value) == 0) {
				alert("<% multilang("2437" "LANG_INVALID_PREFIX_LENGTH_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
				document.radvd.prefix_len.focus();
				return false;
			}
		}
		
		if (document.radvd.AdvValidLifetimeAct.value.length !=0) {
			if ( checkDigit(document.radvd.AdvValidLifetimeAct.value) == 0) {
				alert("<% multilang("2438" "LANG_INVALID_ADVVALIDLIFETIME_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
				document.radvd.AdvValidLifetimeAct.focus();
				return false;
			}
		}
		
		if (document.radvd.AdvPreferredLifetimeAct.value.length !=0) {
			if ( checkDigit(document.radvd.AdvPreferredLifetimeAct.value) == 0) {
				alert("<% multilang("2439" "LANG_INVALID_ADVPREFERREDLIFETIME_IT_SHOULD_BE_THE_DECIMAL_NUMBER_0_9"); %>");
				document.radvd.AdvPreferredLifetimeAct.focus();
				return false;
			}
		}		
		
		vlt = parseInt(document.radvd.AdvValidLifetimeAct.value, 10);
		plt = parseInt(document.radvd.AdvPreferredLifetimeAct.value, 10);
		if ( vlt <= plt ) {			
			alert("<% multilang("2440" "LANG_ADVVALIDLIFETIME_MUST_BE_GREATER_THAN_ADVPREFERREDLIFETIME"); %>");
			document.radvd.AdvValidLifetimeAct.focus();
			return false;
		}
	
	}
	

		if (document.radvd.RDNSS1.value !="") {
			if ( validateKeyV6IP(document.radvd.RDNSS1.value) == 0) {
				alert("<% multilang("2441" "LANG_INVALID_RDNSS1_IP"); %>");
				document.radvd.RDNSS1.focus();
				return false;
			}
		}

		if (document.radvd.RDNSS2.value !="") {
			if ( validateKeyV6IP(document.radvd.RDNSS2.value) == 0) {
				alert("<% multilang("2442" "LANG_INVALID_RDNSS2_IP"); %>");
				document.radvd.RDNSS2.focus();
				return false;
			}
		}

	postTableEncrypt(document.forms[0].postSecurityFlag, document.radvd);
	return true;
}

function radvd_enable_on_off()
{
	if (document.radvd.radvd_enable[0].checked == true) //radvd off
	{
		document.getElementById('radvdID').style.display = 'none';
		document.getElementById('prefixModeDiv').style.display = 'none';
		document.getElementById('ULAenableID').style.display = 'none';
		document.getElementById('ULAdiv').style.display = 'none';
	}
	else if (document.radvd.radvd_enable[1].checked == true) //radvd on
	{
		document.getElementById('prefixModeDiv').style.display = 'block';
		ramodechange();

		document.getElementById('ULAenableID').style.display = 'block';
		document.getElementById('ULAdiv').style.display = 'block';
		ULASelection();
		ULAPrefixRandomChange();
	}
}

function ramodechange()
{
	if (document.radvd.PrefixMode.value == 0) //radvd auto
	{
		document.getElementById('radvdID').style.display = 'none';
		document.getElementById('RADVDModeDiv').style.display = 'block';
	}
	else if (document.radvd.PrefixMode.value == 1) //radvd manual
	{
		document.getElementById('radvdID').style.display = 'block';
		document.getElementById('RADVDModeDiv').style.display = 'none';
	}
}

function ULASelection()
{
    if(document.radvd.EnableULA[0].checked)
    {
		document.all.ULAdiv.style.display = 'none';
    }
    else
    {
		document.all.ULAdiv.style.display = 'block';
    }
}

function ULAPrefixRandomChange()
{
	if (document.radvd.ULAPrefixRandom.checked)
	{
		document.all.ULAPrefix.value = "";
		document.all.ULAPrefix.disabled = true;
	}
	else
	{
		document.all.ULAPrefix.value = "<% getInfo("V6ULAPrefix"); %>";
		document.all.ULAPrefix.disabled = false;
	}
}

function on_init()
{
	radvd_enable_on_off();
}

</SCRIPT>
</head>

<body onLoad="on_init();">
<div class="intro_main ">
	<p class="intro_title">RADVD <% multilang("262" "LANG_CONFIGURATION"); %></p>
	<p class="intro_content" <% multilang("481" "LANG_THIS_PAGE_IS_USED_TO_SETUP_THE_RADVD_S_CONFIGURATION_OF_YOUR_DEVICE"); %></p>
</div>

<form action=/boaform/formRadvdSetup method=POST name="radvd">
<div ID="raenableID" class="data_common data_common_notitle">
	<table>
		<tr>
	   <th><% multilang("1278" "LANG_RADVD"); %><% multilang("200" "LANG_ENABLED"); %>:</th>
       <td width="70%">
         <input type="radio" name="radvd_enable" value=0 <% checkWrite("radvd_enable0"); %> onClick="radvd_enable_on_off()"><% multilang("509" "LANG_OFF"); %>&nbsp;&nbsp;
         <input type="radio" name="radvd_enable" value=1 <% checkWrite("radvd_enable1"); %> onClick="radvd_enable_on_off()"><% multilang("508" "LANG_ON"); %>&nbsp;&nbsp;
      </td>
    </tr>
  <tr>
			<th width="30%"><% multilang("482" "LANG_MAXRTRADVINTERVAL"); %>:</th>
			<td width="70%"><input type="text" name="MaxRtrAdvIntervalAct" size="15" maxlength="15" value=<% getInfo("V6MaxRtrAdvInterval"); %>></td>
		</tr>
		<tr>
			<th width="30%"><% multilang("483" "LANG_MINRTRADVINTERVAL"); %>:</th>
			<td width="70%"><input type="text" name="MinRtrAdvIntervalAct" size="15" maxlength="15" value=<% getInfo("V6MinRtrAdvInterval"); %>></td>
		</tr>
		<tr>
			<th><% multilang("490" "LANG_ADVMANAGEDFLAG"); %>:&nbsp;&nbsp;</th>  
			<td>
				<input type="radio" name="AdvManagedFlagAct" value=0 <% checkWrite("radvd_ManagedFlag0"); %>><% multilang("509" "LANG_OFF"); %>&nbsp;&nbsp;
				<input type="radio" name="AdvManagedFlagAct" value=1 <% checkWrite("radvd_ManagedFlag1"); %>><% multilang("508" "LANG_ON"); %>&nbsp;&nbsp;
			</td>
		</tr>
		<tr>
			<th><% multilang("491" "LANG_ADVOTHERCONFIGFLAG"); %>:&nbsp;&nbsp;</th>  
			<td>
				<input type="radio" name="AdvOtherConfigFlagAct" value=0 <% checkWrite("radvd_OtherConfigFlag0"); %>><% multilang("509" "LANG_OFF"); %>&nbsp;&nbsp;
				<input type="radio" name="AdvOtherConfigFlagAct" value=1 <% checkWrite("radvd_OtherConfigFlag1"); %>><% multilang("508" "LANG_ON"); %>&nbsp;&nbsp;
			</td>
		</tr>
	</table>
</div>
<div style="display:none" class="data_common data_common_notitle">
		<table>
			<tr>
				<th width="30%"><% multilang("484" "LANG_ADVCURHOPLIMIT"); %>:</th>
				<td width="70%"><input type="text" name="AdvCurHopLimitAct" size="15" maxlength="15" value=<% getInfo("V6AdvCurHopLimit"); %>></td>
			</tr>
			<tr>
				<th width="30%"><% multilang("485" "LANG_ADVDEFAULTLIFETIME"); %>:</th>
				<td width="70%"><input type="text" name="AdvDefaultLifetimeAct" size="15" maxlength="15" value=<% getInfo("V6AdvDefaultLifetime"); %>></td>
			</tr>
			<tr>
				<th width="30%"><% multilang("486" "LANG_ADVREACHABLETIME"); %>:</th>
				<td width="70%"><input type="text" name="AdvReachableTimeAct" size="15" maxlength="15" value=<% getInfo("V6AdvReachableTime"); %>></td>
			</tr>
			<tr>
				<th width="30%"><% multilang("487" "LANG_ADVRETRANSTIMER"); %>:</th>
				<td width="70%"><input type="text" name="AdvRetransTimerAct" size="15" maxlength="15" value=<% getInfo("V6AdvRetransTimer"); %>></td>
			</tr>
			<tr>
				<th width="30%"><% multilang("488" "LANG_ADVLINKMTU"); %>:</th>
				<td width="70%"><input type="text" name="AdvLinkMTUAct" size="15" maxlength="15" value=<% getInfo("V6AdvLinkMTU"); %>></td>
			</tr>
			<tr>
				<th><% multilang("489" "LANG_ADVSENDADVERT"); %>: &nbsp;&nbsp;</th>  
				<td>
					<input type="radio" name="AdvSendAdvertAct" value=0 <% checkWrite("radvd_SendAdvert0"); %>><% multilang("509" "LANG_OFF"); %>&nbsp;&nbsp;
					<input type="radio" name="AdvSendAdvertAct" value=1 <% checkWrite("radvd_SendAdvert1"); %>><% multilang("508" "LANG_ON"); %>&nbsp;&nbsp;
				</td>
			</tr>
	</table>
</div>

<div ID="prefixModeDiv" class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%"><% multilang("492" "LANG_PREFIX_MODE"); %>:</th>
			<td>
				<select size="1" name="PrefixMode" id="prefixmode" onChange="ramodechange()">
					<OPTION VALUE="0" > <% multilang("191" "LANG_AUTO"); %></OPTION>
					<OPTION VALUE="1" > <% multilang("493" "LANG_MANUAL"); %></OPTION>
				</select>
			</td>
		</tr>
	</table>
</div>
<div ID="RADVDModeDiv" class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%"><% multilang("3302" "LANG_RDNSS_MODE"); %>:</th>
			<td width="70%">
				<select size="1" name="RDNSSMode" id="rdnssmode">
					<OPTION VALUE="0" > <% multilang("3303" "LANG_HGWPROXY"); %></OPTION>
					<OPTION VALUE="1" > <% multilang("3304" "LANG_WANCONN"); %></OPTION>
				</select>
			</td>
		</tr>
	</table>
</div>
<div ID="radvdID" style="display:none" class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%"><% multilang("112" "LANG_PREFIX"); %>:</th>
			<td width="70%"><input type=text name=prefix_ip size=24 maxlength=24 value=<% getInfo("V6prefix_ip"); %>></td>
		</tr>
		<tr>
			<th><% multilang("495" "LANG_PREFIX_LENGTH"); %>:</th>
			<td><input type=text name=prefix_len size=15 maxlength=15 value=<% getInfo("V6prefix_len"); %>></td>
		</tr>         
		<tr>
			<th><% multilang("496" "LANG_ADVVALIDLIFETIME"); %>:</th>
			<td><input type=text name=AdvValidLifetimeAct size=15 maxlength=15 value=<% getInfo("V6ValidLifetime"); %>></td>
		</tr>
		<tr>
			<th><% multilang("497" "LANG_ADVPREFERREDLIFETIME"); %>:</th>
			<td><input type=text name=AdvPreferredLifetimeAct size=15 maxlength=15 value=<% getInfo("V6PreferredLifetime"); %>></td>
		</tr>
		<tr id="radvd_rdnss1">
			<th><% multilang("506" "LANG_RDNSS_1"); %>:</th>
			<td><input type="text" name="RDNSS1" size="48" maxlength="48" value=<% getInfo("V6RDNSS1"); %>></td>
		</tr>
		<tr id="radvd_rdnss2">
			<th><% multilang("507" "LANG_RDNSS_2"); %>:</th>
			<td><input type="text" name="RDNSS2" size="48" maxlength="48" value=<% getInfo("V6RDNSS2"); %>></td>
		</tr>
		<tr id="radvd_A_flag" style="display:none">
			<th><% multilang("498" "LANG_ADVONLINK"); %>:</th>  
			<td>
				<input type="radio" name="AdvOnLinkAct" value=0 <% checkWrite("radvd_OnLink0"); %>>off&nbsp;&nbsp;
				<input type="radio" name="AdvOnLinkAct" value=1 <% checkWrite("radvd_OnLink1"); %>>on
			</td>
		</tr>
		<tr id="radvd_AdvAutonomous" style="display:none">
			<th><% multilang("499" "LANG_ADVAUTONOMOUS"); %>:</th>  
			<td>
				<input type="radio" name="AdvAutonomousAct" value=0 <% checkWrite("radvd_Autonomous0"); %>>off&nbsp;&nbsp;
				<input type="radio" name="AdvAutonomousAct" value=1 <% checkWrite("radvd_Autonomous1"); %>>on&nbsp;&nbsp;
			</td>
		</tr>
	</table>
</div>

<div id="ULAenableID" style="display:none" class="data_common data_common_notitle">
		<table>
			<tr>
				<th width="30%"><% multilang("500" "LANG_ENABLE_ULA"); %>:</th>  
				<td>
					<input type="radio" name="EnableULA" value=0 <% checkWrite("radvd_EnableULAFlag0"); %> onClick="ULASelection();"><% multilang("509" "LANG_OFF"); %>
					<input type="radio" name="EnableULA" value=1 <% checkWrite("radvd_EnableULAFlag1"); %> onClick="ULASelection();"><% multilang("508" "LANG_ON"); %>
				</td>
			</tr>
		</table>
</div>
<div ID="ULAdiv"  style="display:none" class="data_common data_common_notitle">
		<table>
				<tr>
					<th width="30%"><% multilang("502" "LANG_ULA_PREFIX_RANDOM"); %>:</th>
					<td width="70%"><input type="checkbox" value=ON name="ULAPrefixRandom" onClick="ULAPrefixRandomChange()"> </td>
				</tr>
				<tr>
					<th width="30%"><% multilang("501" "LANG_ULA_PREFIX"); %>:</th>
					<td width="70%"><input type="text" name="ULAPrefix" size="48" maxlength="48" value=<% getInfo("V6ULAPrefix"); %>></td>
				</tr>
				<tr>
					<th width="30%"><% multilang("503" "LANG_ULA_PREFIX_LEN"); %>:</th>
					<td width="70%"><input type="text" name="ULAPrefixlen" size="10" maxlength="10" value=<% getInfo("V6ULAPrefixlen"); %>></td>
				</tr>
				<tr>
					<th width="30%"><% multilang("504" "LANG_ULA_PREFIX_VALID_TIME"); %>:</th>
					<td width="70%"><input type="text" name="ULAPrefixValidTime" size="10" maxlength="10" value=<% getInfo("V6ULAPrefixValidLifetime"); %>></td>
				</tr>
				<tr>
					<th width="30%"><% multilang("505" "LANG_ULA_PREFIX_PREFERED_TIME"); %>:</th>
					<td width="70%"><input type="text" name="ULAPrefixPreferedTime" size="10" maxlength="10" value=<% getInfo("V6ULAPrefixPreferredLifetime"); %>></td>
				</tr>
		</table>
</div>
<div class="btn_ctl">
	<input class="link_bg" type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" onClick="return saveChanges()">&nbsp;&nbsp;
	<!--input type="reset" value="Undo" name="reset" onClick="resetClick()"-->
	<input type="hidden" value="/radvdconf.asp" name="submit-url">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
<script>
	<% initPage("radvd_conf"); %>		
</script>
</form>
</body>
</html>
