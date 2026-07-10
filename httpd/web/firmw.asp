<%SendWebHeadStr(); %>
<title>Firmware Bank Manager</title>

<!-- Import our shared UI functions! -->
<script src="customprompt.js"></script>

<script>
/* ─── Bank Manager ───────────────────────────────────────────── */
function loadPageData() {
    var form = document.getElementById('api-form');
    var sep  = '___SEP___';

    document.getElementById('api-payload').value =
        '; ( /var/config/httpd/lmeapi.sh GETBANKINFO; echo "' + sep + '"; ' +
        '/var/config/httpd/lmeapi.sh GETFWUPDATESTATUS ) 2>&1';
    document.getElementById('apiPingAct').value = 'Start';
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    form.submit();
    setTimeout(function() { pollPageData(0); }, 500);
}

function pollPageData(attempts) {
    if (attempts > 60) {
        stopApi();
        customAlert('Timed out loading page data.');
        return;
    }
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text  = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            var parts = text.split('___SEP___');

            if (parts.length >= 2) {
                stopApi();

                // ── Bank Info ──
                var bankRaw = parts[0].trim();
                if (bankRaw.indexOf('GETBANKINFO success') !== -1) {
                    var ver0   = bankRaw.match(/sw_version0=([^\n]+)/);
                    var ver1   = bankRaw.match(/sw_version1=([^\n]+)/);
                    var active = bankRaw.match(/sw_active=([^\n]+)/);
                    var commit = bankRaw.match(/sw_commit=([^\n]+)/);

                    ver0   = ver0   ? ver0[1].trim()   : 'Block Firmware Updates are on, or nv has an issue.';
                    ver1   = ver1   ? ver1[1].trim()   : 'Block Firmware Updates are on, or nv has an issue.';
                    active = active ? active[1].trim() : '0';
                    commit = commit ? commit[1].trim() : '0';
                    renderBankInfo(ver0, ver1, active, commit);
                } else {
                    customAlert('Failed to load bank info.');
                }

                // ── Block Status ──
                var blockRaw = parts[1].trim();
                if (blockRaw.indexOf('GETFWUPDATESTATUS blocked') !== -1) {
                    renderBlockStatus(true);
                } else if (blockRaw.indexOf('GETFWUPDATESTATUS unblocked') !== -1) {
                    renderBlockStatus(false);
                } else {
                    renderBlockStatus(null);
                }

            } else {
                setTimeout(function() { pollPageData(attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}
function pollBankInfo(attempts) {
    if (attempts > 60) {
        stopApi();
        customAlert('Timed out loading bank info.');
        return;
    }
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();

            if (text.indexOf('GETBANKINFO success') !== -1) {
                stopApi();

                var ver0   = text.match(/sw_version0=([^\n]+)/);
                var ver1   = text.match(/sw_version1=([^\n]+)/);
                var active = text.match(/sw_active=([^\n]+)/);
                var commit = text.match(/sw_commit=([^\n]+)/);

                ver0   = ver0   ? ver0[1].trim()   : 'Block Firmware Updates are on, or nv has an issue.';
                ver1   = ver1   ? ver1[1].trim()   : 'Block Firmware Updates are on, or nv has an issue.';
                active = active ? active[1].trim() : '0';
                commit = commit ? commit[1].trim() : '0';

                renderBankInfo(ver0, ver1, active, commit);
            } else if (text.indexOf('GETBANKINFO failed') !== -1) {
                stopApi();
                customAlert('Failed to load bank info.');
            } else {
                setTimeout(function() { pollBankInfo(attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}

function renderBankInfo(ver0, ver1, active, commit) {
    document.getElementById('ver0').textContent = ver0;
    document.getElementById('ver1').textContent = ver1;

    setActiveBadge('bank0', active === '0', commit === '0');
    setActiveBadge('bank1', active === '1', commit === '1');

    // Disable if currently active OR if version is unknown
    document.getElementById('switch-btn-0').disabled = (active === '0') || (ver0 === 'Block Firmware Updates are on, or nv has an issue.');
    document.getElementById('switch-btn-1').disabled = (active === '1') || (ver1 === 'Block Firmware Updates are on, or nv has an issue.');

    // Grey out the version cell if unknown
    document.getElementById('ver0').style.color = (ver0 === 'Block Firmware Updates are on, or nv has an issue.') ? '#aaa' : '';
    document.getElementById('ver1').style.color = (ver1 === 'Block Firmware Updates are on, or nv has an issue.') ? '#aaa' : '';
}

function setActiveBadge(bankId, isActive, isCommit) {
    var badge = document.getElementById(bankId + '-badge');
    if (isActive) {
        badge.textContent  = 'Active';
        badge.className    = 'boot-status boot-status-on';
    } else if (isCommit) {
        badge.textContent  = 'Committed';
        badge.className    = 'boot-status boot-status-commit';
    } else {
        badge.textContent  = 'Inactive';
        badge.className    = 'boot-status boot-status-off';
    }
}

function switchBank(bank) {
    customConfirm('Switch to Bank ' + bank + ' and reboot?\nThe ONT will be unavailable for 1 minute.', function() {
        document.getElementById('switch-btn-0').disabled = true;
        document.getElementById('switch-btn-1').disabled = true;

        var form = document.getElementById('api-form');
        document.getElementById('api-payload').value = '; /var/config/httpd/lmeapi.sh SWITCHBANK ' + bank + ' 2>&1';
        document.getElementById('apiPingAct').value = 'Start';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }

        try { window.parent.rebooting = true; } catch(e) {}
        showLoader('Switching to Bank ' + bank + ',<br>the ONT is rebooting.');

        form.submit();
        setTimeout(function() { pollSwitch(bank, 0); }, 500);
    });
}

function pollSwitch(bank, attempts) {
    if (attempts > 60) {
        stopApi();
        hideLoader();
        customAlert('Timed out while switching.');
        return;
    }
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            if (text.indexOf('SWITCHBANK success') !== -1) {
                stopApi();
                var form = document.getElementById('api-form');
                document.getElementById('api-payload').value = '; reboot 2>&1';
                document.getElementById('apiPingAct').value = 'Start';
                if (typeof postTableEncrypt === 'function') {
                    postTableEncrypt(form.postSecurityFlag, form);
                }
                form.submit();
                setTimeout(function() {
                    top.window.location.href = '/admin/login.asp';
                }, 60000);
            } else if (text.indexOf('SWITCHBANK failed') !== -1) {
                stopApi();
                hideLoader();
                customAlert('Switch failed. Try again.', function() {
                    loadBankInfo();
                });
            } else {
                setTimeout(function() { pollSwitch(bank, attempts + 1); }, 500);
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


/* ─── FW Update Block Status ─────────────────────────────────── */

function pollBlockStatus(attempts) {
    if (attempts > 30) { renderBlockStatus(null); return; }
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            if (text.indexOf('GETFWUPDATESTATUS blocked') !== -1) {
                stopApi(); renderBlockStatus(true);
            } else if (text.indexOf('GETFWUPDATESTATUS unblocked') !== -1) {
                stopApi(); renderBlockStatus(false);
            } else {
                setTimeout(function() { pollBlockStatus(attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}

function renderBlockStatus(blocked) {
    var badge = document.getElementById('block-status-badge');
    var btn   = document.getElementById('block-toggle-btn');
    if (blocked === null) {
        badge.textContent = 'Unknown';
        badge.className   = 'boot-status boot-status-unknown';
        btn.disabled = false;
        return;
    }
    if (blocked) {
        badge.textContent = 'Enabled';
        badge.className   = 'boot-status boot-status-on';
        btn.value    = 'Unblock Updates';
        btn.disabled = false;
    } else {
        badge.textContent = 'Disabled';
        badge.className   = 'boot-status boot-status-off';
        btn.value    = 'Block Updates';
        btn.disabled = false;
    }
}

function toggleBlockStatus() {
    var badge = document.getElementById('block-status-badge');
    var isBlocked = badge.textContent === 'Blocked';
    var action = isBlocked ? 'UNBLOCKFWUPDATE' : 'BLOCKFWUPDATE';
    var msg    = isBlocked ? 'Allow firmware updates?' : 'Block firmware updates?\nThis will also persist across reboots.';

    customConfirm(msg, function() {
        document.getElementById('block-toggle-btn').disabled = true;
        badge.textContent = 'Working...';
        badge.className   = 'boot-status boot-status-unknown';

        var form = document.getElementById('api-form');
        document.getElementById('api-payload').value =
            '; /var/config/httpd/lmeapi.sh ' + action + ' 2>&1';
        document.getElementById('apiPingAct').value = 'Start';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        form.submit();
        setTimeout(function() { pollBlockToggle(action, 0); }, 500);
    });
}

function pollBlockToggle(action, attempts) {
    if (attempts > 30) { stopApi(); loadPageData(); return; }
    var successKey = action === 'BLOCKFWUPDATE' ? 'BLOCKFWUPDATE success' : 'UNBLOCKFWUPDATE success';
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            if (text.indexOf(successKey) !== -1) {
                stopApi(); loadPageData();
            } else {
                setTimeout(function() { pollBlockToggle(action, attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}


/* ─── Firmware Upload Logic ──────────────────────────────────── */
function uploadFirmware() {
    var fileInput = document.getElementById('fw-file-input');
    
    if (!fileInput.files || !fileInput.files[0]) {
        customAlert('Please select a firmware package first.');
        return;
    }

    var fileName = fileInput.files[0].name.toLowerCase();
    if (!fileName.endsWith('.tar') && !fileName.endsWith('.tar.gz') && !fileName.endsWith('.tgz')) {
        customAlert('Only .tar, .tar.gz, or .tgz files are supported.');
        return;
    }

    customConfirm('Are you sure you want to upload and flash this firmware package?\nPlease DO NOT power off the router during this process.', function() {
        document.getElementById('fw-upload-btn').disabled = true;

        try { window.parent.rebooting = true; } catch(e) {}
        showLoader('Uploading and flashing firmware.<br>Do not power off...');

        // Submit the file upload form to the hidden iframe
        document.getElementById('fw-upload-form').submit();

        // Give it a short delay to start the network stream, then trigger the bash script
        setTimeout(function() {
            var form = document.getElementById('api-form');
            document.getElementById('api-payload').value = '; /var/config/httpd/lmeapi.sh FWUPLOAD 2>&1';
            document.getElementById('apiPingAct').value = 'Start';
            if (typeof postTableEncrypt === 'function') {
                postTableEncrypt(form.postSecurityFlag, form);
            }
            form.submit();
            pollFirmwareUpload(0);
        }, 1500);
    });
}

function pollFirmwareUpload(attempts) {
    if (attempts > 300) { // 10 minute maximum timeout
        stopApi();
        hideLoader();
        try { window.parent.rebooting = false; } catch(e) {}
        document.getElementById('fw-upload-btn').disabled = false;
        customAlert('Firmware update timed out.');
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();

            if (text.indexOf('WAITFORFILE failed') !== -1) {
                stopApi();
                hideLoader();
                try { window.parent.rebooting = false; } catch(e) {}
                
                var waitMatch = text.match(/WAITFORFILE failed.*/);
                customAlert('Upload failed:\n' + (waitMatch ? waitMatch[0] : 'Unknown error'));
                document.getElementById('fw-upload-btn').disabled = false;

            } else if (text.indexOf('FWUPDATE failed') !== -1) {
                stopApi();
                hideLoader();
                try { window.parent.rebooting = false; } catch(e) {}
                
                var failMatch = text.match(/FWUPDATE failed.*/);
                customAlert(failMatch ? failMatch[0] : 'Execution failed.');
                document.getElementById('fw-upload-btn').disabled = false;

            } else if (text.indexOf('FWUPDATE success') !== -1) {
                stopApi();
                
                
                // Trigger auto-reboot to apply the bank
                var form = document.getElementById('api-form');
                document.getElementById('api-payload').value = '; reboot 2>&1';
                document.getElementById('apiPingAct').value = 'Start';
                if (typeof postTableEncrypt === 'function') {
                    postTableEncrypt(form.postSecurityFlag, form);
                }
                form.submit();

setTimeout(function() {
    hideLoader();
    customAlert('Firmware flashed successfully!\nThe system is rebooting,\nwait at least 1 minute for the system to startup.', function() {
        top.window.location.href = '/admin/login.asp';
    });
}, 5000);
            } else {
                setTimeout(function() { pollFirmwareUpload(attempts + 1); }, 2000);
            }
        } else {
            setTimeout(function() { pollFirmwareUpload(attempts + 1); }, 2000);
        }
    }; 
    xhr.onerror = function() {
        setTimeout(function() { pollFirmwareUpload(attempts + 1); }, 2000);
    };
    xhr.send();
}

function init() {
    loadBlockStatus();
    loadBankInfo();
}
window.onload = function() { loadPageData(); };
</script>
<STYLE type=text/css>
@import url(/style/default.css);
</STYLE>
<style>
.boot-status {
    display: inline-block;
    padding: 2px 10px;
    border-radius: 3px;
    font-size: 12px;
    font-weight: bold;
    min-width: 80px;
    text-align: center;
}
.boot-status-on      { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
.boot-status-off     { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
.boot-status-commit  { background: #cce5ff; color: #004085; border: 1px solid #b8daff; }
.boot-status-unknown { background: #fff3cd; color: #856404; border: 1px solid #ffeeba; }
</style>
</head>
<body>

<iframe name="api_blind" style="display:none;"></iframe>
<iframe name="upload_blind" style="display:none;"></iframe>
<form id="api-form" action="/boaform/formPing" method="POST" target="api_blind">
    <input type="hidden" name="pingAddr" id="api-payload">
    <input type="hidden" name="wanif" value="any">
    <input type="hidden" name="pingAct" id="apiPingAct" value="Start">
    <input type="hidden" name="submit-url" value="/fwbank.asp">
    <input type="hidden" name="postSecurityFlag" value="">
</form>

<div class="intro_main">
    <p class="intro_title">Firmware Bank Manager</p>
    <p class="intro_content">View and switch between the two firmware banks. Switching will reboot the device.</p>
</div>

<div class="data_common data_common_notitle">
    <table>
        <tr>
            <th width="15%">Bank</th>
            <th width="45%">Version</th>
            <th width="20%">Status</th>
            <th width="20%">Action</th>
        </tr>
        <tr>
            <th>Bank 0</th>
            <td id="ver0">Loading...</td>
            <td><span id="bank0-badge" class="boot-status boot-status-unknown">Loading...</span></td>
            <td><input class="inner_btn" type="button" id="switch-btn-0" value="Switch to Bank 0" disabled onClick="switchBank(0)"></td>
        </tr>
        <tr>
            <th>Bank 1</th>
            <td id="ver1">Loading...</td>
            <td><span id="bank1-badge" class="boot-status boot-status-unknown">Loading...</span></td>
            <td><input class="inner_btn" type="button" id="switch-btn-1" value="Switch to Bank 1" disabled onClick="switchBank(1)"></td>
        </tr>
    </table>
</div>


<br>
<div class="intro_main">
    <p class="intro_title">Firmware Update</p>
    <p class="intro_content">Upload a custom firmware package (.tar). The router will automatically extract it and run the included update script. This will flash the inactive bank.</p>
</div>

<form id="fw-upload-form" action="/boaform/formImportOMCIShell" enctype="multipart/form-data" method=POST name="fwConfig" target="upload_blind">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width=30%>Firmware Package (.tar / .tar.gz)</th>
			<td width=30%><input class="inner_btn" type="file" id="fw-file-input" name="binary" size=24 accept=".tar,.tar.gz,.tgz"></td>
			<td><input class="inner_btn" type="button" id="fw-upload-btn" value="Upload & Flash" name="load" onclick="uploadFirmware()"></td>
		</tr>  
		<tr>
    <th width=30%>Firmware Update Protection</th>
    <td width=30%><span id="block-status-badge" class="boot-status boot-status-unknown">Loading...</span></td>
    <td><input class="inner_btn" type="button" id="block-toggle-btn" value="..." disabled onclick="toggleBlockStatus()"></td>
</tr>

	</table>
</div>
</form> 

</body>
</html>