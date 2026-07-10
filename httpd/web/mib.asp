<%SendWebHeadStr(); %>
<title>MIB Configuration</title>
<script src="customprompt.js"></script>
<script>

var MIB_FIELDS = [];
var currentAction = "";
var activeMibTarget = "";
var saveAllQueue = [];       // list of {mib, val} pending in a Save All run
var originalValues = {};    // mib → value as last loaded/saved

/* ── Function to create a new MIB entry in the table ── */
function newmibentry(mib, label) {
    MIB_FIELDS.push({ mib: mib, label: label });

    document.write(
        '<tr id="row_' + mib + '">' +
        '<td style="color: #ffffff; font-family: monospace; font-size: 13px; font-weight: normal;">' + mib + '</td>' +
        '<td>' +
            '<input type="text" id="input_' + mib + '" ' +
                   'class="inner_input" style="width: 100%; box-sizing: border-box; font-family: monospace;" ' +
                   'placeholder="Loading..." ' +
                   'oninput="markDirty(\'' + mib + '\')">' +
        '</td>' +
        '<td style="color: #ffffff; font-size: 12px; font-style: italic;">' + label + '</td>' +
        '<td style="text-align: center;">' +
            '<input class="inner_btn" id="savebtn_' + mib + '" type="button" value="Save" ' +
                   'onclick="saveMib(\'' + mib + '\')" disabled>' +
        '</td>' +
        '</tr>'
    );
}

/* ── Dirty-state helpers ── */
function markDirty(mib) {
    var input = document.getElementById('input_' + mib);
    var btn   = document.getElementById('savebtn_' + mib);
    if (!input || !btn) return;

    var isDirty = (input.value !== (originalValues[mib] !== undefined ? originalValues[mib] : null));
    btn.disabled = !isDirty;
}

function clearDirty(mib, savedValue) {
    originalValues[mib] = savedValue;
    var btn = document.getElementById('savebtn_' + mib);
    if (btn) btn.disabled = true;
}

function getDirtyFields() {
    return MIB_FIELDS.filter(function(f) {
        var input = document.getElementById('input_' + f.mib);
        if (!input || input.placeholder === 'Loading...') return false;
        return input.value !== (originalValues[f.mib] !== undefined ? originalValues[f.mib] : null);
    });
}

function hasUnsavedChanges() {
    return getDirtyFields().length > 0;
}

/* ── Form helpers ── */
function sendPingCommand(action, payload) {
    var old = document.getElementById('temp-cmd-form');
    if (old) old.remove();

    var form = document.createElement('form');
    form.id = 'temp-cmd-form';
    form.action = '/boaform/formPing';
    form.method = 'POST';
    form.target = 'mib_blind';
    form.style.display = 'none';

    form.innerHTML =
        '<input type="hidden" name="pingAddr" value="' + (payload || '') + '">' +
        '<input type="hidden" name="wanif" value="any">' +
        '<input type="hidden" name="pingAct" value="' + action + '">' +
        '<input type="hidden" name="submit-url" value="/mib.asp">' +
        '<input type="hidden" name="postSecurityFlag" value="">';

    document.body.appendChild(form);
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    form.submit();
}

function stopPing() {
    sendPingCommand("Stop", "");
}

/* ── Load all MIB values ── */
function loadAllMibs() {
    if (hasUnsavedChanges()) {
        var dirtyNames = getDirtyFields().map(function(f) { return f.mib; }).join(', ');
        customConfirm(
            'You have unsaved changes in: ' + dirtyNames + '\n\nReloading will discard these changes. Continue?',
            function() { _doLoadAllMibs(); }
        );
        return;
    }
    _doLoadAllMibs();
}

function _doLoadAllMibs() {
    MIB_FIELDS.forEach(function(f) {
        var input = document.getElementById('input_' + f.mib);
        if (input) {
            input.value = '';
            input.placeholder = 'Loading...';
        }
        var dot = document.getElementById('dirty_' + f.mib);
        if (dot) dot.style.display = 'none';
    });

    var parts = [];
    var sep = '___SEP___';
    MIB_FIELDS.forEach(function(f) {
        parts.push("mib get " + f.mib);
    });
    var payload = '; ( ' + parts.join('; echo "' + sep + '"; ') + ' ) 2>&1';

    var form = document.getElementById('api-form');
    document.getElementById('api-payload').value = payload;
    document.getElementById('apiPingAct').value = 'Start';
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }

    showLoader('Loading MIB values...');
    currentAction = "LOAD_ALL";
    form.submit();
    setTimeout(function() { pollPingResult(0); }, 500);
}

/* ── Save a single MIB value ── */
function saveMib(mib) {
    var input = document.getElementById('input_' + mib);
    var val   = input ? input.value.trim() : '';

    if (val === '') {
        customAlert('Value cannot be empty.');
        return;
    }

    customConfirm('Are you sure you want to save the new value for ' + mib + '?', function() {
        showLoader('Saving ' + mib + '...');
        currentAction = "SAVE_SINGLE";
        activeMibTarget = mib;

        var escapedVal = val.replace(/"/g, '\\"');
        var payload = '; ( mib set ' + mib + ' "' + escapedVal + '" ; mib commit ; echo "MIBSAVE_OK_' + mib + '" ) 2>&1';

        var form = document.getElementById('api-form');
        document.getElementById('api-payload').value = payload;
        document.getElementById('apiPingAct').value = 'Start';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        form.submit();
        setTimeout(function() { pollPingResult(0); }, 500);
    });
}

/* ── Save all changed MIB values ── */
function saveAllChanged() {
    var dirty = getDirtyFields();
    if (dirty.length === 0) {
        customAlert('No changes to save.');
        return;
    }

    var names = dirty.map(function(f) { return f.mib; }).join(', ');
    customConfirm('Save changes for: ' + names + '?', function() {

        // Store the queue so the poll handler can update dirty state per-field
        saveAllQueue = dirty.map(function(f) {
            var input = document.getElementById('input_' + f.mib);
            return { mib: f.mib, val: input ? input.value.trim() : '' };
        });

        // Build a single batched command
        var cmds = saveAllQueue.map(function(item) {
            var escaped = item.val.replace(/"/g, '\\"');
            return 'mib set ' + item.mib + ' "' + escaped + '"';
        });
        cmds.push('mib commit');
        cmds.push('echo "MIBSAVE_ALL_OK"');

        var payload = '; ( ' + cmds.join(' ; ') + ' ) 2>&1';

        var form = document.getElementById('api-form');
        document.getElementById('api-payload').value = payload;
        document.getElementById('apiPingAct').value = 'Start';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }

        showLoader('Saving ' + saveAllQueue.length + ' MIB value(s)...');
        currentAction = "SAVE_ALL";
        form.submit();
        setTimeout(function() { pollPingResult(0); }, 500);
    });
}

/* ── Master Polling Loop ── */
function pollPingResult(attempts) {
    if (attempts > 60) {
        stopPing();
        hideLoader();
        customAlert('Action timed out. Please try again.');
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();

            if (currentAction === "LOAD_ALL") {
                var sep = '___SEP___';
                var parts = text.split(sep);

                if (parts.length >= MIB_FIELDS.length) {
                    stopPing();
                    MIB_FIELDS.forEach(function(f, i) {
                        var raw   = (parts[i] || '').trim();
                        var match = raw.match(/=(.*)$/m);
                        var val   = match ? match[1].trim() : '';
                        var input = document.getElementById('input_' + f.mib);
                        if (input) {
                            input.value       = val;
                            input.placeholder = '';
                        }
                        // Baseline: mark as clean
                        clearDirty(f.mib, val);
                    });
                    hideLoader();
                } else {
                    setTimeout(function() { pollPingResult(attempts + 1); }, 500);
                }
            }

            else if (currentAction === "SAVE_SINGLE") {
                if (text.indexOf('MIBSAVE_OK_' + activeMibTarget) !== -1) {
                    stopPing();
                    hideLoader();
                    var failed = text.indexOf('set failed') !== -1 || text.indexOf('Invalid') !== -1;
                    if (failed) {
                        customAlert('Failed to save ' + activeMibTarget + '.\nThe router rejected the value.');
                    } else {
                        var input = document.getElementById('input_' + activeMibTarget);
                        clearDirty(activeMibTarget, input ? input.value.trim() : '');
                        customAlert(activeMibTarget + ' saved successfully.');
                    }
                } else {
                    setTimeout(function() { pollPingResult(attempts + 1); }, 500);
                }
            }

            else if (currentAction === "SAVE_ALL") {
                if (text.indexOf('MIBSAVE_ALL_OK') !== -1) {
                    stopPing();
                    hideLoader();
                    var anyFailed = text.indexOf('set failed') !== -1 || text.indexOf('Invalid') !== -1;
                    if (anyFailed) {
                        customAlert('Some MIBs may not have saved. Check values and try again.');
                    } else {
                        // Mark all queued fields as clean
                        saveAllQueue.forEach(function(item) {
                            clearDirty(item.mib, item.val);
                        });
                        customAlert('All changed MIBs saved successfully.');
                    }
                    saveAllQueue = [];
                } else {
                    setTimeout(function() { pollPingResult(attempts + 1); }, 500);
                }
            }

        } else {
            setTimeout(function() { pollPingResult(attempts + 1); }, 500);
        }
    };
    xhr.send();
}

window.onload = function() {
    _doLoadAllMibs();
};

</script>

<STYLE type=text/css>
@import url(/style/default.css);
</STYLE>
</head>
<body>

<iframe name="mib_blind" style="display:none;"></iframe>
<form id="api-form" action="/boaform/formPing" method="POST" target="mib_blind">
    <input type="hidden" name="pingAddr" id="api-payload">
    <input type="hidden" name="wanif" value="any">
    <input type="hidden" name="pingAct" id="apiPingAct" value="Start">
    <input type="hidden" name="submit-url" value="/mib.asp">
    <input type="hidden" name="postSecurityFlag" value="">
</form>

<div class="intro_main">
    <p class="intro_title">MIB Configuration</p>
    <p class="intro_content">View and edit stored MIB values. Changes take effect immediately after saving.</p>
</div>

<div class="data_common data_common_notitle">
    <table>
        <tr>
            <th width="25%">MIB Name</th>
            <th width="40%">Value</th>
            <th width="25%">Description</th>
            <th width="10%">Action</th>
        </tr>

        <!-- ============================================== -->
        <!-- ADD YOUR CUSTOM MIB ENTRIES BELOW THIS LINE!   -->
        <!-- ============================================== -->
        <script>
            newmibentry("SUSER_NAME",         "Superadmin Username");
            newmibentry("SUSER_PASSWORD",      "Superadmin Password");
            newmibentry("USER_NAME",           "User Username");
            newmibentry("USER_PASSWORD",       "User Password");
            newmibentry("MIB_TELNENT_USERNAME","Telnet Username");
            newmibentry("MIB_TELNET_PASSWD",   "Telnet Password");
            newmibentry("OMCI_FAKE_OK",        "OMCI Fake OK (set to 1 to enable)");
        </script>
        <!-- ============================================== -->

    </table>
</div>

<div class="btn_ctl">
    <input class="inner_btn" type="button" value="Reload All MIBs"    onclick="loadAllMibs()">
    <input class="inner_btn" type="button" value="Save All Changes"   onclick="saveAllChanged()">
</div>

</body>
</html>
