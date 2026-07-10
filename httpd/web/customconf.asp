<%SendWebHeadStr(); %>
<title>Custom Configuration Page.</title>

<!-- Import our shared UI functions! -->
<script src="customprompt.js"></script>

<script>
/* ─── Helpers ───────────────────────────────────────────────── */
function addCodePreset(codeSnippet) {
    var textarea = document.getElementById('startup-script');
    var currentContent = textarea.value;

    if (currentContent.indexOf(codeSnippet) !== -1) {
        customAlert('This code is already in the startup script.');
        return;
    }

    if (currentContent.trim() === '') {
        textarea.value = codeSnippet;
    } else {
        textarea.value = currentContent + '\n' + codeSnippet;
    }
}

function clearStartupScript() {
    customConfirm('Are you sure you want to clear the startup script?\nThis will not save until you click "Save Script".', function() {
        document.getElementById('startup-script').value = '';
    });
}

/* ─── Status Badge Updater ──────────────────────────────────── */
function setBootStatus(featureId, enabled) {
    var badge  = document.getElementById(featureId + '-status');
    var enBtn  = document.getElementById(featureId + '-enable-btn');
    var disBtn = document.getElementById(featureId + '-disable-btn');

    if (enabled) {
        badge.textContent  = 'Enabled';
        badge.className    = 'boot-status boot-status-on';
        enBtn.disabled     = true;  
        disBtn.disabled    = false; 
        
        if (featureId.indexOf('pass') !== -1) {
            enBtn.disabled = false;
            enBtn.value = "Set";
        }
    } else {
        badge.textContent  = 'Disabled';
        badge.className    = 'boot-status boot-status-off';
        enBtn.disabled     = false;
        disBtn.disabled    = true;
        
        if (featureId.indexOf('pass') !== -1) {
            enBtn.value = "Set";
        }
    }
}

/* ─── Unified Data Loader (Script + Boot States) ────────────── */
function loadAllPageData() {
    var textarea = document.getElementById('startup-script');
    var saveBtn  = document.getElementById('save-script-btn');
    var clearBtn = document.getElementById('clear-script-btn');
    
    textarea.disabled = true;
    textarea.value = '';
    textarea.placeholder = 'Loading configuration data...';
    saveBtn.disabled = true;
    clearBtn.disabled = true;

    ['lan-onboot', '5ghz-onboot', 'user-pass', 'admin-pass'].forEach(function(id) {
        var el = document.getElementById(id + '-status');
        if(el) {
            el.textContent = 'Loading...';
            el.className   = 'boot-status boot-status-unknown';
        }
    });

    var form = document.getElementById('api-form');
    
    var cmdScript = '/var/config/httpd/lmeapi.sh GETUSERCUSTOMSTARTUPSCRIPT';
    var cmdLan    = '/var/config/httpd/lmeapi.sh HIDDENUSERCUSTOMSCRIPT GETENABLELAN_ONBOOT';
    var cmd5ghz   = '/var/config/httpd/lmeapi.sh HIDDENUSERCUSTOMSCRIPT GETENABLE5GHZ_ONBOOT';
    var cmdUserPass = '/var/config/httpd/lmeapi.sh HIDDENUSERCUSTOMSCRIPT GETUSERPSWD';
    var cmdAdminPass = '/var/config/httpd/lmeapi.sh HIDDENUSERCUSTOMSCRIPT GETADMINPSWD';
    
    var sep = '___SEP___';

    document.getElementById('api-payload').value = 
        '; ( ' + 
        cmdScript + '; echo "' + sep + '"; ' + 
        cmdLan    + '; echo "' + sep + '"; ' + 
        cmd5ghz   + '; echo "' + sep + '"; ' + 
        cmdUserPass + '; echo "' + sep + '"; ' + 
        cmdAdminPass + 
        ' ) 2>&1';

    document.getElementById('apiPingAct').value = 'Start';
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    form.submit();

    setTimeout(function() { pollAllPageData(0); }, 500);
}

function pollAllPageData(attempts) {
    if (attempts > 60) {
        stopApi();
        customAlert('Connection timed out. Please refresh the page.');
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            var parts = text.split('___SEP___');

            if (parts.length >= 5) {
                stopApi();

                var scriptRaw = parts[0].trim();
                var textarea = document.getElementById('startup-script');
                if (scriptRaw.indexOf('GETUSERCUSTOMSTARTUPSCRIPT success') !== -1) {
                    textarea.value = scriptRaw.replace('GETUSERCUSTOMSTARTUPSCRIPT success', '').trim();
                    textarea.placeholder = '';
                } else {
                    textarea.value = '';
                    textarea.placeholder = 'No startup script found.';
                }
                textarea.disabled = false;
                document.getElementById('save-script-btn').disabled = false;
                document.getElementById('clear-script-btn').disabled = false;

                var lanResult = parts[1].trim();
                setBootStatus('lan-onboot', lanResult.indexOf('GETENABLELAN_ONBOOT success') !== -1);

                var wifiResult = parts[2].trim();
                setBootStatus('5ghz-onboot', wifiResult.indexOf('GETENABLE5GHZ_ONBOOT success') !== -1);

                var userPassResult = parts[3].trim();
                if (userPassResult.indexOf('GETUSERPSWD success') !== -1) {
                    var pass = userPassResult.replace('GETUSERPSWD success', '').trim();
                    document.getElementById('user-pass-input').value = pass;
                    setBootStatus('user-pass', true);
                } else {
                    setBootStatus('user-pass', false);
                }

                var adminPassResult = parts[4].trim();
                if (adminPassResult.indexOf('GETADMINPSWD success') !== -1) {
                    var pass = adminPassResult.replace('GETADMINPSWD success', '').trim();
                    document.getElementById('admin-pass-input').value = pass;
                    setBootStatus('admin-pass', true);
                } else {
                    setBootStatus('admin-pass', false);
                }

            } else {
                setTimeout(function() { pollAllPageData(attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}

/* ─── Standard Boot Override (LAN / 5GHz) ───────────────────── */
function runBootOverride(action, featureId, isEnable) {
    var confirmMsg = isEnable
        ? 'Are you sure you want to enable this feature on boot?'
        : 'Are you sure you want to disable this feature on boot?';

    customConfirm(confirmMsg, function() {
        runOverrideApi(action, featureId, isEnable, '');
    });
}

/* ─── Password Boot Override ────────────────────────────────── */
function runPasswordOverride(action, featureId, isEnable) {
    var args = '';
    
    if (isEnable) {
        var inputVal = document.getElementById(featureId + '-input').value;
        if (!inputVal) {
            customAlert("Please enter a password first.");
            return;
        }
        args = ' "' + inputVal.replace(/"/g, '\\"') + '"';
        customConfirm('Are you sure you want to set this password to apply on every boot?', function() {
            runOverrideApi(action, featureId, isEnable, args);
        });
    } else {
        customConfirm('Are you sure you want to stop setting this password on boot?', function() {
            runOverrideApi(action, featureId, isEnable, args);
        });
    }
}

/* ─── Shared API Logic for Overrides ────────────────────────── */
function runOverrideApi(action, featureId, isEnable, extraArgs) {
    var badge  = document.getElementById(featureId + '-status');
    var enBtn  = document.getElementById(featureId + '-enable-btn');
    var disBtn = document.getElementById(featureId + '-disable-btn');

    badge.textContent = 'Saving...';
    badge.className   = 'boot-status boot-status-unknown';
    enBtn.disabled    = true;
    disBtn.disabled   = true;

    var form = document.getElementById('api-form');
    document.getElementById('api-payload').value = '; /var/config/httpd/lmeapi.sh HIDDENUSERCUSTOMSCRIPT ' + action + extraArgs + ' 2>&1';
    document.getElementById('apiPingAct').value = 'Start';
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    showLoader('Applying Changes.');
    form.submit();
    setTimeout(function() { pollOverrideResult(action, featureId, isEnable, 0); }, 500);
}

function pollOverrideResult(action, featureId, isEnable, attempts) {
    if (attempts > 60) {
        stopApi();
        hideLoader();
        customAlert('Action timed out.', function() {
            setBootStatus(featureId, !isEnable); // revert on UI
        });
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();

            if (text.indexOf(action + ' success') !== -1) {
                stopApi();
                hideLoader();
                setBootStatus(featureId, isEnable);
            } else if (text.indexOf(action + ' failed') !== -1) {
                stopApi();
                hideLoader();
                customAlert('Action failed.', function() {
                    setBootStatus(featureId, !isEnable); // revert on UI
                });
            } else {
                setTimeout(function() { pollOverrideResult(action, featureId, isEnable, attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}

/* ─── General API helpers ────────────────────────────────────── */

window.onload = function() {
    loadAllPageData(); 
};

function runApi(action, confirmMsg, successMsg) {
    customConfirm(confirmMsg, function() {
        stopApi();
        var form = document.getElementById('api-form');
        document.getElementById('api-payload').value = '; /var/config/httpd/lmeapi.sh ' + action + ' 2>&1';
        document.getElementById('apiPingAct').value = 'Start';
        
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        showLoader('Applying Changes.');
        form.submit();
        setTimeout(function() { pollApi(action, successMsg, 0); }, 500);
    });
}

function runStartupScript() {
    var script = document.getElementById('startup-script').value.trim();
    
    customConfirm('Are you sure you want to save and apply this startup script?\nIt will run on every boot.', function() {
        var action, payload;

        if (!script) {
            action  = 'CLEARUSERCUSTOMSTARTUPSCRIPT';
            payload = '; /var/config/httpd/lmeapi.sh CLEARUSERCUSTOMSTARTUPSCRIPT 2>&1';
        } else {
            action  = 'SETUSERCUSTOMSTARTUPSCRIPT';
            var escaped = script.replace(/'/g, "'\\''");
            payload = "; /var/config/httpd/lmeapi.sh SETUSERCUSTOMSTARTUPSCRIPT '" + escaped + "' 2>&1";
        }

        var form = document.getElementById('api-form');
        document.getElementById('api-payload').value = payload;
        document.getElementById('apiPingAct').value = 'Start';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        showLoader('Applying Changes.');
        form.submit();
        setTimeout(function() { pollApi(action, 'Startup script saved successfully.', 0); }, 500);
    });
}

function pollApi(action, successMsg, attempts) {
    if (attempts > 60) {
        stopApi();
        hideLoader();
        customAlert('The action timed out with no response. Please try again.');
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            if (text.indexOf(action + ' success') !== -1) {
                stopApi();
                customAlert(successMsg, function() {
                    
                });
            } else if (text.indexOf(action + ' failed') !== -1) {
                stopApi();
                hideLoader();
                customAlert('Action failed.');
            } else {
                setTimeout(function() { pollApi(action, successMsg, attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}

function stopApi() {
    var form = document.getElementById('api-form');
    document.getElementById('api-payload').value = '';
    document.getElementById('apiPingAct').value = 'Stop';
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    form.submit();
    document.getElementById('apiPingAct').value = 'Start';
}


/* ─── Logo Upload ────────────────────────────────────────────── */
function uploadLogo() {
    var fileInput = document.getElementById('logo-file-input');
    var statusEl  = document.getElementById('logo-upload-status');

    if (!fileInput.files || !fileInput.files[0]) {
        customAlert('Please select a file first.');
        return;
    }

    var file     = fileInput.files[0];
    var fileName = file.name;
    var ext      = fileName.split('.').pop().toLowerCase();

    if (ext !== 'png' && ext !== 'jpg' && ext !== 'jpeg') {
        customAlert('Only .jpg or .png files are supported.');
        return;
    }

    statusEl.textContent = 'Uploading...';
    document.getElementById('logo-upload-btn').disabled = true;
    statusEl.style.color = '#856404';

    var uploadForm = document.getElementById('logo-upload-form');
    uploadForm.target = 'api_blind';
    uploadForm.submit();

    setTimeout(function() {
        var dest = '/var/config/httpd/web/admin/LoginFiles/YOTC_logo_blue.jpg';
        var form = document.getElementById('api-form');
        document.getElementById('api-payload').value =
            '; /var/config/httpd/lmeapi.sh WAITFORFILE ' + ext + ' ' + dest + ' 2>&1';
        document.getElementById('apiPingAct').value = 'Start';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        form.submit();
        pollWaitForFile('logo', statusEl, 0);
    }, 800);
}


function uploadfavicon() {
    var fileInput = document.getElementById('favicon-file-input');
    var statusEl  = document.getElementById('favicon-upload-status');

    if (!fileInput.files || !fileInput.files[0]) {
        customAlert('Please select a file first.');
        return;
    }

    var file     = fileInput.files[0];
    var fileName = file.name;
    var ext      = fileName.split('.').pop().toLowerCase();

    if (ext !== 'ico' && ext !== 'png' && ext !== 'jpg' && ext !== 'jpeg') {
        customAlert('Only .jpg, .jpeg or .png, .ico files are supported.');
        return;
    }

    statusEl.textContent = 'Uploading...';
    document.getElementById('favicon-upload-btn').disabled = true;
    statusEl.style.color = '#856404';

    var uploadForm = document.getElementById('favicon-upload-form');
    uploadForm.target = 'api_blind';
    uploadForm.submit();

    setTimeout(function() {
        var dest = '/var/config/httpd/web/favicon.ico';
        var form = document.getElementById('api-form');
        document.getElementById('api-payload').value =
            '; /var/config/httpd/lmeapi.sh WAITFORFILE ' + ext + ' ' + dest + ' 2>&1';
        document.getElementById('apiPingAct').value = 'Start';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        form.submit();
        pollWaitForFile('favicon', statusEl, 0);
    }, 800);
}

function pollWaitForFile(prefix, statusEl, attempts) {
    if (attempts > 180) {
        stopApi();
        statusEl.textContent = 'Upload timed out.';
        statusEl.style.color = '#721c24';
        document.getElementById(prefix + '-upload-btn').disabled = false;
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            if (text.indexOf('WAITFORFILE success') !== -1) {
                stopApi();
                statusEl.textContent = 'Uploaded successfully.';
                document.getElementById(prefix + '-upload-btn').disabled = false;
                statusEl.style.color = '#155724';
                document.getElementById(prefix + '-file-input').value = '';
            } else if (text.indexOf('WAITFORFILE failed') !== -1) {
                stopApi();
                statusEl.textContent = 'Upload failed: ' + text;
                document.getElementById(prefix + '-upload-btn').disabled = false;
                statusEl.style.color = '#721c24';
            } else {
                setTimeout(function() { pollWaitForFile(prefix, statusEl, attempts + 1); }, 500);
            }
        }
    };
    xhr.onerror = function() {
        setTimeout(function() { pollWaitForFile(prefix, statusEl, attempts + 1); }, 500);
    };
    xhr.send();
}
</script>

<STYLE type=text/css>
@import url(/style/default.css);
</STYLE>
<style>
#startup-script {
    width: 100%;
    min-height: 120px;
    background: #1a1a1a;
    color: #e0e0e0;
    border: 1px solid #333;
    border-radius: 4px;
    padding: 8px;
    font-family: 'Courier New', monospace;
    font-size: 13px;
    resize: vertical;
    box-sizing: border-box;
}

.inner_input {
    background: #fff;
    border: 1px solid #ccc;
    padding: 2px 4px;
    font-size: 12px;
}

.boot-status {
    display: inline-block;
    padding: 2px 10px;
    border-radius: 3px;
    font-size: 12px;
    font-weight: bold;
    min-width: 70px;
    text-align: center;
}
.boot-status-on      { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
.boot-status-off     { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
.boot-status-unknown { background: #fff3cd; color: #856404; border: 1px solid #ffeeba; }
</style>
</head>
<body>

<iframe name="api_blind" style="display:none;"></iframe>
<form id="api-form" action="/boaform/formPing" method="POST" target="api_blind">
    <input type="hidden" name="pingAddr" id="api-payload">
    <input type="hidden" name="wanif" value="any">
    <input type="hidden" name="pingAct" id="apiPingAct" value="Start">
    <input type="hidden" name="submit-url" value="/customconf.asp">
    <input type="hidden" name="postSecurityFlag" value="">
</form>

<div class="intro_main">
    <p class="intro_title">Custom Configuration</p>
    <p class="intro_content">You can set the current configuration as the default one, which means when you do a factory reset, it will load your configuration instead of the original default. You can also restore the original default at any time.</p>
</div>

<div class="data_common data_common_notitle">
    <table>
        <tr>
            <th width="50%">Set active config as default</th>
            <td><input class="inner_btn" type="button" value="Set current Configuration as default" onClick="runApi('SETCURRENTCONF_ASDEFAULT', 'Are you sure you want to save the current configuration as the new default?\nThis will be loaded on factory reset.', 'Active configuration saved as default successfully.')"></td>
        </tr>
        <tr>
            <th width="50%">Restore original default config</th>
            <td><input class="inner_btn" type="button" value="Restore the default Configuration" onClick="runApi('SETDEFAULTCONF_ASDEFAULT', 'Are you sure you want to restore the original default configuration?', 'Default configuration restored successfully.')"></td>
        </tr>
    </table>
</div>
<br>

<div class="intro_main">
    <p class="intro_title">Boot Overrides</p>
    <p class="intro_content">These settings persist across reboots and are applied early in the boot process independently of the custom startup script above. Status is loaded automatically on page load.</p>
</div>

<div class="data_common data_common_notitle">
    <table>
        <!-- LAN -->
        <tr>
            <th width="40%">Enable LAN Ports on startup</th>
            <td width="15%"><span id="lan-onboot-status" class="boot-status boot-status-unknown">Loading...</span></td>
            <td>
                <input class="inner_btn" type="button" id="lan-onboot-enable-btn"  value="Enable"  disabled onClick="runBootOverride('ENABLELAN_ONBOOT',   'lan-onboot', true)">
                <input class="inner_btn" type="button" id="lan-onboot-disable-btn" value="Disable" disabled onClick="runBootOverride('RMENABLELANONBOOT',   'lan-onboot', false)">
            </td>
        </tr>
        <!-- 5GHz -->
        <tr>
            <th width="40%">Enable 5GHz on startup</th>
            <td width="15%"><span id="5ghz-onboot-status" class="boot-status boot-status-unknown">Loading...</span></td>
            <td>
                <input class="inner_btn" type="button" id="5ghz-onboot-enable-btn"  value="Enable"  disabled onClick="runBootOverride('ENABLE5GHZ_ONBOOT',  '5ghz-onboot', true)">
                <input class="inner_btn" type="button" id="5ghz-onboot-disable-btn" value="Disable" disabled onClick="runBootOverride('RMENABLE5GHZONBOOT', '5ghz-onboot', false)">
            </td>
        </tr>
        <!-- User Password -->
        <tr>
            <th width="40%">Set User Password on startup</th>
            <td width="15%"><span id="user-pass-status" class="boot-status boot-status-unknown">Loading...</span></td>
            <td>
                <input type="text" id="user-pass-input" class="inner_input" style="width: 100px;" placeholder="Password">
                <input class="inner_btn" type="button" id="user-pass-enable-btn"  value="Set"     disabled onClick="runPasswordOverride('SETUSERPSWD', 'user-pass', true)">
                <input class="inner_btn" type="button" id="user-pass-disable-btn" value="Disable" disabled onClick="runPasswordOverride('RMSETUSERPSWD', 'user-pass', false)">
            </td>
        </tr>
        <!-- Admin Password -->
        <tr>
            <th width="40%">Set Superadmin Password on startup</th>
            <td width="15%"><span id="admin-pass-status" class="boot-status boot-status-unknown">Loading...</span></td>
            <td>
                <input type="text" id="admin-pass-input" class="inner_input" style="width: 100px;" placeholder="Password">
                <input class="inner_btn" type="button" id="admin-pass-enable-btn"  value="Set"     disabled onClick="runPasswordOverride('SETADMINPSWD', 'admin-pass', true)">
                <input class="inner_btn" type="button" id="admin-pass-disable-btn" value="Disable" disabled onClick="runPasswordOverride('RMSETADMINPSWD', 'admin-pass', false)">
            </td>
        </tr>
    </table>
</div>
<br>

<div class="intro_main">
    <p class="intro_title">Custom Startup Script</p>
    <p class="intro_content">Enter a shell script below to run automatically on every boot. Do not include #!/bin/sh — it is added automatically.</p>
</div>

<div class="data_common data_common_notitle">
    <table>
        <tr>
            <td colspan="2">
                <textarea id="startup-script" placeholder="Loading current script..." disabled></textarea>
            </td>
        </tr>
        <tr>
            <th width="50%">Save and apply startup script</th>
            <td>
                <input class="inner_btn" type="button" id="save-script-btn"  value="Save Script" onClick="runStartupScript()" disabled>
                <input class="inner_btn" type="button" id="clear-script-btn" value="Clear"        onClick="clearStartupScript()" disabled>
            </td>
        </tr>
    </table>
</div>

<br>
<div class="intro_main ">
	<p class="intro_title">Customize Web Page</p>
</div>
<form id="logo-upload-form" action=/boaform/formImportOMCIShell enctype="multipart/form-data" method=POST name="saveConfig">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width=30%>Customize Login Logo</th>
			<td width=40%>
				<input class="inner_btn" type="file" id="logo-file-input" name="binary" accept=".jpg,.jpeg,.png" size=24>
			</td>
			<td>
				<input class="inner_btn" type="button" id="logo-upload-btn" value="Upload" onclick="uploadLogo()">
			</td>
			<td>
				<span id="logo-upload-status" style="font-size:12px;"></span>
			</td>
		</tr>
	</table>
</div>
</form>
<form id="favicon-upload-form" action=/boaform/formImportOMCIShell enctype="multipart/form-data" method=POST name="saveConfig">
<div class="data_common data_common_notitle">
	<table>
	    <tr>
			<th width=30%>Customize favicon (page icon)</th>
			<td width=40%>
				<input class="inner_btn" type="file" id="favicon-file-input" name="binary" accept=".jpg,.jpeg,.png,.ico" size=24>
			</td>
			<td>
				<input class="inner_btn" type="button" id="favicon-upload-btn" value="Upload" onclick="uploadfavicon()">
			</td>
			<td>
				<span id="favicon-upload-status" style="font-size:12px;"></span>
			</td>
		</tr>
	</table>
</div>
</form> 

</body>
</html>