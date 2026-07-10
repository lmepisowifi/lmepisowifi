// -----------------------------------------------------------
// SHARED UI FUNCTIONS (ALERTS, CONFIRMS, LOADERS)
// -----------------------------------------------------------

// Helper: Purges any leftover buttons from previous alerts
function cleanLoaderDOM(loader) {
    if (!loader) return;
    var pText = loader.querySelector('p');
    loader.innerHTML = ''; // Wipe everything out
    if (pText) {
        loader.appendChild(pText); // Put only the text back
    } else {
        pText = window.parent.document.createElement('p');
        loader.appendChild(pText);
    }
    return pText;
}

function customAlert(msg, callback) {
    try {
        var parentDoc = window.parent.document;
        var loadDiv = parentDoc.getElementById('loadpagediv');
        var shade = parentDoc.getElementById('shade');
        
        var pText = cleanLoaderDOM(loadDiv);
        
        loadDiv.className = 'no-spinner'; // Hide the spinning animation
        pText.innerHTML = msg.replace(/\n/g, '<br>');
        
        var btn = parentDoc.createElement('input');
        btn.type = 'button';
        btn.value = 'OK';
        btn.className = 'link_bg';
        btn.style.marginTop = '15px';
        btn.style.cursor = 'pointer';
        
        btn.onclick = function() {
            cleanLoaderDOM(loadDiv); // Cleanup self
            loadDiv.style.display = 'none';
            shade.style.display = 'none';
            loadDiv.className = 'loading'; // Reset class for future loading screens
            if (callback) callback();
        };
        
        loadDiv.appendChild(btn);
        shade.style.display = 'block';
        loadDiv.style.display = 'block';
    } catch(e) {
        alert(msg.replace(/<br>/g, '\n'));
        if (callback) callback();
    }
}

function customConfirm(msg, yesCallback, noCallback) {
    try {
        var parentDoc = window.parent.document;
        var loadDiv = parentDoc.getElementById('loadpagediv');
        var shade = parentDoc.getElementById('shade');
        
        var pText = cleanLoaderDOM(loadDiv);
        
        loadDiv.className = 'no-spinner'; 
        pText.innerHTML = msg.replace(/\n/g, '<br>');
        
        var btnContainer = parentDoc.createElement('div');
        btnContainer.style.marginTop = '15px';
        
        var btnYes = parentDoc.createElement('input');
        btnYes.type = 'button';
        btnYes.value = 'Yes';
        btnYes.className = 'link_bg';
        btnYes.style.marginRight = '10px';
        btnYes.style.cursor = 'pointer';
        
        var btnNo = parentDoc.createElement('input');
        btnNo.type = 'button';
        btnNo.value = 'No';
        btnNo.className = 'link_bg';
        btnNo.style.cursor = 'pointer';
        
        function cleanup() {
            cleanLoaderDOM(loadDiv);
            loadDiv.style.display = 'none';
            shade.style.display = 'none';
            loadDiv.className = 'loading';
        }
        
        btnYes.onclick = function() {
            cleanup();
            if (yesCallback) yesCallback();
        };
        
        btnNo.onclick = function() {
            cleanup();
            if (noCallback) noCallback();
        };
        
        btnContainer.appendChild(btnYes);
        btnContainer.appendChild(btnNo);
        loadDiv.appendChild(btnContainer);
        
        shade.style.display = 'block';
        loadDiv.style.display = 'block';
    } catch(e) {
        if (confirm(msg.replace(/<br>/g, '\n'))) {
            if (yesCallback) yesCallback();
        } else {
            if (noCallback) noCallback();
        }
    }
}

function showLoader(msg) {
    try {
        var parentDoc = window.parent.document;
        var loader = parentDoc.getElementById('loadpagediv');
        var shade  = parentDoc.getElementById('shade');
        if (loader) { 
            var pText = cleanLoaderDOM(loader); // Guarantee no ghost buttons exist!
            loader.className = 'loading'; 
            pText.innerHTML = msg || 'Applying Changes.'; 
            loader.style.display = 'block'; 
        }
        if (shade)  shade.style.display = 'block';
    } catch(e) {}
}

function hideLoader() {
    try {
        var parentDoc = window.parent.document;
        var loader = parentDoc.getElementById('loadpagediv');
        var shade  = parentDoc.getElementById('shade');
        if (loader) { 
            cleanLoaderDOM(loader);
            loader.style.display = 'none'; 
        }
        if (shade)  shade.style.display = 'none';
        window.parent.rebooting = false;
    } catch(e) {}
}
