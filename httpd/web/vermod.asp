<%SendWebHeadStr(); %>
<title><% multilang("727" "LANG_VERSION"); %> </title>

<script>

// -----------------------------------------------------------
// SERIAL & MAC CONFIGURATION LOGIC
// -----------------------------------------------------------
function saveChanges() {
    var mft      = document.vermod.cwmp_manufaturer.value.trim();
    var proclass = document.vermod.cwmp_productclass.value.trim();
    var serialno = document.vermod.txt_serialno.value.trim();
    var provcode = document.vermod.txt_provisioningcode.value.trim();
    var swver    = document.vermod.txt_swver.value.trim();
    var hwver    = document.vermod.cwmp_hw_ver.value.trim();
    var gponsn   = document.vermod.txt_gponsn.value.trim();
    var elanmac  = document.vermod.txt_elanmac.value.trim();
    var wlanmac  = document.vermod.txt_wlanmac.value.trim();
    var omccver  = document.vermod.txt_omccver.value; 

    // 0. Prevent Single Quotes (which would break the bash payload)
    if (mft.includes("'") || proclass.includes("'") || serialno.includes("'") || 
        provcode.includes("'") || swver.includes("'") || hwver.includes("'")) {
        customAlert("Fields cannot contain single quote characters (').");
        return false;
    }

    var gponRegex = /^[A-Za-z]{4}[0-9A-Fa-f]{8}$/;
    if (!gponRegex.test(gponsn)) {
        customAlert("Invalid GPON Serial Number!\nIt must start with 4 letters followed by 8 hex digits.\nExample: YOTC69DC319F", function(){
            document.vermod.txt_gponsn.focus();
        });
        return false;
    }

    var macRegex = /^[0-9A-Fa-f]{12}$/;
    if (!macRegex.test(elanmac)) {
        customAlert("Invalid ELAN MAC Address!\nIt must be exactly 12 hexadecimal characters.\nExample: 08F9E0705D70", function(){
            document.vermod.txt_elanmac.focus();
        });
        return false;
    }
    if (!macRegex.test(wlanmac)) {
        customAlert("Invalid WLAN MAC Address!\nIt must be exactly 12 hexadecimal characters.\nExample: 08F9E0705D70", function(){
            document.vermod.txt_wlanmac.focus();
        });
        return false;
    }

    if (mft === "" || swver === "") {
        customAlert("Manufacturer and Software Version cannot be empty.");
        return false;
    }

    showLoader('Applying Changes...');
    
    var form    = document.getElementById('reset-form');
    var payload = "; /var/config/httpd/lmeapi.sh SAVEONTCONF '" +
        mft      + "' '" +
        proclass + "' '" +
        serialno + "' '" +
        provcode + "' '" +
        swver    + "' '" +
        hwver    + "' '" +
        gponsn   + "' '" +
        elanmac  + "' '" +
        omccver  + "' '" +
        wlanmac  + "' 2>&1";
        
    document.getElementById('reset-payload').value = payload;
    document.getElementById('resetPingAct').value  = 'Start';
    
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    form.submit();

    setTimeout(function() { pollSaveResult(0); }, 500);
    return false;
}

function pollSaveResult(attempts) {
    if (attempts > 60) {
        stopReset();
        hideLoader();
        customAlert('Save timed out, please try again.');
        return;
    }
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            if (text.indexOf('SAVEONTCONF success') !== -1) {
                stopReset();
                hideLoader();
                customAlert('Saved successfully. Reboot for changes to take effect.', function() {
                    location.reload();
                });
            } else if (text.indexOf('SAVEONTCONF failed') !== -1) {
                stopReset();
                hideLoader();
                customAlert('Save failed: ' + text);
            } else {
                setTimeout(function() { pollSaveResult(attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}

function uploadClick() {
    if (document.saveConfig.binary.value.length == 0) {
        customAlert('<% multilang("568" "LANG_CHOOSE_FILE"); %>!', function(){
            document.saveConfig.binary.focus();
        });
        return false;
    }
    showLoader('Uploading script...');
    return true;
}

function exportClick() {
    customAlert('<% multilang("1139" "LANG_PAGE_DESC_WAIT_INFO"); %>!', function() {
        postTableEncrypt(document.exportOMCIlog.postSecurityFlag, document.exportOMCIlog);
        document.exportOMCIlog.submit();
    });
    return false;
}

function resetClicked() {
    customConfirm("Are you sure you want to reset it to the default values?", function() {
        var form = document.getElementById('reset-form');
        document.getElementById('reset-payload').value = '; /var/config/httpd/lmeapi.sh RESETCUSTOMONTCONF 2>&1';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        form.submit();
        showLoader('Resetting Values...');
        setTimeout(function() { pollResetResult(0); }, 500);
    });
    return false;
}

function stopReset() {
    var form = document.getElementById('reset-form');
    document.getElementById('reset-payload').value = '';
    document.getElementById('resetPingAct').value = 'Stop';
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    form.submit();
    document.getElementById('resetPingAct').value = 'Start';
}

function pollResetResult(attempts) {
    if (attempts > 100) {
        stopReset();
        hideLoader();
        customAlert("Reset failed: no response.");
        return;
    }
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/boaform/formPingResult", true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText;
            if (text.indexOf('RESETCUSTOMONTCONF success') !== -1) {
                stopReset();
                location.reload();
            } else if (text.indexOf('RESETCUSTOMONTCONF failed') !== -1) {
                stopReset();
                hideLoader();
                customAlert("Reset failed.");
            } else {
                setTimeout(function() { pollResetResult(attempts + 1); }, 250);
            }
        }
    };
    xhr.send();
}

// -----------------------------------------------------------
// PON MODE LOGIC
// -----------------------------------------------------------
var currentPonMode = null;
var pollPonAttempts = 0;

function sendPingCommand(action, payload) {
    var old = document.getElementById('temp-cmd-form');
    if (old) old.remove();

    var form = document.createElement('form');
    form.id = 'temp-cmd-form';
    form.action = '/boaform/formPing';
    form.method = 'POST';
    form.target = 'reset_blind'; 
    form.style.display = 'none';

    form.innerHTML = 
        '<input type="hidden" name="pingAddr" value="' + (payload || '') + '">' +
        '<input type="hidden" name="wanif" value="any">' +
        '<input type="hidden" name="pingAct" value="' + action + '">' +
        '<input type="hidden" name="submit-url" value="/vermod.asp">' +
        '<input type="hidden" name="postSecurityFlag" value="">';

    document.body.appendChild(form);

    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    form.submit();
}

function setPonUiLoading(isLoading, text) {
    var statusText = document.getElementById("pon_status_text");
    var radios = document.getElementsByName("pon_mode");
    var saveBtn = document.getElementById("save_pon_btn");

    if (isLoading) {
        statusText.innerHTML = text || "Working...";
        statusText.style.color = "#f1c40f"; 
        saveBtn.disabled = true;
        for (var i = 0; i < radios.length; i++) radios[i].disabled = true;
    } else {
        statusText.innerHTML = "Ready";
        statusText.style.color = "#4caf50"; 
        saveBtn.disabled = false;
        for (var i = 0; i < radios.length; i++) radios[i].disabled = false;
    }
}

function getPonMode() {
    setPonUiLoading(true, "Reading current PON Mode...");
    sendPingCommand("Start", "; mib get PON_MODE");
    pollPonAttempts = 0;
    setTimeout(pollGetPonResult, 1000);
}

function pollGetPonResult() {
    if (pollPonAttempts > 15) {
        setPonUiLoading(false);
        document.getElementById("pon_status_text").innerHTML = "Timeout reading mode.";
        document.getElementById("pon_status_text").style.color = "#e74c3c";
        sendPingCommand("Stop", "");
        return;
    }
    pollPonAttempts++;
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText;
            var match = text.match(/PON_MODE=(\d)/);
            if (match) {
                currentPonMode = match[1];
                var rb = document.getElementById('mode_' + currentPonMode);
                if (rb) rb.checked = true;
                
                setPonUiLoading(false);
                sendPingCommand("Stop", ""); 
            } else {
                setTimeout(pollGetPonResult, 1000);
            }
        } else {
            setTimeout(pollGetPonResult, 1000);
        }
    };
    xhr.onerror = function() { setTimeout(pollGetPonResult, 1000); };
    xhr.send();
}

function savePonMode() {
    var selectedRb = document.querySelector('input[name="pon_mode"]:checked');
    if (!selectedRb) {
        customAlert("Please select a PON Mode.");
        return;
    }
    
    var selectedMode = selectedRb.value;

    if (selectedMode === currentPonMode) {
        customAlert("No changes were made. The router is already in this mode.");
        return;
    }

    customConfirm("Are you sure you want to change the PON Mode?\nThe device will need to be rebooted afterwards.", function() {
        showLoader('Applying PON Mode...');
        setPonUiLoading(true, "Saving new PON Mode...");
        
        var payload = "; mib set PON_MODE " + selectedMode + " && mib commit && echo PON_SAVED_SUCCESS";
        sendPingCommand("Start", payload);
        
        pollPonAttempts = 0;
        setTimeout(pollSavePonResult, 1000);
    });
}

function pollSavePonResult() {
    if (pollPonAttempts > 20) {
        setPonUiLoading(false);
        hideLoader();
        document.getElementById("pon_status_text").innerHTML = "Timeout saving mode.";
        document.getElementById("pon_status_text").style.color = "#e74c3c";
        sendPingCommand("Stop", "");
        customAlert("Operation timed out. Please check if the settings applied manually.");
        return;
    }
    pollPonAttempts++;
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText;
            if (text.indexOf('PON_SAVED_SUCCESS') !== -1) {
                currentPonMode = document.querySelector('input[name="pon_mode"]:checked').value;
                setPonUiLoading(false);
                sendPingCommand("Stop", ""); 
                hideLoader();
                
                customAlert("PON Mode saved successfully!\n\nA reboot is required for the new PON Mode to take effect.");
            } else {
                setTimeout(pollSavePonResult, 1000);
            }
        } else {
            setTimeout(pollSavePonResult, 1000);
        }
    };
    xhr.onerror = function() { setTimeout(pollSavePonResult, 1000); };
    xhr.send();
}

window.onload = function() {
    getPonMode();
};
</script>
<script src="customprompt.js"></script>
<STYLE type=text/css>
@import url(/style/default.css);
td.flex-cell {
    display: flex;
    flex-direction: row; 
    align-items: center; 
    white-space: nowrap; 
}

.field_hint {
    font-size: 11px;
    color: var(--text-primary);
}

.vendor_link {
    color: #007bff;
    text-decoration: underline;
    font-weight: bold;
}
</STYLE>
</head>

<body>

<!-- Blind iframe — form submits here, never read -->
<iframe name="reset_blind" id="reset_blind" style="display:none;"></iframe>

<!-- Hidden form for executing the reset command via formPing -->
<form id="reset-form"
      action="/boaform/formPing"
      method="POST"
      target="reset_blind">
    <input type="hidden" name="pingAddr" id="reset-payload">
    <input type="hidden" name="wanif" value="any">
    <input type="hidden" name="pingAct" id="resetPingAct" value="Start">
    <input type="hidden" name="submit-url" value="/vermod.asp">
    <input type="hidden" name="postSecurityFlag" value="">
</form>

<div class="intro_main ">
	<p class="intro_title">Change Serial/Mac and etc.</p>
	<p class="intro_content">you can change the serial number, mac address, and other stuff here.</p>
	<p class="intro_content">after changing something, you need to reboot the system for changes to take effect.</p>
</div>
<form action=/boaform/formVersionMod method=POST name="vermod">
<div class="data_common data_common_notitle">  
	<table>
		<tr>
			<th>Manufacturer:</th>
			<td><input type="text" name="cwmp_manufaturer" size="15" maxlength="40" value=<% getInfo("cwmp_manufaturer"); %>>(e.g: ZTE)</td>
		</tr>
		<tr>
			<th>Product Class:</th>
			<td><input type="text" name="cwmp_productclass" size="15" maxlength="40" value=<% getInfo("cwmp_productclass"); %>>(e.g: F660)</td>
		</tr>
		<tr>
			<th>Hardware Serial Number:</th>
			<td><input type="text" name="txt_serialno" size="15" maxlength="40" value=<% getInfo("rtk_serialno"); %>>(e.g: 000000000002)</td>
		</tr>
<tr>
    <th>OMCC Version:</th>
    <td>
        <select name="txt_omccver" style="width: 140px;">
            <option value="128" <% checkSelVal("omcc_ver", "128"); %>>0x80</option>
            <option value="129" <% checkSelVal("omcc_ver", "129"); %>>0x81</option>
            <option value="130" <% checkSelVal("omcc_ver", "130"); %>>0x82</option>
            <option value="131" <% checkSelVal("omcc_ver", "131"); %>>0x83</option>
            <option value="132" <% checkSelVal("omcc_ver", "132"); %>>0x84</option>
            <option value="133" <% checkSelVal("omcc_ver", "133"); %>>0x85</option>
            <option value="134" <% checkSelVal("omcc_ver", "134"); %>>0x86</option>
            <option value="150" <% checkSelVal("omcc_ver", "150"); %>>0x96</option>
            <option value="160" <% checkSelVal("omcc_ver", "160"); %>>0xA0</option>
            <option value="161" <% checkSelVal("omcc_ver", "161"); %>>0xA1</option>
            <option value="162" <% checkSelVal("omcc_ver", "162"); %>>0xA2</option>
            <option value="163" <% checkSelVal("omcc_ver", "163"); %>>0xA3</option>
            <option value="176" <% checkSelVal("omcc_ver", "176"); %>>0xB0</option>
            <option value="177" <% checkSelVal("omcc_ver", "177"); %>>0xB1</option>
            <option value="178" <% checkSelVal("omcc_ver", "178"); %>>0xB2</option>
            <option value="179" <% checkSelVal("omcc_ver", "179"); %>>0xB3</option>
        </select>
        (OMCC version)
    </td>
</tr>
		<tr>
			<th>Provisioning Code:</th>
			<td><input type="text" name="txt_provisioningcode" size="15" maxlength="40" value=<% getInfo("cwmp_provisioningcode"); %>>(e.g: TLCO.GRP2)</td>
		</tr>
		<tr>
			<th>Software <% multilang("727" "LANG_VERSION"); %>:</th>
			<td><input type="text" name="txt_swver" size="15" maxlength="14" value=<% getInfo("fwVersion"); %>>(e.g: 518_V364R92B00)</td>
		</tr>
		<tr>
			<th>Hardware <% multilang("727" "LANG_VERSION"); %>:</th>
			<td><input type="text" name="cwmp_hw_ver" size="15" maxlength="40" value=<% getInfo("cwmp_hw_ver"); %>>(e.g: Ver.B)</td>
		</tr>
<tr>
    <th>GPON Serial Number:</th>
    <td class="flex-cell">
        <input type="text" name="txt_gponsn" size="15" maxlength="12" 
               value=<% getInfo("gpon_sn"); %> 
               oninput="this.value = this.value.toUpperCase();">
        
        <span class="field_hint">
            Must start with 4 ASCII char. 
            <a href="https://hack-gpon.org/vendor/" target="_blank" class="vendor_link">
                View Vendor ID list (YOTC, HWTC, etc.)
            </a>
        </span>
    </td>
</tr>
		<tr>
			<th>ELAN MAC Address:</th>
			<td><input type="text" name="txt_elanmac" size="15" maxlength="12" value=<% getInfo("elan_mac_addr"); %>>(e.g: 08F9E0705D70)</td>
		</tr>
	    <tr>
			<th>WLAN MAC Address:</th>
			<td><input type="text" name="txt_wlanmac" size="15" maxlength="12" value=<% getInfo("wlan-Mac"); %>>(e.g: 08F9E0705D70)</td>
		</tr>
	</table>
</div>

<div class="btn_ctl">
    <input class="inner_btn" type="button" value="Save" onClick="return saveChanges()">
    <input class="inner_btn" type="button" value="Reset to Default" onClick="return resetClicked()">&nbsp;&nbsp;
    <input type="hidden" value="/vermod.asp" name="submit-url">
    <input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
</DIV>
<br>

<!-- NEW PON MODE SECTION -->
<div class="intro_main">
	<p class="intro_title">PON Mode Configuration</p>
	<p class="intro_content">Select the operational mode for the fiber uplink interface.</p>
</div>
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="35%">Status:</th>
			<td><span id="pon_status_text" style="font-weight: bold; color: #f1c40f;">Initializing...</span></td>
		</tr>
		<tr>
			<th valign="top" style="padding-top: 15px;">Operational Mode:</th>
			<td>
			    <div style="margin: 8px 0;">
			        <label style="cursor: pointer; font-size: 14px;"><input type="radio" name="pon_mode" id="mode_1" value="1" disabled style="margin-right: 8px; vertical-align: middle;"> <b>GPON Mode</b> (Gigabit Passive Optical Network)</label>
			    </div>
			    <div style="margin: 8px 0;">
			        <label style="cursor: pointer; font-size: 14px;"><input type="radio" name="pon_mode" id="mode_2" value="2" disabled style="margin-right: 8px; vertical-align: middle;"> <b>EPON Mode</b> (Ethernet Passive Optical Network)</label>
			    </div>
			    <div style="margin: 8px 0;">
			        <label style="cursor: pointer; font-size: 14px;"><input type="radio" name="pon_mode" id="mode_3" value="3" disabled style="margin-right: 8px; vertical-align: middle;"> <b>Ethernet Mode</b> (SFP Media Converter Mode)</label>
			    </div>
			</td>
		</tr>
	</table>
</div>
<div class="btn_ctl">
	<input class="inner_btn" type="button" id="save_pon_btn" value="Save PON Mode" onClick="savePonMode()" disabled>
</div>
</DIV>
<br>
<!-- END PON MODE SECTION -->

<div class="intro_main ">
	<p class="intro_title"><% multilang("1138" "LANG_OMCI"); %></p>
</div>

<form action=/boaform/formExportOMCIlog method=POST name="exportOMCIlog">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width=60%>export omci logs</th>
			<td>
				<input class="inner_btn" type="button" value="<% multilang("1136" "LANG_EXPORT"); %>" onclick="exportClick()">
				<input type="hidden" name="postSecurityFlag" value="">
			</td>
		</tr>
	</table>
</div>
</form>
</DIV>
<br>

<div class="intro_main ">
	<p class="intro_title">Execute script.</p>
	<p class="intro_content">after uploading, your script will be executed, also keep in mind to add "#/bin/sh" at the top of your script.</p>
</div>

<form action=/boaform/formImportOMCIShell enctype="multipart/form-data" method=POST name="saveConfig">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width=30%>you can execute a script by uploading it.</th>
			<td width=30%><input class="inner_btn" type="file" value="<% multilang("568" "LANG_CHOOSE_FILE"); %>" name="binary" size=24></td>
			<td><input class="inner_btn" type="submit" value="upload" name="load" onclick="return uploadClick()"></td>
		</tr>  
	</table>
</div>
</form> 

<script>
(function() {
    var cur = "<% getInfo("omcc_ver"); %>";
    var sel = document.querySelector('select[name="txt_omccver"]');
    if (sel) sel.value = cur;
})();
</script>
</DIV>
</blockquote>

</body>
</html>