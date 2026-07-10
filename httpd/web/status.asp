<% SendWebHeadStr();%>
<title><% multilang("77" "LANG_DEVICE_STATUS"); %></title>
<script>
var getObj = null;
function modifyClick(url)
{
	var wide=600;
	var high=400;
	if (document.all)
		var xMax = screen.width, yMax = screen.height;
	else if (document.layers)
		var xMax = window.outerWidth, yMax = window.outerHeight;
	else
	   var xMax = 640, yMax=480;
	var xOffset = (xMax - wide)/2;
	var yOffset = (yMax - high)/3;
	var settings = 'width='+wide+',height='+high+',screenX='+xOffset+',screenY='+yOffset+',top='+yOffset+',left='+xOffset+', resizable=yes, toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes';
	window.open( url, 'Status_Modify', settings );
}

function disButton(id)
{
	getObj = document.getElementById(id);
	window.setTimeout("getObj.disabled=true", 100);
	return false;
}


function on_init()
{
	// Mason Yu for IPv6
	if (!<% checkWrite("IPv6Show"); %>) {
		if (document.getElementById)  // DOM3 = IE5, NS6
		{
			document.getElementById('ipv6DefaultGW').style.display = 'none';
		}
		else {
			if (document.layers == false) // IE4
			{
				document.all.ipv6DefaultGW.style.display = 'none';
			}
		}
	}
	return true;
}

function on_submit(obj)
{
	obj.isclick = 1;
	postTableEncrypt(document.status.postSecurityFlag, document.status);
	return true;
}

</script>
<style>
.progress-bar {
    display: flex !important;
    align-items: center !important;       /* Centers text vertically */
    justify-content: center !important;   /* Centers text horizontally */
     
}
.progress-bartxt {
    font-size: 10px;
    position: absolute;
    display: flex;
    align-items: center;
    justify-content: center;
}
.progress {
    background-color: rgba(255,255,255,0.1) !important;
    border: 1px solid rgba(255,255,255,0.15) !important;
}

.progress-bar-striped {
    background-image: none !important;
}

.progress-bar-animated, .active {
    animation: none !important;
}
</style>
</head>
<script>

function pollStats() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', '/admin/status.asp', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var parser = new DOMParser();
            var doc = parser.parseFromString(xhr.responseText, 'text/html');

            // Find all progress bars in the fetched page
            var newBars = doc.querySelectorAll('.progress-bar');
            var curBars = document.querySelectorAll('.progress-bar');

for (var i = 0; i < newBars.length && i < curBars.length; i++) {
    curBars[i].style.width = newBars[i].style.width;
    curBars[i].innerHTML = '<span class="progress-bartxt">' + newBars[i].textContent + '</span>';
    curBars[i].setAttribute('aria-valuenow', newBars[i].getAttribute('aria-valuenow'));
}
            var curBars = document.querySelectorAll('.progress-bar');
curBars.forEach(function(bar) {
    var pct = parseInt(bar.getAttribute('aria-valuenow'));
    bar.style.backgroundImage = 'none';
if (pct >= 75) {
    bar.style.backgroundColor = '#e74c3c'; // red
} else if (pct >= 50) {
    bar.style.backgroundColor = '#f1c40f'; // yellow
} else {
    bar.style.backgroundColor = '#4caf50'; // green
}
});
        }
        setTimeout(pollStats, 1500);
    };
    xhr.onerror = function() {
        setTimeout(pollStats, 1500);
    };
    xhr.send();
}

function pollWanConf() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', '/admin/status.asp', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var parser = new DOMParser();
            var doc = parser.parseFromString(xhr.responseText, 'text/html');
            var newTable = doc.getElementById('wanConfTable');
            var curTable = document.getElementById('wanConfTable');
            if (newTable && curTable) {
                curTable.innerHTML = newTable.innerHTML;
            }
        }
        setTimeout(pollWanConf, 5000);
    };
    xhr.onerror = function() {
        setTimeout(pollWanConf, 5000);
    };
    xhr.send();
}

setTimeout(pollWanConf, 5000);

function pollUptime() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', '/admin/status.asp', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var parser = new DOMParser();
            var doc = parser.parseFromString(xhr.responseText, 'text/html');
            var newUptime = doc.getElementById('uptimeVal');
            if (newUptime) {
                document.getElementById('uptimeVal').textContent = newUptime.textContent;
            }
        }
        setTimeout(pollUptime, 30000);
    };
    xhr.onerror = function() {
        setTimeout(pollUptime, 30000);
    };
    xhr.send();
}

setTimeout(pollUptime, 30000); 
setTimeout(pollStats, 1500);
// Color bars on initial load
// Color and Format bars on initial load
window.addEventListener('load', function() {
    document.querySelectorAll('.progress-bar').forEach(function(bar) {
        // 1. Apply the colors immediately
        var pct = parseInt(bar.getAttribute('aria-valuenow'));
        bar.style.backgroundImage = 'none';
        if (pct >= 75) {
            bar.style.backgroundColor = '#e74c3c'; 
        } else if (pct >= 50) {
            bar.style.backgroundColor = '#f1c40f'; 
        } else {
            bar.style.backgroundColor = '#4caf50'; 
        }

        // 2. APPLY TEXT FORMATTING IMMEDIATELY
        // This wraps the existing text in the span your CSS expects
        if (!bar.querySelector('.progress-bartxt')) {
            var existingText = bar.textContent;
            bar.innerHTML = '<span class="progress-bartxt">' + existingText + '</span>';
        }
    });
});

</script>
<body onLoad="on_init();">
<div class="intro_main ">
	<p class="intro_title"><% multilang("77" "LANG_DEVICE_STATUS"); %></p>
	<p class="intro_content"><% multilang("78" "LANG_PAGE_DESC_DEVICE_STATUS_SETTING"); %></p>
</div>

<form action=/boaform/admin/formStatus method=POST name="status2">
<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
			<p><% multilang("79" "LANG_SYSTEM"); %></p>
		<div class="column_title_right"></div>
	</div>

	<div class="data_common">
		<table>
			<tr>
				<th width=40%><% multilang("105" "LANG_DEVICE_NAME"); %></th>
				<td width=60%><% getInfo("name"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("81" "LANG_UPTIME"); %></th>
				<td width=60% id="uptimeVal"><% getInfo("uptime"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("2929" "LANG_HARDWARE_VERSION"); %></th>
				<td width=60%><% getInfo("hwVersion"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("84" "LANG_FIRMWARE_VERSION"); %></th>
				<td width=60%><% getInfo("fwVersion"); %></td>
			</tr>
			<tr>
				<th width=40%><% multilang("564" "LANG_SERIAL_NUMBER"); %></th>
				<td width=60%><% fmgpon_checkWrite("fmgpon_sn"); %></td>
			</tr>
			<% cpuUtility(); %>
			<% untimeout_utility(); %>
		</table>
	</div>	
</div>

<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
		<p><% multilang("6" "LANG_LAN"); %>&nbsp;<% multilang("262" "LANG_CONFIGURATION"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common">
	<table>
		<tr>
			<th width=40%><% multilang("94" "LANG_IP_ADDRESS"); %></th>
			<td width=60%><% getInfo("lan-ip"); %></td>
		</tr>
		<tr>
			<th width=40%><% multilang("95" "LANG_SUBNET_MASK"); %></th>
			<td width=60%><% getInfo("lan-subnet"); %></td>
		</tr>
		<% DHCPSrvStatus(); %>
		<tr>
			<th width=40%><% multilang("97" "LANG_MAC_ADDRESS"); %></th>
			<td width="60%" style="text-transform: uppercase"><% getInfo("elan-Mac"); %></td>
		</tr>
	</table>
	</div>
</div>

<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
		<p>WLAN Configuration</p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common">
	<table>
		<tr>
			<th width="40%">WLAN MAC Address</th>
			<td width="60%" style="text-transform: uppercase"><% getInfo("wlan-Mac"); %></td>
		</tr>
	</table>
	</div>
</div>
</form>


<form action=/boaform/admin/formStatus method=POST name="status">
<div class="column" <% checkWrite("bridge-only"); %>>
	<div class="column_title">
		<div class="column_title_left"></div>
		<p>IPv4&nbsp;<% multilang("11" "LANG_WAN"); %>&nbsp;<% multilang("262" "LANG_CONFIGURATION"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common data_vertical">
		<table>
<table id="wanConfTable">
    <% wanConfList(); %>
</table>
		</table>
	</div>
</div>
<% wan3GTable(); %>
<% wanPPTPTable(); %>
<% wanL2TPTable(); %>
<% wanIPIPTable(); %>
</form>
</body>
</html>


