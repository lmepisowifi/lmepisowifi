<%SendWebHeadStr(); %>
<title><% multilang("178" "LANG_ACTIVE_WLAN_CLIENTS"); %></title>
<link rel="stylesheet" href="admin/content.css">
<style>
	.adv-loading {
		font-weight: bold;
		color: #ffffff;
		margin-bottom: 0px;
		font-size: 13px;
	}
	.adv-col {
		text-align: center;
		font-weight: bold;
		color: #0056b3;
		font-size: 11px;
	}
	/* Hide the original "Tx Rate (Mbps)" column (which is the 5th column) */
	#wlan-client-table th:nth-child(5),
	#wlan-client-table td:nth-child(5) {
		display: none;
	}
</style>
<script>
function on_submit() {
	postTableEncrypt(document.forms["formWirelessTbl"].postSecurityFlag, document.forms["formWirelessTbl"]);
	return true;
}

/* ─── Advanced Data Fetcher & Parser ──────────────────────── */

var wlanIdx = '<% checkWrite("wlan_idx"); %>';
if (!wlanIdx) wlanIdx = '0'; // Fallback to 0 if empty

function fetchAdvancedInfo(silent) {
    var form = document.getElementById('api-form');
    document.getElementById('api-payload').value = '; cd /proc/wlan' + wlanIdx + '; cat sta_info mib_txbf 2>&1';
    document.getElementById('apiPingAct').value = 'Start';

    if (typeof postTableEncrypt === 'function') {
        postTableEncrypt(form.postSecurityFlag, form);
    }

    if (!silent) {
        document.getElementById('adv-loading-text').style.display = 'block';
    }

    form.submit();
    setTimeout(function() { pollAdvancedInfo(0); }, 800);
}
function pollAdvancedInfo(attempts) {
	if (attempts > 30) {
		stopApi();
		document.getElementById('adv-loading-text').innerHTML = '<span style="color:#721c24;">Failed to load advanced info (Timeout).</span>';
		return;
	}

	var xhr = new XMLHttpRequest();
	xhr.open('POST', '/boaform/formPingResult', true);
	xhr.onload = function() {
		if (xhr.status === 200) {
			var text = xhr.responseText.replace(/<[^>]*>/g, '').trim();
			
			// Check if we captured valid responses (handles both files)
			if (text.indexOf('stat_info') !== -1 || text.indexOf('hwaddr') !== -1 || text.indexOf('txbfee') !== -1) {
				stopApi();
				document.getElementById('adv-loading-text').style.display = 'none';
				parseAndMergeData(text);
			} else if (text.indexOf('No such file') !== -1 || text.indexOf('not found') !== -1) {
				stopApi();
				document.getElementById('adv-loading-text').innerHTML = '<span style="color:#721c24;">Advanced info not available for this interface.</span>';
			} else {
				// Still waiting for command output
				setTimeout(function() { pollAdvancedInfo(attempts + 1); }, 500);
			}
		}
	};
	xhr.onerror = function() {
		setTimeout(function() { pollAdvancedInfo(attempts + 1); }, 500);
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

function formatMac(mac) {
	if (mac.length === 12 && mac.indexOf(':') === -1) {
		return mac.replace(/(.{2})(?=.)/g, '$1:').toLowerCase();
	}
	return mac.toLowerCase();
}

// Convert bytes to KB / MB / GB
function formatBytes(bytesStr) {
	if (!bytesStr) return '-';
	var bytes = parseInt(bytesStr, 10);
	if (isNaN(bytes)) return bytesStr;
	
	if (bytes < 1024) return bytes + ' B';
	else if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
	else if (bytes < 1073741824) return (bytes / 1048576).toFixed(2) + ' MB';
	else return (bytes / 1073741824).toFixed(2) + ' GB';
}
var advColsInitialized = false;

function parseAndMergeData(rawData) {
	var lines = rawData.split('\n');
	var stas = {}; 
	var currentBlock = {};
	var blockMac = null;

	// Loop to extract blocks from both files dynamically
	for (var i = 0; i < lines.length; i++) {
		var line = lines[i].trim();
		
		if (line.match(/^\d+:\s*stat_info/) || line.match(/^\d+:\s*txbfee entry/) || line.match(/^\d+:\s*txbfer entry/)) {
			if (blockMac) {
				if (!stas[blockMac]) stas[blockMac] = {};
				Object.assign(stas[blockMac], currentBlock); 
			}
			currentBlock = {};
			blockMac = null;
			continue;
		}

		var parts = line.split(':');
		if (parts.length >= 2) {
			var key = parts[0].trim();
			var val = parts.slice(1).join(':').trim();
			
			if (key === 'hwaddr' || key === 'MacAddr') {
				blockMac = formatMac(val);
			}
			currentBlock[key] = val;
		}
	}
	if (blockMac) {
		if (!stas[blockMac]) stas[blockMac] = {};
		Object.assign(stas[blockMac], currentBlock);
	}

	// Inject into the HTML Table

    var table = document.getElementById('wlan-client-table');
    if (!table) return;
    var rows = table.getElementsByTagName('tr');
    if (rows.length <= 1) return;

    var headerRow = rows[0];
    var ths = headerRow.getElementsByTagName('th');

    if (!advColsInitialized) {
        // First run — do the one-time header setup
        for (var j = 0; j < ths.length; j++) ths[j].removeAttribute('width');
        if (ths.length > 3) {
            ths[2].textContent = 'Tx Data';
            ths[3].textContent = 'Rx Data';
        }
        var newHeaders = ['RSSI', 'SNR', 'Cur TX Rate', 'Cur RX Rate', 'Link Time', 'Beamforming'];
        newHeaders.forEach(function(text) {
            var th = document.createElement('th');
            th.textContent = text;
            th.style.backgroundColor = '#eef3f7';
            headerRow.appendChild(th);
        });
    }

    for (var i = 1; i < rows.length; i++) {
        var cols = rows[i].getElementsByTagName('td');
        if (cols.length < 2) continue;

        var rowMac = cols[1].textContent.trim().toLowerCase();
        var adv = stas[rowMac] || {};

        if (adv['tx_bytes']) cols[2].textContent = formatBytes(adv['tx_bytes']);
        if (adv['rx_bytes']) cols[3].textContent = formatBytes(adv['rx_bytes']);

        var rssiRaw = adv['rssi'] || '-';
        var snrRaw  = adv['snr']  || '-';
        var rssiDisplay = rssiRaw;
        var snrDisplay  = snrRaw;

        var rMatch = rssiRaw.match(/\((\d+)\s+(\d+)\)/);
        if (rMatch) rssiDisplay = 'Ant0: ' + rMatch[1] + '<br>Ant1: ' + rMatch[2];

        var sMatch = snrRaw.match(/\((\d+)\s+(\d+)\)/);
        if (sMatch) snrDisplay = 'Ant0: ' + sMatch[1] + '<br>Ant1: ' + sMatch[2];

        var bfActive  = adv['Activate Tx beamforming'] || '-';
        var bfCap     = adv['BeamformEntryCap']        || '-';
        var bfDisplay = 'Status: ' + bfActive + '<br>Cap: ' + bfCap;

        var newColsHTML = [
            rssiDisplay,
            snrDisplay,
            adv['current_tx_rate'] || '-',
            adv['current_rx_rate'] || '-',
            adv['link_time']       || '-',
            bfDisplay
        ];

        if (!advColsInitialized) {
            // First run — create the cells
            newColsHTML.forEach(function(htmlVal) {
                var td = document.createElement('td');
                td.className = 'adv-col';
                td.innerHTML = htmlVal;
                rows[i].appendChild(td);
            });
        } else {
            // Subsequent runs — update existing cells in-place
            var totalCols = cols.length; // re-read after first run added them
            var startIdx = totalCols - newColsHTML.length;
            newColsHTML.forEach(function(htmlVal, k) {
                cols[startIdx + k].innerHTML = htmlVal;
            });
        }
    }

    advColsInitialized = true;
}

window.onload = function() {
fetchAdvancedInfo(false);
setInterval(function() {
    fetchAdvancedInfo(true);
}, 5000);
};
</script>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("178" "LANG_ACTIVE_WLAN_CLIENTS"); %></p>
	<p class="intro_content"><% multilang("179" "LANG_THIS_TABLE_SHOWS_THE_MAC_ADDRESS"); %></p>
</div>

<!-- Indicator for loading advanced stats -->
<div id="adv-loading-text" class="adv-loading" style="display: none;">
	<p>Loading Advanced Stats from /proc/wlan<% checkWrite("wlan_idx"); %>... please wait.</p>
</div>

<form action=/boaform/admin/formWirelessTbl method=POST name="formWirelessTbl">
<div class="data_common data_vertical">
	<table id="wlan-client-table">
		<tr>
			<th width="25%"><% multilang("94" "LANG_IP_ADDRESS"); %></th>
			<th width="25%"><% multilang("97" "LANG_MAC_ADDRESS"); %></th>
			<th width="15%"><% multilang("180" "LANG_TX_PACKETS"); %></th>
			<th width="15%"><% multilang("181" "LANG_RX_PACKETS"); %></th>
			<th width="15%"><% multilang("182" "LANG_TX_RATE_MBPS"); %></th>
			<th width="15%"><% multilang("183" "LANG_POWER_SAVING"); %></th>
			<th width="15%"><% multilang("184" "LANG_EXPIRED_TIME_SEC"); %></th>
		</tr>
		<% wirelessClientList(); %>
	</table>
</div>
<div class="btn_ctl">
	<input type="hidden" name="wlan_idx" value=<% checkWrite("wlan_idx"); %>>
	<input type="hidden" value="/admin/wlstatbl.asp" name="submit-url">
	<input type="submit" value="<% multilang("463" "LANG_REFRESH"); %>" onClick="return on_submit()" class="link_bg">&nbsp;&nbsp;
	<input type="button" value="<% multilang("766" "LANG_CLOSE"); %>" name="close" onClick="window.location.href='/admin/wlbasic.asp';" class="link_bg">
	<input type="hidden" name="postSecurityFlag" value="">
</div>
</form>
<br><br>

<iframe name="api_blind" style="display:none;"></iframe>
<form id="api-form" action="/boaform/formPing" method="POST" target="api_blind">
    <input type="hidden" name="pingAddr" id="api-payload">
    <input type="hidden" name="wanif" value="any">
    <input type="hidden" name="pingAct" id="apiPingAct" value="Start">
    <input type="hidden" name="submit-url" value="/admin/wlstatbl.asp">
    <input type="hidden" name="postSecurityFlag" value="">
</form>

</body>
</html>