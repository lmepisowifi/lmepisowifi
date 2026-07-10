















































<% SendWebHeadStr();%>
<title><% multilang("305" "LANG_EASYMESH_CHANNEL_SCAN"); %></title>
<style>
.on {display:on}
.off {display:none}

tbody.for_top_margin::before
{
  content: '';
  display: block;
  height: 20px;
}
</style>

<SCRIPT>
var scan_band = <% GetChannelScanInfo(); %>;
function loadInfo()
{
	if (scan_band == 0) {
		document.getElementById("band_all").checked = true;
	} else if (scan_band == 1) {
		document.getElementById("band_2G").checked = true;
	} else if (scan_band == 2) {
		document.getElementById("band_5G").checked = true;
	}
}

</SCRIPT>
</head>

<body onload="loadInfo();">
    <div class="intro_main ">
	    <p class="intro_title"><% multilang("305" "LANG_EASYMESH_CHANNEL_SCAN"); %></p>
	    <p class="intro_content"><% multilang("306" "LANG_EASYMESH_CHANNEL_SCAN_DESC"); %></p>
    </div>

<form action=/boaform/formChannelScan method=POST name="MultiAP">
	<div class="data_common data_common_notitle">
	<table>
	<tr id="channel_scan_band">
		<th><% multilang("3316" "LANG_EASYMESH_SCAN_BIND"); %></th>
		<td>
		<input type="radio" id="band_5G" name="scan_band" value="5G">5G&nbsp;&nbsp;
		<input type="radio" id="band_2G" name="scan_band" value="2G">2.4G&nbsp;&nbsp;
		<input type="radio" id="band_all" name="scan_band" value="all">All</td>
	</tr>

	</table>
	</div>
	<div class="btn_ctl">
		<input type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" class="link_bg" name="channel_scan" onclick="">&nbsp;&nbsp;

		<input type="hidden" value="/multi_ap_channel_scan.asp" name="submit-url">
	</div>
</form>

</body>

</html>
