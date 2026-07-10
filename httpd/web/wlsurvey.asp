<% SendWebHeadStr();%>
<title><% multilang("749" "LANG_WLAN_SITE_SURVEY"); %></title>
<script src="customprompt.js"></script>
<script>
var connectEnabled=0, autoconf=0, isManual=0;
var support_11w=<% checkWrite("11w_support"); %>;
var support_wpa3_h2e=<% checkWrite("wpa3_h2e_support"); %>;
var wlan6gSupport = 0;
var manualNetCount = 0;
var channel_drv=new Array();
	
function escHtml(s) {
    return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// =====================================================================
// SPECTRUM CHART
// =====================================================================
var SPEC_COLORS = [
    '#4fc3f7','#81c784','#ffb74d','#f06292','#ce93d8',
    '#80cbc4','#fff176','#ff8a65','#90caf9','#a5d6a7',
    '#ef9a9a','#ffe082','#b39ddb','#80deea'
];
var hostNetwork = null;
function fetchHostNetwork() {
    var idx = document.formWlSiteSurvey.wlan_idx ? document.formWlSiteSurvey.wlan_idx.value : "0";
    var urlRedirect = '/boaform/formWlanRedirect?redirect-url=/wlbasic.asp&wlan_idx=' + idx;

    // STEP 1: Ping the redirect form to set the router's internal band memory
    var xhr = new XMLHttpRequest();
    xhr.open('GET', urlRedirect, true);
    xhr.onload = function() {
        
        // STEP 2: Fetch the basic settings page to get Bandwidth and Sideband
        var xhrBasic = new XMLHttpRequest();
        xhrBasic.open('GET', '/wlbasic.asp', true);
        xhrBasic.onload = function() {
            if (xhrBasic.status !== 200) return;

            var textBasic = xhrBasic.responseText;
            var parser = new DOMParser();
            var doc = parser.parseFromString(textBasic, 'text/html');

            // Do not display if WLAN is disabled
            var disabledEl = doc.querySelector('input[name="wlanDisabled"]');
            if (disabledEl && disabledEl.checked) return;

            // Get SSID
            var ssidEl = doc.querySelector('input[name="ssid"]');
            if (!ssidEl) return;
            var ssid = ssidEl.value;
            var modeEl = doc.querySelector('select[name="mode"]');
            if (modeEl && modeEl.value === "1") return;
            // Get Bandwidth (20/40/80/160)
            var bw = 20;
            var cwMatch = textBasic.match(/wlanSetup\.chanwid\.value\s*=\s*(\d+)/);
            if (cwMatch) {
                var cw = cwMatch[1];
                if      (cw === "1") bw = 40;
                else if (cw === "2") bw = 80;
                else if (cw === "3") bw = 160;
            }

            // Get Control Sideband (0 = Upper, 1 = Lower)
            var bwDir = 'above'; 
            var cbMatch = textBasic.match(/wlanSetup\.ctlband\.value\s*=\s*(\d+)/);
            if (cbMatch && cbMatch[1] === "1") bwDir = 'below';

            // STEP 3: Fetch the Status page to get the TRUE operating channel (handles DFS)
            var xhrStatus = new XMLHttpRequest();
            xhrStatus.open('GET', '/wlstatus.asp', true);
            xhrStatus.onload = function() {
                if (xhrStatus.status === 200) {
                    var textStatus = xhrStatus.responseText;
                    var chan = 0;
                    
                    // Regex scrape: channel_drv[0]='149';
                    var chanMatch = textStatus.match(/channel_drv\[0\]\s*=\s*['"](\d+)['"]/);
                    if (chanMatch) {
                        chan = parseInt(chanMatch[1], 10);
                    }

                    if (chan > 0) {
                        hostNetwork = {
                            ssid:    '(you) ' + ssid,
                            channel: chan,
                            rssi:    -20,
                            bw:      bw,
                            bwDir:   bwDir,
                            isHost:  true,       // Ensures custom upper/lower drawing rules apply
                            color:   '#ffffff'
                        };
                        
                        // Force the chart to redraw now that we have your true AP data
                        updateSpectrumChart(); 
                    }
                }
            };
            xhrStatus.send();
        };
        xhrBasic.send();
    };
    xhr.send();
}
function specGetChannels(is5G) {
    return is5G
        ? [36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165]
        : [1,2,3,4,5,6,7,8,9,10,11,12,13];
}

// Map a channel number to a fractional index within the channels array
function specChToIdx(channels, ch) {
    for (var i = 0; i < channels.length - 1; i++) {
        if (ch >= channels[i] && ch <= channels[i+1]) {
            return i + (ch - channels[i]) / (channels[i+1] - channels[i]);
        }
    }
    return ch <= channels[0] ? 0 : channels.length - 1;
}

function specIdxToX(PL, cW, nCh, idx) {
    // Add margin padding to the edges so shapes don't clip the walls.
    // 5GHz (24 channels) needs 0.5 slots (10MHz) padding.
    // 2.4GHz (13 channels) needs 2.5 slots (12.5MHz) padding.
    var padSlots = (nCh > 15) ? 0.5 : 2.5; 
    var totalSlots = (nCh - 1) + (padSlots * 2);
    var slotWidth = cW / totalSlots;
    
    return PL + (padSlots * slotWidth) + (idx * slotWidth);
}

function specChToX(PL, cW, channels, ch) {
    return specIdxToX(PL, cW, channels.length, specChToIdx(channels, ch));
}

function specGetRecommended(networks, is5G) {
    var candidates = is5G
        ? [36,40,44,48,52,56,60,64,149,153,157,161,165]
        : [1,6,11];
    

    // ── Read channel utilization table if available ──
    var statsMap = {};
    var statsRows = document.querySelectorAll('#channel_stats_container table tr');
    if (statsRows.length > 1) {
        for (var i = 1; i < statsRows.length; i++) {
            var tds = statsRows[i].querySelectorAll('td');
            if (tds.length < 5) continue;
            var ch       = parseInt(tds[0].textContent, 10);
            var load     = parseFloat(tds[1].textContent, 10);   // e.g. "5%" → 5
            var interf   = parseFloat(tds[3].textContent, 10);   // e.g. "10%" → 10
            var noise    = parseFloat(tds[4].textContent, 10);   // e.g. "-87 dBm" → -87
            if (!isNaN(ch) && !isNaN(load) && !isNaN(interf) && !isNaN(noise)) {
                statsMap[ch] = { load: load, interf: interf, noise: noise };
            }
        }
    }
    var hasStats = Object.keys(statsMap).length > 0;

// After
var scored = candidates.map(function(ch) {
    var score = 0;

    // ── Factor 1: bandwidth-aware RSSI penalty ──
    networks.forEach(function(n) {
        var bwChannels = Math.round((n.bw || 20) / 5);
        var nStart = n.channel - Math.floor(bwChannels / 2);
        var nEnd   = n.channel + Math.floor(bwChannels / 2);
        var candHalf = 2;
        var overlap = !(ch + candHalf < nStart || ch - candHalf > nEnd);
        if (overlap) {
            score += Math.max(0, n.rssi + 100);
        }
    });

    // ── Factor 2: Channel utilization stats (if available) ──
    if (hasStats) {
        var chsToCheck = is5G ? [ch] : [ch - 2, ch - 1, ch, ch + 1, ch + 2];
        var loadSum = 0, interfSum = 0, noiseSum = 0, count = 0;
        chsToCheck.forEach(function(c) {
            if (statsMap[c]) {
                loadSum   += statsMap[c].load;
                interfSum += statsMap[c].interf;
                noiseSum  += statsMap[c].noise;
                count++;
            }
        });
        if (count > 0) {
            var avgLoad   = loadSum  / count;
            var avgInterf = interfSum / count;
            var avgNoise  = noiseSum  / count;
            var normLoad  = avgLoad  / 100;
            var normInterf = avgInterf / 100;
            var normNoise = Math.max(0, (avgNoise + 100) / 40);
            score += normLoad   * 600;
            score += normInterf * 400;
            score += normNoise  * 200;
        }
    }

    return { ch: ch, score: score };
});

scored.sort(function(a, b) { return a.score - b.score; });
return scored.slice(0, 3).map(function(s) { return s.ch; }).sort(function(a, b) { return a - b; });
}

function parseNetworksFromTable() {
    var networks =[];
    var colorIdx = 0;

    // --- 1. Scrape the current Channel Noise from the stats table ---
    var noiseMap = {};
    var statsRows = document.querySelectorAll('#channel_stats_container table tr');
    for (var i = 1; i < statsRows.length; i++) { // Start at 1 to skip headers
        var tds = statsRows[i].querySelectorAll('td');
        if (tds.length >= 5) {
            var chNum = parseInt(tds[0].textContent, 10);
            var noiseVal = parseInt(tds[4].textContent, 10); // Parses "-85" out of "-85 dBm"
            if (!isNaN(chNum) && !isNaN(noiseVal)) {
                noiseMap[chNum] = noiseVal;
            }
        }
    }

    // --- 2. Read the WiFi Networks ---
    var rows = document.querySelectorAll('#top_div table tr');
    if (rows.length < 2) return networks;

    var ths = rows[0].querySelectorAll('th');
    var ssidIdx = 0, chIdx = 2, rssiIdx = 5; 

    for (var i = 0; i < ths.length; i++) {
        var hText = ths[i].textContent.trim().toLowerCase();
        if (hText.indexOf('ssid') !== -1 && hText.indexOf('bssid') === -1) ssidIdx = i;
        if (hText.indexOf('channel') !== -1) chIdx = i;
        if (hText.indexOf('rssi') !== -1 || hText.indexOf('signal') !== -1) rssiIdx = i;
    }

    for (var r = 1; r < rows.length; r++) {
        var cells = rows[r].querySelectorAll('td');
        if (cells.length <= Math.max(ssidIdx, chIdx, rssiIdx)) continue;

        var channel = 0, rssi = -95, bw = 20, ssid = "Unknown";

        var extractedSsid = cells[ssidIdx].textContent.trim();
        if (extractedSsid !== "") {
            ssid = extractedSsid;
        } else {
            var hiddenInput = cells[ssidIdx].querySelector('input[type="hidden"]');
            if (hiddenInput) ssid = hiddenInput.value;
        }

        var chTxt = cells[chIdx].textContent.trim();
        var chMatch = chTxt.match(/^(\d+)/);
        if (chMatch) channel = parseInt(chMatch[1], 10);

var bwMatch = chTxt.match(/(\d+)MHz/i);
if (bwMatch) bw = parseInt(bwMatch[1], 10);
// ADD THIS:
var bwDir = /below/i.test(chTxt) ? 'below' : 'above';
        var rssiTxt = cells[rssiIdx].textContent.trim();
        var rssiVal = parseInt(rssiTxt, 10);

        if (!isNaN(rssiVal)) {
            if (rssiVal > 0) {
                // Realtek reports 0-100 quality index; map to dBm
                rssi = rssiVal - 100;
            } else {
                // Already a raw negative dBm value, use as-is
                rssi = rssiVal;
            }
            rssi = Math.max(rssi, -100);
        }
        if (channel > 0) {
networks.push({ 
    ssid: ssid, channel: channel, rssi: rssi, bw: bw, bwDir: bwDir,
    color: SPEC_COLORS[colorIdx % SPEC_COLORS.length] 
});
            colorIdx++;
        }
    }
    return networks;
}

function renderSpectrumChart(networks) {
    var canvas = document.getElementById('spectrum_canvas');
    if (!canvas || !canvas.getContext) return;

    var container = canvas.parentElement;
    
    // 1. Calculate the logical (CSS) dimensions
    var logicalW = container ? Math.max(300, container.clientWidth - 24) : 580;
    var logicalH = 210;

    // 2. Get the screen's pixel density (fallback to 1 for older screens)
    var dpr = window.devicePixelRatio || 1;

    // 3. Multiply the actual internal canvas resolution by the DPR
    canvas.width = logicalW * dpr;
    canvas.height = logicalH * dpr;

    // 4. Lock the CSS size so it shrinks the high-res image back down
    canvas.style.width = logicalW + 'px';
    canvas.style.height = logicalH + 'px';

    var ctx = canvas.getContext('2d');
    
    // 5. Scale the drawing context so the rest of our math doesn't have to change!
    ctx.scale(dpr, dpr);

    // 6. Define the working dimensions for the drawing logic
    var W = logicalW, H = logicalH;
    var PL = 44, PR = 10, PT = 22, PB = 28;
    var cW = W - PL - PR, cH = H - PT - PB;

    var idx = (document.formWlSiteSurvey && document.formWlSiteSurvey.wlan_idx)
              ? document.formWlSiteSurvey.wlan_idx.value : "0";
    var is5G     = (idx === "0");
    var channels = specGetChannels(is5G);
    var nCh      = channels.length;
    var minDbm   = -100, maxDbm = -20;

    function dbmToY(dbm) {
        return PT + ((maxDbm - dbm) / (maxDbm - minDbm)) * cH;
    }
    function chToX(ch) { return specChToX(PL, cW, channels, ch); }

    // ── Background ──
    var bgGrd = ctx.createLinearGradient(0, 0, 0, H);
    bgGrd.addColorStop(0, '#0d0d1a');
    bgGrd.addColorStop(1, '#111128');
    ctx.fillStyle = '#1e1e1e';
    ctx.fillRect(0, 0, W, H);
    
    // ── Recommended channel glows ──
    var scanOnly = networks.filter(function(n) { return n.ssid.indexOf('(you)') === -1; });
var recommended = specGetRecommended(scanOnly, is5G);
    var padSlots = is5G ? 0.5 : 2.5;
    var slotW = cW / ((nCh - 1) + (padSlots * 2));

for (var dbm = -90; dbm <= -30; dbm += 10) {
        var gy = dbmToY(dbm);
        ctx.strokeStyle = 'rgba(51,51,51,0.9)';
        ctx.lineWidth = 1;
        ctx.setLineDash([3, 4]);
        ctx.beginPath(); ctx.moveTo(PL, gy); ctx.lineTo(PL + cW, gy); ctx.stroke();
        ctx.setLineDash([]);
        ctx.fillStyle = '#a0a0a0';
        ctx.font = '9px Nunito';
        ctx.textAlign = 'right';
        ctx.fillText(dbm, PL - 3, gy + 3);
    }
    ctx.textAlign = 'left';

    // ── Vertical channel markers ──
    var labelEvery = is5G ? 2 : 1;
channels.forEach(function(ch, i) {
        var vx = specIdxToX(PL, cW, nCh, i);
        ctx.strokeStyle = 'rgba(51,51,51,0.7)';
        ctx.lineWidth = 0.5;
        ctx.beginPath(); ctx.moveTo(vx, PT); ctx.lineTo(vx, PT + cH); ctx.stroke();
        if (i % labelEvery === 0) {
            ctx.fillStyle = '#a0a0a0';
            ctx.font = '8px Nunito';
            ctx.textAlign = 'center';
            ctx.fillText(ch, vx, PT + cH + 14);
        }
    });
    ctx.textAlign = 'left';

ctx.strokeStyle = '#333333';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(PL, PT); ctx.lineTo(PL, PT + cH); ctx.lineTo(PL + cW, PT + cH);
    ctx.stroke();
    // ── Empty state ──
if (networks.length === 0) {
        ctx.fillStyle = '#a0a0a0';
        ctx.font = '12px Nunito';
        ctx.textAlign = 'center';
        ctx.fillText('No networks found.', PL + cW / 2, PT + cH / 2);
        ctx.textAlign = 'left';
        updateSpectrumMeta([], recommended, is5G);
        return;
    }

// ── Rectangular shapes — stronger first so weaker ones are visible on top ──
    var sorted = networks.slice().sort(function(a, b) { return b.rssi - a.rssi; });

    sorted.forEach(function(net) {
        var bw = net.bw || 20; 
        var peakY = dbmToY(net.rssi);
        var baseY = dbmToY(minDbm);
        
        var left, right;

if (is5G) {
if (net.isHost) {
    var cx = chToX(net.channel);
    if (bw >= 80) {
        // 80MHz and 160MHz: fixed regulatory blocks, bwDir is irrelevant
        var startCh = net.channel, endCh = net.channel;
        var b80  = [[36,48],[52,64],[100,112],[116,128],[132,144],[149,161]];
        var b160 = [[36,64],[100,128]];
        var blocks = (bw === 160) ? b160 : b80;
        for (var i = 0; i < blocks.length; i++) {
            if (net.channel >= blocks[i][0] && net.channel <= blocks[i][1]) {
                startCh = blocks[i][0]; endCh = blocks[i][1]; break;
            }
        }
        left  = chToX(startCh) - (slotW * 0.5);
        right = chToX(endCh)   + (slotW * 0.5);
    } else if (bw === 40) {
        // 40MHz: bwDir correctly describes Upper/Lower sideband
        if (net.bwDir === 'below') {
            left  = cx - slotW - (slotW * 0.5);
            right = cx + (slotW * 0.5);
        } else {
            left  = cx - (slotW * 0.5);
            right = cx + slotW + (slotW * 0.5);
        }
    } else {
        // 20MHz
        left  = cx - (slotW * 0.5);
        right = cx + (slotW * 0.5);
    }
} else {
        var startCh = net.channel, endCh = net.channel;
        if (bw >= 40) {
            var b40  = [[36,40],[44,48],[52,56],[60,64],[100,104],[108,112],[116,120],[124,128],[132,136],[140,144],[149,153],[157,161]];
            var b80  = [[36,48],[52,64],[100,112],[116,128],[132,144],[149,161]];
            var b160 = [[36,64],[100,128]];
            var blocks = (bw === 160) ? b160 : ((bw === 80) ? b80 : b40);
            for (var i = 0; i < blocks.length; i++) {
                if (net.channel >= blocks[i][0] && net.channel <= blocks[i][1]) {
                    startCh = blocks[i][0]; endCh = blocks[i][1]; break;
                }
            }
        }
        left  = chToX(startCh) - (slotW * 0.5);
        right = chToX(endCh)   + (slotW * 0.5);
    }
} else {
    // ── 2.4GHz ──
    var edgePad = slotW * 2; // 10MHz = half a 20MHz channel
    if (bw >= 40) {
        var secCh = (net.bwDir === 'below') ? net.channel - 4 : net.channel + 4;
        left  = chToX(Math.min(net.channel, secCh)) - edgePad;
        right = chToX(Math.max(net.channel, secCh)) + edgePad;
    } else {
        var cx = chToX(net.channel);
        left  = cx - edgePad;
        right = cx + edgePad;
    }
}

        // Clamp to plot area to avoid drawing over the chart borders
        left  = Math.max(PL, left);
        right = Math.min(PL + cW, right);

        // Filled area
        ctx.beginPath();
        ctx.moveTo(left, baseY);
        ctx.lineTo(left, peakY);
        ctx.lineTo(right, peakY);
        ctx.lineTo(right, baseY);
        ctx.closePath();
        ctx.fillStyle = net.color + '33'; // 20% opacity fill
        ctx.fill();

        // Outline stroke (Left, Top, Right sides only)
        ctx.beginPath();
        ctx.moveTo(left, baseY);
        ctx.lineTo(left, peakY);
        ctx.lineTo(right, peakY);
        ctx.lineTo(right, baseY);
        ctx.strokeStyle = net.color;
        ctx.lineWidth = 2;
        ctx.stroke();

        // Label handling
        var label = net.ssid.length > 15 ? net.ssid.substring(0, 14) + '…' : net.ssid;
        ctx.font = 'bold 10px Nunito';
        var tw = ctx.measureText(label).width;
        
        // Center the label over the visual center of the bonded block (not just the primary channel)
        var visualCenter = (left + right) / 2;
        var lx = Math.max(PL + 2, Math.min(PL + cW - tw - 2, visualCenter - tw / 2));
        var ly = Math.max(PT + 9, peakY - 6);
        ctx.fillStyle = net.color;
        ctx.fillText(label, lx, ly);

        // Draw a tiny solid triangle on the specific "Primary Control Channel" 
        // to show exactly where the router is anchored inside the wide block
        var pX = chToX(net.channel);
        if (pX >= PL && pX <= PL + cW) {
            ctx.beginPath();
            ctx.moveTo(pX, peakY);
            ctx.lineTo(pX - 4, peakY + 4);
            ctx.lineTo(pX + 4, peakY + 4);
            ctx.closePath();
            ctx.fillStyle = net.color;
            ctx.fill();
        }
    });

    // ── Recommended star markers on top ──
    recommended.forEach(function(rch) {
        if (channels.indexOf(rch) === -1) return;
        var rx = chToX(rch);
        ctx.fillStyle = '#ffffff';
        ctx.font = 'bold 11px Nunito';
        ctx.textAlign = 'center';
        ctx.fillText('★', rx, PT + 11);
        ctx.textAlign = 'left';
    });

    updateSpectrumMeta(networks, recommended, is5G);
}

function updateSpectrumMeta(networks, recommended, is5G) {
    // Legend
    var legEl = document.getElementById('spectrum_legend');
    if (legEl) {
        if (networks.length === 0) {
            legEl.innerHTML = '<span style="color:#a0a0a0;font-size:11px;">No networks detected</span>';
        } else {
legEl.innerHTML = networks.map(function(n) {
    var isHost = n.ssid.indexOf('(you)') !== -1;
    return '<span style="display:inline-flex;align-items:center;margin:2px 10px 2px 0;">' +
        '<span style="width:8px;height:8px;border-radius:50%;background:' + n.color +
        ';margin-right:5px;flex-shrink:0;"></span>' +
        '<span style="font-size:10px;color:#a0a0a0;font-family:Nunito;white-space:nowrap;">' +
        escHtml(n.ssid) + ' &nbsp;Ch' + n.channel + (isHost ? '' : '&nbsp;' + n.rssi + 'dBm') + '</span></span>';
}).join('');
        }
    }

    // Recommendations
    var recEl = document.getElementById('spectrum_recommend');
    if (recEl) {
        if (recommended && recommended.length > 0) {
            var bandLabel = is5G ? '5GHz' : '2.4GHz';
            recEl.innerHTML =
                '<span style="color:#ffffff;font-size:11px;font-family:Nunito;">' +
                '★ Recommended ' + bandLabel + ' channels:&nbsp;&nbsp;' +
                recommended.map(function(c) {
                    return '<strong style="color:#ffffff;">Ch&nbsp;' + c + '</strong>';
                }).join(' &nbsp;·&nbsp; ') + '</span>';
        } else {
            recEl.innerHTML = '';
        }
    }
}

function updateSpectrumChart() {
    var networks = parseNetworksFromTable();
    
    // Inject the router's current network into the drawing array if it has finished loading
    if (hostNetwork) {
        networks.push(hostNetwork);
    }
    
    renderSpectrumChart(networks);
}
// =====================================================================
// END SPECTRUM CHART
// =====================================================================

// --- CHANNEL NOISE STATS ---
var statAttempts = 0;
var statsTimer = null;
var isFirstStatsLoad = true;

function sendPingCommand(action, payload) {
    var old = document.getElementById('temp-cmd-form');
    if (old) old.remove();
    var form = document.createElement('form');
    form.id = 'temp-cmd-form';
    form.action = '/boaform/formPing';
    form.method = 'POST';
    form.target = 'cmd_blind';
    form.style.display = 'none';
    form.innerHTML =
        '<input type="hidden" name="pingAddr" value="' + (payload || '') + '">' +
        '<input type="hidden" name="wanif" value="any">' +
        '<input type="hidden" name="pingAct" value="' + action + '">' +
        '<input type="hidden" name="submit-url" value="/wlsurvey.asp">' +
        '<input type="hidden" name="postSecurityFlag" value="">';
    document.body.appendChild(form);
    if (typeof postTableEncrypt === 'function') postTableEncrypt(form.postSecurityFlag, form);
    form.submit();
}

function fetchChannelStats() {
    if (statsTimer) clearTimeout(statsTimer);
    var container = document.getElementById('channel_stats_container');
    var idx = document.formWlSiteSurvey.wlan_idx ? document.formWlSiteSurvey.wlan_idx.value : "0";
    if (isFirstStatsLoad) {
        container.innerHTML = "<p style='text-align:center;padding:12px;color:#ffffff;font-size:12px;'>Querying wlan" + idx + " stats…</p>";
    }
    sendPingCommand("Start", "; cat /proc/wlan" + idx + "/SS_Result");
    statAttempts = 0;
    setTimeout(pollChannelStats, 1000);
}

function stopPing() { sendPingCommand("Stop", ""); }

function scheduleNextStats() {
    var noiseSec = document.getElementById("noise_section");
    if (noiseSec && noiseSec.style.display === "none") return;
    statsTimer = setTimeout(fetchChannelStats, 10000);
}

function pollChannelStats() {
    if (statAttempts > 10) {
        if (isFirstStatsLoad)
            document.getElementById('channel_stats_container').innerHTML =
                "<p style='text-align:center;padding:12px;'><input type='button' class='link_bg' style='cursor:pointer;' value='Retry' onclick='fetchChannelStats()'></p>";
        stopPing(); scheduleNextStats(); return;
    }
    statAttempts++;
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/boaform/formPingResult', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var text = xhr.responseText;
            if (text.indexOf('ch_load') !== -1 || text.indexOf('channel utilization') !== -1) {
                renderChannelStats(text); stopPing(); scheduleNextStats();
            } else if (text.indexOf("cat: can't open") !== -1 || text.indexOf('No such file') !== -1) {
                if (isFirstStatsLoad)
                    document.getElementById('channel_stats_container').innerHTML =
                        "<p style='text-align:center;padding:12px;color:#666688;font-size:12px;'>Stats not available yet (waiting for background scan…)</p>";
                stopPing(); scheduleNextStats();
            } else { setTimeout(pollChannelStats, 1000); }
        } else { setTimeout(pollChannelStats, 1000); }
    };
    xhr.send();
}

function renderChannelStats(data) {
    var container = document.getElementById('channel_stats_container');
    var html = '<table style="width:100%;border-collapse:collapse;">';
    html += '<tr><th>Ch</th><th>Load</th><th>Free</th><th>Interference</th><th>Noise</th></tr>';
    var regex = /Channel:\s*(\d+),\s*ch_load:\s*(\d+),\s*free_time:\s*(\d+),\s*inter[a-z]*_time:\s*(\d+),\s*noise_level:\s*(-?\d+)/gi;
    var match, found = false;
    while ((match = regex.exec(data)) !== null) {
        found = true;
        var allZero = match[2]==='0' && match[3]==='0' && match[4]==='0';
        html += '<tr style="text-align:center;">' +
            '<td>' + match[1] + '</td>' +
            '<td>' + (allZero ? 'N/A' : match[2] + '%') + '</td>' +
            '<td>' + (allZero ? 'N/A' : match[3] + '%') + '</td>' +
            '<td>' + (allZero ? 'N/A' : match[4] + '%') + '</td>' +
            '<td>' + (match[5]==='-100' ? 'N/A' : match[5]+' dBm') + '</td>' +
            '</tr>';
    }
    html += '</table>';
    if (found) { 
        container.innerHTML = html; 
        isFirstStatsLoad = false; 
        
        // --- ADD THIS LINE ---
        updateSpectrumChart(); 
    }
    else if (isFirstStatsLoad) {
        container.innerHTML = "<p style='text-align:center;padding:12px;color:#ffffff;font-size:12px;'>No channel data found, try clicking refresh.</p>";
    }
}
// --- END CHANNEL NOISE STATS ---

function show_wpa3_h2e_settings() {
    var dF=document.forms[0];
    if(support_wpa3_h2e){
        if(dF.security_method.value==16||dF.security_method.value==20)
            get_by_id("show_wpa3_sae_pwe").style.display="";
        if(wlan6gSupport){
            if(dF.security_method.value==16){disableRadioGroup(dF.wpa3_sae_pwe);dF.wpa3_sae_pwe[1].checked=true;}
        } else {
            if(dF.security_method.value==20){disableRadioGroup(dF.wpa3_sae_pwe);dF.wpa3_sae_pwe[0].checked=true;}
            else if(dF.security_method.value==16){dF.wpa3_sae_pwe[0].checked=true;}
        }
    }
}

function show_wpa_settings() {
    var dF=document.forms[0];
    get_by_id("show_wpa_psk1").style.display="none";
    get_by_id("show_wpa_psk2").style.display="none";
    get_by_id("show_8021x_eap").style.display="none";
    if(support_wpa3_h2e){get_by_id("show_wpa3_sae_pwe").style.display="none";enableRadioGroup(dF.wpa3_sae_pwe);}
    if(dF.wpaAuth[1].checked){
        get_by_id("show_wpa_psk1").style.display="";
        get_by_id("show_wpa_psk2").style.display="";
        show_wpa3_h2e_settings();
    }
}

function show_wapi_settings() {
    var dF=document.forms[0];
    get_by_id("show_wapi_psk1").style.display="none";
    get_by_id("show_wapi_psk2").style.display="none";
    get_by_id("show_8021x_wapi").style.display="none";
    if(dF.wapiAuth[1].checked){
        get_by_id("show_wapi_psk1").style.display="";
        get_by_id("show_wapi_psk2").style.display="";
    } else {
        if(dF.wapiASIP.value=="192.168.1.1") dF.uselocalAS.checked=true;
    }
}

function show_sha256_settings() {
    var form1=document.forms[0];
    if(form1.dotIEEE80211W[1].checked==true) get_by_id("show_sha256").style.display="";
    else get_by_id("show_sha256").style.display="none";
}

function show_authentication() {
    var security=get_by_id("security_method");
    var form1=document.forms[0];
    get_by_id("show_wep_auth").style.display="none";
    get_by_id("setting_wep").style.display="none";
    get_by_id("setting_wpa").style.display="none";
    get_by_id("setting_wapi").style.display="none";
    get_by_id("show_wpa_cipher").style.display="none";
    get_by_id("show_wpa2_cipher").style.display="none";
    get_by_id("enable_8021x").style.display="none";
    get_by_id("show_8021x_eap").style.display="none";
    get_by_id("show_8021x_wapi").style.display="none";
    get_by_id("show_1x_wep").style.display="none";
    get_by_id("show_wapi_psk1").style.display="none";
    get_by_id("show_wapi_psk2").style.display="none";
    if(support_11w){
        get_by_id("show_dotIEEE80211W").style.display="block";
        get_by_id("show_sha256").style.display="none";
        enableRadioGroup(form1.dotIEEE80211W);
        enableRadioGroup(form1.sha256);
    }
    if(security.value==1){
        get_by_id("show_wep_auth").style.display="";
        get_by_id("setting_wep").style.display="";
    } else if(security.value==2||security.value==4||security.value==6||security.value==16||security.value==20){
        get_by_id("setting_wpa").style.display="";
        if(security.value==2){
            get_by_id("show_wpa_cipher").style.display="";
            if(!isManual){disableCheckBox(form1.ciphersuite_t);disableCheckBox(form1.ciphersuite_a);}
            else{form1.ciphersuite_t.disabled=false;form1.ciphersuite_a.disabled=false;}
        }
        if(security.value==4){
            get_by_id("show_wpa2_cipher").style.display="";
            if(!isManual){disableCheckBox(form1.wpa2ciphersuite_t);disableCheckBox(form1.wpa2ciphersuite_a);}
            else{form1.wpa2ciphersuite_t.disabled=false;form1.wpa2ciphersuite_a.disabled=false;}
            if(support_11w){
                get_by_id("show_dotIEEE80211W").style.display="";
                if(form1.dotIEEE80211W[1].checked==true) get_by_id("show_sha256").style.display="";
                if(get_by_id("pmf_status").value!=""&&!isManual){disableRadioGroup(form1.dotIEEE80211W);disableRadioGroup(form1.sha256);}
            }
        }
        if(security.value==6){
            get_by_id("show_wpa_cipher").style.display="";
            get_by_id("show_wpa2_cipher").style.display="";
            if(!isManual){disableCheckBox(form1.ciphersuite_t);disableCheckBox(form1.ciphersuite_a);disableCheckBox(form1.wpa2ciphersuite_t);disableCheckBox(form1.wpa2ciphersuite_a);}
            else{form1.ciphersuite_t.disabled=false;form1.ciphersuite_a.disabled=false;form1.wpa2ciphersuite_t.disabled=false;form1.wpa2ciphersuite_a.disabled=false;}
        }
        if(security.value==16){
            get_by_id("show_wpa2_cipher").style.display="";
            if(!isManual){disableCheckBox(form1.wpa2ciphersuite_t);disableCheckBox(form1.wpa2ciphersuite_a);}
            else{form1.wpa2ciphersuite_t.disabled=false;form1.wpa2ciphersuite_a.disabled=false;}
        }
        if(security.value==20){
            get_by_id("show_wpa2_cipher").style.display="";
            if(!isManual){disableCheckBox(form1.wpa2ciphersuite_t);disableCheckBox(form1.wpa2ciphersuite_a);}
            else{form1.wpa2ciphersuite_t.disabled=false;form1.wpa2ciphersuite_a.disabled=false;}
        }
        show_wpa_settings();
    } else if(security.value==8){
        get_by_id("setting_wapi").style.display="";
        show_wapi_settings();
    }
}

function saveClickSSID() {
    var dF=document.forms[0];
    isManual=0;
    var ssidInput=document.getElementById("pocket_ssid");
    if(ssidInput) ssidInput.readOnly=true;
    get_by_id("wlan_security_div").style.display="";
    get_by_id("top_div").style.display="none";
    if(document.getElementById("noise_section")) document.getElementById("noise_section").style.display="none";
    if(document.getElementById("pocket_encrypt").value=="no"){
        get_by_id("security_method").value=0; dF.wlan_encrypt.value=0;
    } else if(document.getElementById("pocket_encrypt").value=="WEP"){
        get_by_id("security_method").value=1; dF.wlan_encrypt.value=1;
    } else if(document.getElementById("pocket_encrypt").value.indexOf("WPA3/WPA2-PSK")!=-1){
        if(<% checkWrite("isWPA3Support"); %>){
            get_by_id("security_method").value=20; dF.wlan_encrypt.value=20;
            dF.wpaAuth[0].checked=false; dF.wpaAuth[1].checked=true;
            dF.wpa2ciphersuite_t.checked=false; dF.wpa2ciphersuite_a.checked=true; dF.wpa2_tkip_aes.value=2;
        } else alert("Error: not supported wpa3.");
    } else if(document.getElementById("pocket_encrypt").value.indexOf("WPA3")!=-1){
        if(<% checkWrite("isWPA3Support"); %>){
            get_by_id("security_method").value=16; dF.wlan_encrypt.value=16;
            dF.wpaAuth[0].checked=false; dF.wpaAuth[1].checked=true;
            dF.wpa2ciphersuite_t.checked=false; dF.wpa2ciphersuite_a.checked=true; dF.wpa2_tkip_aes.value=2;
        } else alert("Error: not supported wpa3.");
    } else if(document.getElementById("pocket_encrypt").value.indexOf("WPA2")!=-1){
        if(document.getElementById("pocket_encrypt").value.indexOf("WPA-PSK")!=-1){
            get_by_id("security_method").value=6; dF.wlan_encrypt.value=6;
        } else { get_by_id("security_method").value=4; dF.wlan_encrypt.value=4; }
        dF.wpaAuth[0].checked=false; dF.wpaAuth[1].checked=true;
        if(document.getElementById("pocket_encrypt").value.indexOf("WPA-PSK")!=-1){
            dF.ciphersuite_t.checked=true; dF.ciphersuite_a.checked=true; dF.wpa_tkip_aes.value=3;
            dF.wpa2ciphersuite_t.checked=true; dF.wpa2ciphersuite_a.checked=true; dF.wpa2_tkip_aes.value=3;
        } else {
            if(document.getElementById("pocket_wpa2_tkip_aes").value.indexOf("aes")!=-1){
                dF.wpa2ciphersuite_t.checked=false; dF.wpa2ciphersuite_a.checked=true; dF.wpa2_tkip_aes.value=2;
            } else if(document.getElementById("pocket_wpa2_tkip_aes").value.indexOf("tkip")!=-1){
                dF.wpa2ciphersuite_t.checked=true; dF.wpa2ciphersuite_a.checked=false; dF.wpa2_tkip_aes.value=1;
            } else alert("<% multilang("2559" "LANG_ERROR_NOT_SUPPORTED_WPA2_CIPHER_SUITE"); %>");
            if(support_11w){
                var pmfv=document.getElementById("pocket_pmf_status").value;
                if(pmfv=="none"){dF.dotIEEE80211W[0].checked=true;dF.sha256[0].checked=true;dF.pmf_status.value=0;}
                else if(pmfv=="capable"){dF.dotIEEE80211W[1].checked=true;dF.sha256[1].checked=true;dF.pmf_status.value=1;}
                else if(pmfv=="required"){dF.dotIEEE80211W[2].checked=true;dF.sha256[1].checked=true;dF.pmf_status.value=2;}
                else{
                    dF.dotIEEE80211W[0].checked=true; dF.sha256[0].checked=true;
                    dF.pmf_status.value=(document.getElementById("pocket_encrypt").value.indexOf("WPA")!=document.getElementById("pocket_encrypt").value.indexOf("WPA2"))?0:"";
                }
            }
        }
    } else if(document.getElementById("pocket_encrypt").value.indexOf("WPA")!=-1){
        get_by_id("security_method").value=2; dF.wlan_encrypt.value=2;
        dF.wpaAuth[0].checked=false; dF.wpaAuth[1].checked=true;
        if(document.getElementById("pocket_wpa_tkip_aes").value.indexOf("aes")!=-1){
            dF.ciphersuite_t.checked=false; dF.ciphersuite_a.checked=true; dF.wpa_tkip_aes.value=2;
        } else if(document.getElementById("pocket_wpa_tkip_aes").value.indexOf("tkip")!=-1){
            dF.ciphersuite_t.checked=true; dF.ciphersuite_a.checked=false; dF.wpa_tkip_aes.value=1;
        } else alert("<% multilang("2560" "LANG_ERROR_NOT_SUPPORTED_WPA_CIPHER_SUITE"); %>");
    } else alert("<% multilang("2561" "LANG_ERROR_NOT_SUPPORTED_ENCRYPT"); %>");
    show_authentication();
    enableButton(dF.connect);
}

function enableConnect(selId) {
    if(document.getElementById("select")) document.getElementById("select").value="sel"+selId;
    if(document.getElementById("pocket_ssid")) document.getElementById("pocket_ssid").value=document.getElementById("selSSID_"+selId).value;
    if(document.getElementById("pocketAP_ssid")) document.getElementById("pocketAP_ssid").value=document.getElementById("selSSID_"+selId).value;
    document.getElementById("pocket_encrypt").value=document.getElementById("selEncrypt_"+selId).value;
    if(document.getElementById("pocket_wpa_tkip_aes")) document.getElementById("pocket_wpa_tkip_aes").value=document.getElementById("wpa_tkip_aes_"+selId).value;
    if(document.getElementById("pocket_wpa2_tkip_aes")) document.getElementById("pocket_wpa2_tkip_aes").value=document.getElementById("wpa2_tkip_aes_"+selId).value;
    if(document.getElementById("pocket_pmf_status")) document.getElementById("pocket_pmf_status").value=document.getElementById("pmf_status_"+selId).value;
    if(document.wizardPocketGW){
        if(document.getElementById("wpa_tkip_aes_"+selId).value=="aes/tkip") document.wizardPocketGW.elements["ciphersuite0"].value="aes";
        else if(document.getElementById("wpa_tkip_aes_"+selId).value=="tkip") document.wizardPocketGW.elements["ciphersuite0"].value="tkip";
        else if(document.getElementById("wpa_tkip_aes_"+selId).value=="aes") document.wizardPocketGW.elements["ciphersuite0"].value="aes";
        if(document.getElementById("wpa2_tkip_aes_"+selId).value=="aes/tkip") document.wizardPocketGW.elements["wpa2ciphersuite0"].value="aes";
        else if(document.getElementById("wpa2_tkip_aes_"+selId).value=="tkip") document.wizardPocketGW.elements["wpa2ciphersuite0"].value="tkip";
        else if(document.getElementById("wpa2_tkip_aes_"+selId).value=="aes") document.wizardPocketGW.elements["wpa2ciphersuite0"].value="aes";
    }
    connectEnabled=1;
    enableButton(document.forms["formWlSiteSurvey"].next);
    document.formWlSiteSurvey.next.style.display = '';
}

function connectClick(obj) {
    if(connectEnabled==1){
        form=document.forms["formWlSiteSurvey"];
        var ssidInput=document.getElementById("pocket_ssid");
        if(ssidInput&&ssidInput.value.replace(/^\s+|\s+$/g,'')==""){
            alert("Please enter an SSID to connect."); ssidInput.focus(); return false;
        }
        wpaAuth=form.wpaAuth;
        var str=form.pskValue.value;
        if(form.pskFormat.selectedIndex==1){
            if(str.length!=64){alert('<% multilang("2574" "LANG_PRE_SHARED_KEY_VALUE_SHOULD_BE_64_CHARACTERS"); %>');form.pskValue.focus();return false;}
            takedef=0;
            if(defPskFormat==1&&defPskLen==64){
                for(var i=0;i<64;i++){if(str.charAt(i)!='*')break;}
                if(i==64)takedef=1;
            }
            if(takedef==0){
                for(var i=0;i<str.length;i++){
                    if((str.charAt(i)>='0'&&str.charAt(i)<='9')||(str.charAt(i)>='a'&&str.charAt(i)<='f')||(str.charAt(i)>='A'&&str.charAt(i)<='F'))continue;
                    alert("<% multilang("2575" "LANG_INVALID_PRE_SHARED_KEY_VALUE_IT_SHOULD_BE_IN_HEX_NUMBER_0_9_OR_A_F"); %>");form.pskValue.focus();return false;
                }
            }
        } else {
            if((form.security_method.value>1)&&wpaAuth[1].checked){
                if(str.length<8){alert('<% multilang("2576" "LANG_PRE_SHARED_KEY_VALUE_SHOULD_BE_SET_AT_LEAST_8_CHARACTERS"); %>');form.pskValue.focus();return false;}
                if(str.length>63){alert('<% multilang("2577" "LANG_PRE_SHARED_KEY_VALUE_SHOULD_BE_LESS_THAN_64_CHARACTERS"); %>');form.pskValue.focus();return false;}
                if(checkPrintableString(str)==0){alert('<% multilang("2592" "LANG_INVALID_PRE_SHARED_KEY"); %>');form.pskValue.focus();return false;}
            }
        }
        form.wlan6gSupport.value=wlan6gSupport;
        showLoader('Connecting to WiFi network.');
        obj.isclick=1;
        form.target='cmd_blind';
        postTableEncrypt(form.postSecurityFlag,form);
        setTimeout(pollConnectStatus,2000);
        return true;
    } else return false;
}

var connectPollAttempts=0;
function pollConnectStatus(){
    connectPollAttempts++;
    if(connectPollAttempts>15){hideLoader();customAlert('Timed out, it is possible that it was successful.');connectPollAttempts=0;return;}
    var xhr=new XMLHttpRequest();
    xhr.open('GET','/admin/status.asp',true);
    xhr.onload=function(){
        if(xhr.status===200){hideLoader();connectPollAttempts=0;customAlert('Changes applied, you can view the status in the WLAN status.');}
        else setTimeout(pollConnectStatus,1500);
    };
    xhr.onerror=function(){setTimeout(pollConnectStatus,1500);};
    xhr.send();
}

function updateState(){
    if(document.formWlSiteSurvey.wlanDisabled.value==1){
        document.getElementById('top_div').style.display='none';
        document.getElementById('wlan_security_div').style.display='none';
        if(document.getElementById("noise_section")) document.getElementById("noise_section").style.display="none";
        var idx=document.formWlSiteSurvey.wlan_idx?document.formWlSiteSurvey.wlan_idx.value:"0";
        var bandLabel=(idx=="0")?"5GHz":"2.4GHz";
        var msg=document.createElement('p');
        msg.textContent=bandLabel+' WLAN is disabled.';
        msg.style.cssText='text-align:center;color:var(--text-primary);font-size:25px;margin:40px 0;';
        document.querySelector('form[name="formWlSiteSurvey"]').appendChild(msg);
        disableButton(document.formWlSiteSurvey.refresh);
        disableButton(document.formWlSiteSurvey.next);
        disableButton(document.formWlSiteSurvey.connect);
        return;
    }
    var hasRadios=document.querySelectorAll('input[type="radio"][name="select"]').length>0;
    if(!hasRadios){
        document.formWlSiteSurvey.next.style.display='none';
        if(document.formWlSiteSurvey.manual) document.formWlSiteSurvey.manual.style.display='none';
    }
}

function backClick(){
    var dF=document.forms["formWlSiteSurvey"];
    get_by_id("wlan_security_div").style.display="none";
    get_by_id("top_div").style.display="";
    if(document.getElementById("noise_section")) document.getElementById("noise_section").style.display="";
    dF.ciphersuite_t.checked=false; dF.ciphersuite_a.checked=false;
    dF.wpa2ciphersuite_t.checked=false; dF.wpa2ciphersuite_a.checked=false;
}

function on_submit(obj){
    obj.isclick=1;
    showLoader('Querying nearby WiFi networks.');
    var form=document.forms["formWlSiteSurvey"];
    form.target='cmd_blind';
    postTableEncrypt(form.postSecurityFlag,form);
    setTimeout(fetchSurveyTable,4000);
    return true;
}

function fetchSurveyTable(){
    var xhr=new XMLHttpRequest();
    xhr.open('GET','/wlsurvey.asp',true);
    xhr.onload=function(){
        if(xhr.status===200){
            var parser=new DOMParser();
            var doc=parser.parseFromString(xhr.responseText,'text/html');
            var newTable=doc.querySelector('#top_div .data_common table');
            var curTable=document.querySelector('#top_div .data_common table');
            if(newTable&&curTable){
                curTable.innerHTML=newTable.innerHTML;
                var sigHdr=document.querySelector('#top_div th:nth-child(6)');
                if(sigHdr) sigHdr.textContent='RSSI';
                connectEnabled=0;
                disableButton(document.formWlSiteSurvey.next);
            }
            hideLoader();
            // ── Update spectrum chart with fresh data ──
            setTimeout(updateSpectrumChart, 100);
        } else { hideLoader(); }
    };
    xhr.onerror=function(){hideLoader();};
    xhr.send();
}

function setDefaultKeyValue(form,wlan_id){
    if(form.elements["length"+wlan_id].selectedIndex==0){
        if(form.elements["format"+wlan_id].selectedIndex==0){form.elements["key"+wlan_id].maxLength=5;form.elements["key"+wlan_id].value="*****";}
        else{form.elements["key"+wlan_id].maxLength=10;form.elements["key"+wlan_id].value="**********";}
    } else {
        if(form.elements["format"+wlan_id].selectedIndex==0){form.elements["key"+wlan_id].maxLength=13;form.elements["key"+wlan_id].value="*************";}
        else{form.elements["key"+wlan_id].maxLength=26;form.elements["key"+wlan_id].value="**************************";}
    }
}

function updateWepFormat(form,wlan_id){
    if(form.elements["length"+wlan_id].selectedIndex==0){
        form.elements["format"+wlan_id].options[0].text='ASCII (5 characters)';
        form.elements["format"+wlan_id].options[1].text='Hex (10 characters)';
        form.wepKeyLen[0].checked=true;
    } else {
        form.elements["format"+wlan_id].options[0].text='ASCII (13 characters)';
        form.elements["format"+wlan_id].options[1].text='Hex (26 characters)';
        form.wepKeyLen[1].checked=true;
    }
    setDefaultKeyValue(form,wlan_id);
}
</script>
<style>
html, body { overflow-y: auto !important; height: auto !important; min-height: 100%; }

#spectrum_canvas {
    display: block;
    border-radius: 4px;
    background: var(--bg-surface);
    border: 1px solid var(--border-color);
    box-sizing: border-box;
}
#spectrum_legend {
    display: flex;
    flex-wrap: wrap;
    gap: 2px;
    padding: 6px 2px 2px 2px;
    min-height: 18px;
}
#spectrum_recommend {
    padding: 4px 2px 2px 2px;
    min-height: 18px;
}
</style>
</head>
<body>

<iframe name="cmd_blind" style="display:none;"></iframe>

<div class="intro_main">
    <p class="intro_title"><% multilang("749" "LANG_WLAN_SITE_SURVEY"); %></p>
    <p class="intro_content">you can scan the radio environment and connect to wifi networks on this page (if the interface is set to client or wds bridge)</p>
</div>

<div id="noise_section">
<br>
    <!-- ══ SPECTRUM CHART ══ -->
    <div class="intro_main">
        <p class="intro_title">WiFi Spectrum</p>
    </div>
    <div class="data_vertical data_common_notitle">
        <div class="data_common" style="padding: 10px 12px;">
            <canvas id="spectrum_canvas" height="210"></canvas>
            <div id="spectrum_legend"></div>
            <div id="spectrum_recommend"></div>
        </div>
    </div>
<br>
    <!-- ══ CHANNEL UTILIZATION ══ -->
    <div class="intro_main">
        <p class="intro_title">Channel Utilization &amp; Noise</p>
    </div>
    <div class="data_vertical data_common_notitle">
        <div class="data_common" id="channel_stats_container">
            <p style="text-align:center;padding:15px;">
                <input type="button" class="link_bg" style="cursor:pointer;" value="loading…" onclick="fetchChannelStats()">
            </p>
        </div>
    </div>

</div>

<form action=/boaform/formWlSiteSurvey method=POST name="formWlSiteSurvey">
<input type=hidden name="wlanDisabled" value=<% getInfo("wlanDisabled"); %>>
<input type=hidden id="pocket_encrypt" name="pocket_encrypt" value="">
<input type=hidden id="pocket_wpa_tkip_aes" name="pocket_wpa_tkip_aes" value="">
<input type=hidden id="pocket_wpa2_tkip_aes" name="pocket_wpa2_tkip_aes" value="">
<input type=hidden id="pocket_pmf_status" name="pocket_pmf_status" value="">
<input type=hidden id="wlan_encrypt" name="wlan_encrypt" value="">
<input type=hidden id="wpa_tkip_aes" name="wpa_tkip_aes" value="">
<input type=hidden id="wpa2_tkip_aes" name="wpa2_tkip_aes" value="">
<input type=hidden id="pmf_status" name="pmf_status" value="">
<input type=hidden id="select" name="select" value="">

<span id="top_div">
<br>
<div class="intro_main">
    <p class="intro_title">Nearby WiFi Networks</p>
</div>
<div class="data_vertical data_common_notitle">
    <div class="data_common">
        <table><% wlSiteSurveyTbl(); %></table>
    </div>
</div>
<div class="btn_ctl">
    <input type="submit" value="<% multilang("463" "LANG_REFRESH"); %>" name="refresh" onClick="return on_submit(this)" class="link_bg">&nbsp;&nbsp;
    <input type="button" value="<% multilang("1266" "LANG_NEXT_STEP"); %>" name="next" onClick="saveClickSSID()" class="link_bg">&nbsp;&nbsp;
</div>
</span>

<span id="wlan_security_div" style="display:none">
<div class="data_common data_common_notitle">
    <table>
        <tr id="ssid_tr">
            <th>BSSID of the access point (e.g: c4:44:7d:73:20:bc)</th>
            <td><input type="text" id="pocket_ssid" name="pocket_ssid" size="32" maxlength="32" value=""></td>
        </tr>
        <tr>
            <th><% multilang("224" "LANG_ENCRYPTION"); %>:&nbsp;
                <select size="1" id="security_method" name="security_method" onChange="show_authentication()">
                    <% checkWrite("wifiClientSecurity"); %>
                </select>
            </th>
        </tr>
        <tr id="enable_8021x" style="display:none">
            <th>802.1x <% multilang("225" "LANG_AUTHENTICATION"); %>:</th>
            <td><input type="checkbox" id="use1x" name="use1x" value="ON" onClick="show_8021x_settings()"></td>
        </tr>
        <tr id="show_wep_auth" style="display:none">
            <th><% multilang("225" "LANG_AUTHENTICATION"); %>:</th>
            <td>
                <input name="auth_type" type=radio value="open" checked><% multilang("226" "LANG_OPEN_SYSTEM"); %>
                <input name="auth_type" type=radio value="shared"><% multilang("227" "LANG_SHARED_KEY"); %>
                <input name="auth_type" type=radio value="both"><% multilang("191" "LANG_AUTO"); %>
            </td>
        </tr>
    </table>
    <table id="setting_wep" style="display:none">
        <input type="hidden" name="wepEnabled" value="ON" checked>
        <tr>
            <th><% multilang("228" "LANG_KEY_LENGTH"); %>:</th>
            <td><select size="1" name="length0" id="key_length" onChange="updateWepFormat(document.formWlSiteSurvey,0)">
                <option value=1>64-bit</option><option value=2>128-bit</option></select></td>
        </tr>
        <tr>
            <th><% multilang("229" "LANG_KEY_FORMAT"); %>:</th>
            <td><select id="key_format" name="format0" onChange="setDefaultKeyValue(document.formWlSiteSurvey,0)">
                <option value="1">ASCII</option><option value="2">Hex</option></select></td>
        </tr>
        <tr>
            <th><% multilang("230" "LANG_ENCRYPTION_KEY"); %>:</th>
            <td><input type="text" id="key" name="key0" maxlength="26" size="26" value=""></td>
        </tr>
    </table>
    <table>
        <tr id="setting_wpa" style="display:none">
            <th><% multilang("231" "LANG_AUTHENTICATION_MODE"); %>:</th>
            <td>
                <input name="wpaAuth" type="radio" value="eap" onClick="show_wpa_settings()">Enterprise (RADIUS)
                <input name="wpaAuth" type="radio" value="psk" onClick="show_wpa_settings()">Personal (Pre-Shared Key)
            </td>
        </tr>
        <tr id="show_wpa3_sae_pwe" style="display:none">
            <th width="30%"><% multilang("238" "LANG_H2E"); %>:</th>
            <td width="70%">
                <input name="wpa3_sae_pwe" type="radio" value="2">Capable
                <input name="wpa3_sae_pwe" type="radio" value="1">Required
            </td>
        </tr>
        <tr id="show_dotIEEE80211W" style="display:none">
            <th width="30%"><% multilang("239" "LANG_IEEE_802_11W"); %>:</th>
            <td width="70%">
                <input name="dotIEEE80211W" type="radio" value="0" onClick="show_sha256_settings()">None
                <input name="dotIEEE80211W" type="radio" value="1" onClick="show_sha256_settings()">Capable
                <input name="dotIEEE80211W" type="radio" value="2" onClick="show_sha256_settings()">Required
            </td>
        </tr>
        <tr id="show_sha256" style="display:none">
            <th width="30%"><% multilang("240" "LANG_SHA256"); %>:</th>
            <td width="70%">
                <input name="sha256" type="radio" value="0">Disable
                <input name="sha256" type="radio" value="1">Enable
            </td>
        </tr>
        <tr id="show_wpa_cipher" style="display:none">
            <th>WPA <% multilang("232" "LANG_CIPHER_SUITE"); %>:</th>
            <td><input type="checkbox" name="ciphersuite_t" value=1>TKIP&nbsp;<input type="checkbox" name="ciphersuite_a" value=1>AES</td>
        </tr>
        <tr id="show_wpa2_cipher" style="display:none">
            <th>WPA2 <% multilang("232" "LANG_CIPHER_SUITE"); %>:</th>
            <td><input type="checkbox" name="wpa2ciphersuite_t" value=1>TKIP&nbsp;<input type="checkbox" name="wpa2ciphersuite_a" value=1>AES</td>
        </tr>
        <tr id="show_wpa_psk1" style="display:none">
            <th><% multilang("234" "LANG_PRE_SHARED_KEY_FORMAT"); %>:</th>
            <td><select id="psk_fmt" name="pskFormat" onChange="">
                <option value="0">Passphrase</option><option value="1">HEX (64 characters)</option></select></td>
        </tr>
        <tr id="show_wpa_psk2" style="display:none">
            <th><% multilang("235" "LANG_PRE_SHARED_KEY"); %>:</th>
            <td><input type="password" name="pskValue" id="wpapsk" size="32" maxlength="64" value=""></td>
        </tr>
        <tr id="setting_wapi" style="display:none">
            <th><% multilang("231" "LANG_AUTHENTICATION_MODE"); %>:</th>
            <td>
                <input name="wapiAuth" type="radio" value="eap" onClick="show_wapi_settings()">Enterprise (AS Server)
                <input name="wapiAuth" type="radio" value="psk" onClick="show_wapi_settings()">Personal (Pre-Shared Key)
            </td>
        </tr>
        <tr id="show_wapi_psk1" style="display:none">
            <th><% multilang("234" "LANG_PRE_SHARED_KEY_FORMAT"); %>:</th>
            <td><select id="wapi_psk_fmt" name="wapiPskFormat" onChange="">
                <option value="0">Passphrase</option><option value="1">HEX (64 characters)</option></select></td>
        </tr>
        <tr id="show_wapi_psk2" style="display:none">
            <th><% multilang("235" "LANG_PRE_SHARED_KEY"); %>:</th>
            <td><input type="password" name="wapiPskValue" id="wapipsk" size="32" maxlength="64" value=""></td>
        </tr>
        <tr id="show_1x_wep" style="display:none">
            <th><% multilang("228" "LANG_KEY_LENGTH"); %>:</th>
            <td>
                <input name="wepKeyLen" type="radio" value="wep64">64 Bits
                <input name="wepKeyLen" type="radio" value="wep128">128 Bits
            </td>
        </tr>
    </table>
    <table id="show_8021x_eap" style="display:none">
        <tr><th>RADIUS <% multilang("96" "LANG_SERVER"); %> <% multilang("94" "LANG_IP_ADDRESS"); %>:</th>
            <td><input id="radius_ip" name="radiusIP" size="16" maxlength="15" value="0.0.0.0"></td></tr>
        <tr><th>RADIUS <% multilang("96" "LANG_SERVER"); %> <% multilang("236" "LANG_PORT"); %>:</th>
            <td><input type="text" id="radius_port" name="radiusPort" size="5" maxlength="5" value="1812"></td></tr>
        <tr><th>RADIUS <% multilang("96" "LANG_SERVER"); %> <% multilang("72" "LANG_PASSWORD"); %>:</th>
            <td><input type="password" id="radius_pass" name="radiusPass" size="32" maxlength="64" value="12345"></td></tr>
    </table>
    <table id="show_8021x_wapi" style="display:none">
        <tr id="show_8021x_wapi_local_as" style="">
            <th><% multilang("237" "LANG_USE_LOCAL_AS_SERVER"); %>:</th>
            <td><input type="checkbox" id="uselocalAS" name="uselocalAS" value="ON" onClick="show_wapi_ASip()"></td>
        </tr>
        <tr><th>AS <% multilang("96" "LANG_SERVER"); %> <% multilang("94" "LANG_IP_ADDRESS"); %>:</th>
            <td><input id="wapiAS_ip" name="wapiASIP" size="16" maxlength="15" value="0.0.0.0"></td></tr>
    </table>
</div>
<div class="btn_ctl">
    <input class="link_bg" type="button" value="<% multilang("1267" "LANG_BACK"); %>" name="back" onClick="return backClick()">
    <input class="link_bg" type="submit" value="<% multilang("104" "LANG_CONNECT"); %>" name="connect" onClick="return connectClick(this)">
    <input type="hidden" value="/wlsurvey.asp" name="submit-url">
    <input type="hidden" name="wlan_idx" value=<% checkWrite("wlan_idx"); %>>
    <input type="hidden" name="wlan6gSupport" value="">
    <input type="hidden" name="postSecurityFlag" value="">
</div>
</span>
<script>
    <% initPage("wlsurvey"); %>
    disableButton(document.formWlSiteSurvey.next);
    updateState();
    document.formWlSiteSurvey.next.style.display = 'none';
    fetchChannelStats();
    fetchHostNetwork(); // <-- ADDED THIS LINE
    var sigHdr = document.querySelector('#top_div th:nth-child(6)');
    if (sigHdr) sigHdr.textContent = 'RSSI';
    // Initial spectrum render (empty state until first scan)
    updateSpectrumChart();
</script>


</form>
</body>
</html>
