<% SendWebHeadStr();%>
<title><% multilang("241" "LANG_WLAN_ACCESS_CONTROL"); %></title>
<script src="customprompt.js"></script>
<script>
function skip () { this.blur(); }
function addClick(obj)
{
	if (!checkMac(document.formWlAcAdd.mac, 1))
		return false; // Check MAC before showing loader to prevent freezing
		
	showLoader('Applying Changes.');
	obj.isclick = 1;
	postTableEncrypt(document.formWlAcAdd.postSecurityFlag, document.formWlAcAdd);
	_saveBlindPending = true;
	return true;
}

function disableDelButton()
{
	disableButton(document.formWlAcDel.deleteSelFilterMac);
	disableButton(document.formWlAcDel.deleteAllFilterMac);
}

function enableAc()
{
  enableTextField(document.formWlAcAdd.mac);
}

function disableAc()
{
  disableTextField(document.formWlAcAdd.mac);
}

function updateState()
{
  if(wlanDisabled || wlanMode == 1 || wlanMode ==2){
	var dataCommons = document.querySelectorAll('.data_common');
	for (var i = 0; i < dataCommons.length; i++) {
		dataCommons[i].style.display = 'none';
	}
	var btnCtls = document.querySelectorAll('.btn_ctl');
	for (var i = 0; i < btnCtls.length; i++) {
		btnCtls[i].style.display = 'none';
	}
	var column = document.querySelector('.column');
	if (column) column.style.display = 'none';

	if (!document.getElementById('wlan-disabled-msg')) {
		var idxEl = document.querySelector('input[name="wlan_idx"]');
		var idx = idxEl ? parseInt(idxEl.value) : 0;
		var bandLabel = (idx == 0) ? "5GHz" : "2.4GHz";
		var msg = document.createElement('p');
		msg.id = 'wlan-disabled-msg';
		if (wlanDisabled) {
			msg.textContent = bandLabel + ' WLAN is disabled.';
		} else {
			msg.textContent = bandLabel + " Access Control isn't available in Client Mode.";
		}
		msg.style.cssText = 'text-align:center; color:var(--text-primary); font-size:25px; margin:40px 0;';
		document.querySelector('form').appendChild(msg);
	}

	disableDelButton();
	disableButton(document.formWlAcAdd.reset);
	disableButton(document.formWlAcAdd.setFilterMode);
	disableButton(document.formWlAcAdd.addFilterMac);
	disableTextField(document.formWlAcAdd.wlanAcEnabled);
	disableAc();
  } 
  else{
    if (document.formWlAcAdd.wlanAcEnabled.selectedIndex) {
	enableButton(document.formWlAcAdd.reset);
	enableButton(document.formWlAcAdd.addFilterMac);
	enableAc();
    }
    else {
	disableButton(document.formWlAcAdd.reset);
	disableButton(document.formWlAcAdd.addFilterMac);
	disableAc();
    }
  }
}

function on_submit(obj)
{
	obj.isclick = 1;
	showLoader('Applying Changes.');
	postTableEncrypt(document.formWlAcAdd.postSecurityFlag, document.formWlAcAdd);
	_saveBlindPending = true;
	return true;
}

function deleteClick(obj)
{
	if ( !confirm('<% multilang("1781" "LANG_CONFIRM_DELETE_ONE_ENTRY"); %>') ) {
		return false;
	}
	else{
		obj.isclick = 1;
		showLoader('Applying Changes.');
		postTableEncrypt(document.formWlAcDel.postSecurityFlag, document.formWlAcDel);
		_saveBlindPending = true;
		return true;
	}
}
        
function deleteAllClick(obj)
{
	if ( !confirm('Do you really want to delete the all entries?') ) {
		return false;
	}
	else{
		obj.isclick = 1;
		showLoader('Applying Changes.');
		postTableEncrypt(document.formWlAcDel.postSecurityFlag, document.formWlAcDel);
		_saveBlindPending = true;
		return true;
	}
}

</script>
</head>

<body>

<!-- ADDED: Hidden iframe so form submissions happen secretly in the background -->
<iframe name="save_blind" id="save_blind" style="display:none;"></iframe>

<script>
var _saveBlindPending = false;
(function() {
    var blind = document.getElementById('save_blind');

    blind.addEventListener('load', function() {
        if (!_saveBlindPending) return;   // ignore initial blank load
        _saveBlindPending = false;
        
        var isSuccess = false;
        try {
            var doc = blind.contentDocument || blind.contentWindow.document;
            var body = doc && doc.body ? doc.body.innerHTML : '';
            
            // Break string to avoid parent index.asp cleanload() false-positive
            if (body.indexOf('Change setting ' + 'successfully!') !== -1) {
                isSuccess = true;
                var okBtn = doc.querySelector('input[type="button"]');
                if (okBtn) okBtn.click();
            }
        } catch(e) {
            isSuccess = true; // Cross-origin block means it likely worked but connection dropped
        }

        if (isSuccess) {
            try {
                var parentDoc = window.parent.document;
                var loadDiv = parentDoc.getElementById('loadpagediv');
                if (loadDiv) {
                    loadDiv.classList.remove('no-spinner'); // Keep the spinner spinning!
                }
            } catch(e) {}

            // Wait 2.5 seconds before we start checking, giving Wi-Fi time to drop
            setTimeout(function() {
                
                var pollTimer = setInterval(function() {
                    var xhr = new XMLHttpRequest();
                    // Add a timestamp cache-buster so the browser doesn't give us a stale page
                    var fetchUrl = window.location.href.split('?')[0] + '?_t=' + new Date().getTime();
                    
                    xhr.open('GET', fetchUrl, true);
                    xhr.timeout = 3000; // Don't hang forever if disconnected
                    
                    xhr.onload = function() {
                        if (xhr.status === 200) {
                            clearInterval(pollTimer); // WE RECONNECTED! Stop polling.
                            
                            // 1. Create a fake background document to parse the new router data
                            var newDoc = document.implementation.createHTMLDocument();
                            newDoc.documentElement.innerHTML = xhr.responseText;
                            
                            // 2. Grab the old table on your screen, and the new table from the router
                            var oldTable = document.querySelector('form[name="formWlAcDel"] table');
                            var newTable = newDoc.querySelector('form[name="formWlAcDel"] table');
                            
                            // 3. Swap them out seamlessly!
                            if (oldTable && newTable) {
                                oldTable.innerHTML = newTable.innerHTML;
                            }
                            
                            // 4. Clear the MAC input box automatically
                            if (document.formWlAcAdd && document.formWlAcAdd.mac) {
                                document.formWlAcAdd.mac.value = '';
                            }
                            
                            // 5. Tell the user it's done and hide the loader after 1 second
                            try {
                                var parentDoc = window.parent.document;
                                var loadDiv = parentDoc.getElementById('loadpagediv');
                                if (loadDiv) {
                                    var pText = cleanLoaderDOM(loadDiv);
                                    pText.innerHTML = 'Changes applied.';
                                    loadDiv.className = 'no-spinner'; 
                                }
                            } catch(e) {}
                            
                            setTimeout(function() {
                                hideLoader();
                                try { window.parent.cleanload(); } catch(e) {}
                            }, 1000);
                        }
                    };
                    
                    xhr.onerror = function() {
                        // Network error means Wi-Fi is still down. Do nothing, loop will try again.
                    };
                    xhr.ontimeout = function() {
                        // Timeout means Wi-Fi is still down. Do nothing.
                    };
                    
                    xhr.send();
                }, 3000); // Check every 3 seconds if the router is reachable yet

            }, 2500); 
            
        } else {
            hideLoader();
            try { window.parent.cleanload(); } catch(e) {}
        }
    });

    blind.addEventListener('error', function() {
        if (!_saveBlindPending) return;
        _saveBlindPending = false;
        hideLoader(); 
        try { window.parent.cleanload(); } catch(e) {}
    });
})();
</script>

<div class="intro_main ">
	<p class="intro_title"><% multilang("241" "LANG_WLAN_ACCESS_CONTROL"); %></p>
	<p class="intro_content"><% multilang("242" "LANG_PAGE_DESC_WLAN_ALLOW_DENY_LIST"); %></p>
</div>
<form action=/boaform/admin/formWlAc method=POST name="formWlAcAdd" target="save_blind">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%">
				<% multilang("151" "LANG_MODE"); %>: &nbsp;&nbsp;&nbsp;&nbsp;
			</th>
			<td>
			<select size="1" name="wlanAcEnabled" onclick="updateState()">
				<option value=0 ><% multilang("201" "LANG_DISABLED"); %></option>
				<option value=1 selected ><% multilang("243" "LANG_ALLOW_LISTED"); %></option>
				<option value=2 ><% multilang("244" "LANG_DENY_LISTED"); %></option>
			</select>
			</td>
			<td><input type="submit" value="<% multilang("169" "LANG_APPLY_CHANGES"); %>" name="setFilterMode" class="inner_btn" onClick="return on_submit(this)">&nbsp;&nbsp;</td>
		</tr>
	</table>
</div>

<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%"><% multilang("97" "LANG_MAC_ADDRESS"); %>: </th>
			<td>
				<input type="text" name="mac" size="15" maxlength="12">&nbsp;&nbsp;(ex. 00E086710502)
			</td>
		</tr>
	</table>
</div>
<div class="btn_ctl">
	<input type="submit" class="link_bg" value="<% multilang("245" "LANG_ADD"); %>" name="addFilterMac" onClick="return addClick(this)">&nbsp;&nbsp;
	<input type="reset" class="link_bg" value="<% multilang("246" "LANG_RESET"); %>" name="reset">&nbsp;&nbsp;&nbsp;
	<input type="hidden" value="/admin/wlactrl.asp" name="submit-url">
	<input type="hidden" name="wlan_idx" value=<% checkWrite("wlan_idx"); %>>
	<input type="hidden" name="postSecurityFlag" value="">
</div>   

</form>
<form action=/boaform/admin/formWlAc method=POST name="formWlAcDel" target="save_blind">
<div class="column">
	<div class="column_title">
		<div class="column_title_left"></div>
			<p><% multilang("247" "LANG_CURRENT_ACCESS_CONTROL_LIST"); %></p>
		<div class="column_title_right"></div>
	</div>
	<div class="data_common data_vertical">
		<table border="0" width=440>
			<% wlAcList(); %>
		</table>
	</div>
</div>
<div class="btn_ctl">
	<input type="submit" class="link_bg" value="<% multilang("248" "LANG_DELETE_SELECTED"); %>" name="deleteSelFilterMac" onClick="return deleteClick(this)">&nbsp;&nbsp;
	<input type="submit" class="link_bg" value="<% multilang("249" "LANG_DELETE_ALL"); %>" name="deleteAllFilterMac" onClick="return deleteAllClick(this)">&nbsp;&nbsp;&nbsp;
	<input type="hidden" value="/admin/wlactrl.asp" name="submit-url">
	<input type="hidden" name="wlan_idx" value=<% checkWrite("wlan_idx"); %>>
	<input type="hidden" name="postSecurityFlag" value="">
</div>
<script>
	<% checkWrite("wlanAcNum"); %>
	<% initPage("wlactrl"); %>
	updateState();
</script>
<br><br>
</form>
</body>
</html>
