<%SendWebHeadStr(); %>
<title>Mod About Page.</title>
<STYLE type=text/css>
@import url(/style/default.css);
.helper-link {
    text-decoration: none; /* Removes underline */
    color: var(--text-secondary) !important;
    display: flex;
    align-items: center;  /* Centers icon and text vertically */
}

.helper-link:hover {
    text-decoration: underline; /* Shows underline only on hover */
    color: var(--text-primary) !important; 
}

.helper-icon {
    width: 20px;          /* Adjust size to match text */
    height: 20px;
    margin-right: 2.tpx;    /* Space between icon and name */
    vertical-align: middle;
}
</STYLE>
<script>
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

function runUninstall() {
    if (!confirm('Are you sure you want to uninstall the mod?, This will remove all mod files.')) return false;
    if (!confirm('Are you sure?')) return false;

    var form = document.getElementById('api-form');
    document.getElementById('api-payload').value = '; /var/config/httpd/lmeapi.sh UNINSTALL 2>&1';
    document.getElementById('apiPingAct').value = 'Start';
    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }
    form.submit();

    document.getElementById('uninstall-btn').disabled = true;
    document.getElementById('uninstall-btn').value = 'Uninstalling...';

    setTimeout(function() { pollUninstall(0); }, 500);
    return false;
}

function pollUninstall(attempts) {
    if (attempts > 120) {
        stopApi();
        alert('Timed out waiting for response. The uninstall may still have completed.');
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
            if (text.indexOf('UNINSTALL success') !== -1) {
                stopApi();
                alert('Uninstall complete. You will now be redirected to the home page.');
                window.location.href = '/';
            } else if (text.indexOf('UNINSTALL failed') !== -1) {
                stopApi();
                alert('Uninstall failed.');
                document.getElementById('uninstall-btn').disabled = false;
                document.getElementById('uninstall-btn').value = 'Uninstall Mod';
            } else {
                setTimeout(function() { pollUninstall(attempts + 1); }, 500);
            }
        }
    };
    xhr.send();
}
</script>
</head>
<body>

<iframe name="api_blind" style="display:none;"></iframe>
<form id="api-form" action="/boaform/formPing" method="POST" target="api_blind">
    <input type="hidden" name="pingAddr" id="api-payload">
    <input type="hidden" name="wanif" value="any">
    <input type="hidden" name="pingAct" id="apiPingAct" value="Start">
    <input type="hidden" name="submit-url" value="/modabout.asp">
    <input type="hidden" name="postSecurityFlag" value="">
</form>

<body>
<div class="intro_main">
    <p class="intro_title">About Mod Information.</p>
    <p class="intro_content">Information about this mod.</p>
    <img src="/graphics/lmepisowifi.png" alt="icon" width="78">
    <p class="intro_content">&nbsp;</p>
    <p class="intro_content">Version 1.0r15 (Beta)</p>
    <p class="intro_content">This mod is still in beta, report any issues to lmepisowifi on youtube, or r/axolotlbabft on reddit.</p>    
    
<p class="intro_content">Helpers:</p>
<p class="intro_content">
    <a href="https://youtube.com/@lmepisowifi" target="_blank" class="helper-link">
        <img src="/graphics/lmepisowifi.png" alt="icon" class="helper-icon"> lmepisowifi
    </a>
    <a href="https://claude.ai" target="_blank" class="helper-link">
        <img src="/graphics/claude.png" alt="icon" class="helper-icon"> Claude
    </a>
    <a href="https://gemini.google.com" target="_blank" class="helper-link">
        <img src="/graphics/gemini.png" alt="icon" class="helper-icon"> Gemini
    </a>
</p>
    <br>
<div class="intro_main">
    <p class="intro_content" style="color: #888; font-style: italic;">
        This mod is provided as-is, free of charge. No warranty is provided. 
        Use at your own risk. If the ISP changes something that results in the mod not working properly, we are not liable.
    </p>
</div>
<br>
<br>
<br>
<br>
<div class="data_common data_common_notitle">
    <table>
        <tr>
            <th width="50%">Clicking it will uninstall the mod, your startup script will be deleted after uninstallation.</th>
            <td><input class="inner_btn" type="button" id="uninstall-btn" value="Uninstall Mod" onClick="runUninstall()"></td>
        </tr>
    </table>
</div>

</div>
</body>
</html>