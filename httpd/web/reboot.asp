<% SendWebHeadStr();%>
<title><% multilang("565" "LANG_COMMIT_AND_REBOOT"); %></title>

<!-- Import our shared UI functions! -->
<script src="customprompt.js"></script>

<SCRIPT>
function saveClick() {
    // customConfirm is asynchronous, so we pass a callback function to run when the user clicks "Yes"
    customConfirm('<% multilang("2612" "LANG_DO_YOU_REALLY_WANT_TO_COMMIT_THE_CURRENT_SETTINGS"); %>', function() {
        var form = document.forms['cmboot'];
        postTableEncrypt(form.postSecurityFlag, form);

        try {
            window.parent.rebooting = true; 

            // 1. Hide the Iframe so the "Connection Lost" error doesn't show up when the router dies
            const iframe = window.parent.document.getElementById("contentIframe");
            if (iframe) {
                iframe.style.display = "none";
            }

            // 2. Attach the 45s timer to the PARENT window so it survives the iframe submission
            window.parent.setTimeout(function() {
                window.parent.location.href = '/admin/login.asp';
            }, 45000);

        } catch (e) {
            console.error(e);
        }

        // 3. Show the beautiful loading screen using our shared function
        showLoader('The ONT is restarting.<br>wait atleast 1 minute for the system to start up.');

        // 4. Finally, submit the form to trigger the actual reboot!
        form.submit();
    });
}

</SCRIPT>
</head>

<body>
<div class="intro_main ">
	<p class="intro_title"><% multilang("565" "LANG_COMMIT_AND_REBOOT"); %></p>
	<p class="intro_content"><% multilang("566" "LANG_THIS_PAGE_IS_USED_TO_COMMIT_CHANGES_TO_SYSTEM_MEMORY_AND_REBOOT_YOUR_SYSTEM"); %></p>
</div>

<form action=/boaform/admin/formReboot method=POST name="cmboot">
<div class="data_common data_common_notitle">
	<table>
		<tr>
			<th width="30%"><% multilang("565" "LANG_COMMIT_AND_REBOOT"); %>:</th>
			<td>
				<input class="inner_btn" type="button" value="<% multilang("565" "LANG_COMMIT_AND_REBOOT"); %>" onclick="saveClick()">
			</td>
		</tr>
	</table>
</div>

<input type="hidden" name="postSecurityFlag" value="">
</form>
</body>
</html>