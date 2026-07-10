<!DOCTYPE HTML>
<html>
<!-- Copyright (c) Realtek Semiconductor Corp., 2003. All Rights Reserved. -->
<head>
<meta http-equiv="Content-Type" content="text/html" charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<TITLE><% multilang("3314" "LANG_TITLE"); %></TITLE>
<link href="favicon.ico" type="image/x-icon" rel="shortcut icon" />
<script type="text/javascript" src="rollups/md5.js"></script>
<script type="text/javascript" src="php-crypt-md5.js"></script>
<link rel="stylesheet" href="/admin/style.css">
<SCRIPT language="javascript" src="/common.js"></SCRIPT>
<script type="text/javascript" src="/base64_code.js"></script>
<SCRIPT>
var loginAttempted = false; // Prevents the iframe from firing on initial load

function setpass(obj)
{
    // Save scroll position before fixed elements snap it
    var sx = window.pageXOffset || document.documentElement.scrollLeft;
    var sy = window.pageYOffset || document.documentElement.scrollTop;

    document.cmlogin.username.value = document.cmlogin.username.value.replace(/\s/g, '');
    document.cmlogin.encodePassword.value = encode64(document.cmlogin.password.value);
    document.cmlogin.password.disabled = true;
    
    <% passwd2xmit(); %>
    obj.isclick = 1;
    loginAttempted = true; // Mark that we submitted the form
    
    document.getElementById('loadpagediv').className = 'loading';
    document.getElementById('loadpagediv').innerHTML = '<p>Logging in.</p>';
    document.getElementById('loadpagediv').style.display = 'block';
    document.getElementById('login-wrapper').classList.add('blurred');

    // Restore scroll immediately after
    window.scrollTo(sx, sy);

    postTableEncrypt(document.cmlogin.postSecurityFlag, document.cmlogin);
}

function mlhandle()
{
    postTableEncrypt(document.formML.postSecurityFlag, document.formML);
    document.formML.submit();
}

// ─── IFRAME RESPONSE HANDLER ───
function loginFrameLoaded() {
    if (!loginAttempted) return; // Ignore the blank page load on startup
    
    var iframe = document.getElementById('login_blind');
    try {
        var doc = iframe.contentDocument || iframe.contentWindow.document;
        var bodyText = doc.body ? doc.body.innerHTML : '';
        var href = iframe.contentWindow.location.href;

        // 1. Check for SUCCESS (Redirected to dashboard)
        if (href.indexOf('index.asp') !== -1 || href.indexOf('index_user.asp') !== -1) {
            document.getElementById('loadpagediv').innerHTML = '<p>Login successful, Redirecting.</p>';
            window.location.href = href;
            return;
        }

        // 2. Check for INCORRECT PASSWORD
        if (bodyText.indexOf('bad password') !== -1 || bodyText.indexOf('username or password error') !== -1) {
            showLoginError('Incorrect password. Please try again.');
            return;
        }

        // 3. Check for 3 FAILED ATTEMPTS (Lockout)
        if (bodyText.indexOf('three times') !== -1 || bodyText.indexOf('1 minute later') !== -1) {
            showLockoutError();
            return;
        }

        // 3.14159265359. "You have not logined" — session race, silently retry
        if (bodyText.indexOf('You have not logined') !== -1) {
            document.cmlogin.submit();
            return;
        }
        // 4. Generic error fallback
        if (bodyText.indexOf('ERROR') !== -1 || bodyText.indexOf('go_back_referrer') !== -1) {
            showLoginError('Unknown Error.');
            return;
        }

    } catch (e) {
        console.error("Iframe read error:", e);
    }
}

function showLoginError(msg) {
    var loadDiv = document.getElementById('loadpagediv');
    loadDiv.className = 'no-spinner'; // Remove spinning animation
    loadDiv.innerHTML = '<p style="color:#ff6b6b; font-weight:bold; font-size:16px;">' + msg + '</p>';
    
    var btn = document.createElement('input');
    btn.type = 'button';
    btn.value = 'OK';
    // Style it identically to your nice login button
    btn.style.cssText = 'margin-top: 15px; -webkit-appearance: none; appearance: none; color: #fff; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); border-radius: 4px; padding: 5px 25px; cursor: pointer;';
    
    btn.onclick = function() {
        // 1. Hide the popup and remove the background blur
        loadDiv.style.display = 'none';
        document.getElementById('login-wrapper').classList.remove('blurred');
        
        // 2. Re-enable the password field and clear it so the user can type again
        document.cmlogin.password.disabled = false;
        document.cmlogin.password.value = '';
        document.cmlogin.password.focus();
        
        // 3. Reset the form state so it allows submission again
        loginAttempted = false;
        
        // 4. Restore the original loading text/spinner for the next attempt
        loadDiv.className = 'loading';
        loadDiv.innerHTML = '<p>Logging in...</p>';
    };
    loadDiv.appendChild(btn);
}

function showLockoutError() {
    var loadDiv = document.getElementById('loadpagediv');
    loadDiv.className = 'no-spinner'; // Remove spinning animation
    
    var seconds = 60;
    loadDiv.innerHTML = '<p style="color:#ff6b6b; font-weight:bold; font-size:16px;">Too many failed attempts.</p><p id="lockout-timer" style="margin-top:10px;">Please try again in ' + seconds + ' seconds.</p>';
    
    // Live countdown timer!
    var interval = setInterval(function() {
        seconds--;
        if (seconds <= 0) {
            clearInterval(interval);
            window.location.reload(); // Automatically refresh when time is up
        } else {
            document.getElementById('lockout-timer').innerText = 'Please try again in ' + seconds + ' seconds.';
        }
    }, 1000);
}
</SCRIPT>
<style>
#login-wrapper.blurred {
    -webkit-filter: blur(5px);
    filter: blur(5px);
    -webkit-transition: -webkit-filter 0.15s ease, filter 0.15s ease;
    transition: -webkit-filter 0.15s ease, filter 0.15s ease;
}
#login-wrapper {
    position: relative;
    -webkit-transition: -webkit-filter 0.15s ease, filter 0.15s ease;
    transition: -webkit-filter 0.15s ease, filter 0.15s ease;
}
select#usernameSelect {
    width: 100% !important;
    height: 34px !important;
    background-color: var(--bg-input) !important;
    border: 1px solid var(--border-color) !important;
    border-radius: 4px !important;
    color: var(--text-primary) !important;
    padding: 0 8px !important;
    box-sizing: border-box !important;
    cursor: pointer !important;
    outline: none !important;
}
select#usernameSelect:focus {
    border-color: var(--accent-color) !important;
}
#loadpagediv {
    display: none;
    position: fixed;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    background: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 24px 32px;
    z-index: 9999;
    text-align: center;
    color: var(--text-primary);
    font-size: 14px;
    min-width: 200px;
}

/* Hide the native spinner pseudo-elements when we apply the 'no-spinner' class */
#loadpagediv.no-spinner::before,
#loadpagediv.no-spinner::after { 
    display: none !important; 
}

/* Aurora canvas sits behind everything */
#aurora-bg {
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    z-index: -1;
    background: #0a1628;
    overflow: hidden;
}
#aurora-canvas {
    display: block;
    position: absolute;
    top: 50%; left: 50%;
    width: 12.5%;
    transform: translate(-50%, -50%) scale(8);
    filter: blur(4px) saturate(1.5);
    opacity: 0.9;
}

/* Make body background transparent so aurora shows through */
body {
    background-color: transparent !important;
    display: flex;
    flex-direction: column !important;
    justify-content: center !important;
    align-items: center !important;
    min-height: 100vh !important;
    margin: 0;
}

/* Just center the logo image with margins - no text-align needed */
img[src*="YOTC_logo_blue"] {
    width: 350px !important;   
    height: auto !important;   
    display: block !important;
    margin: 15px auto !important;
    max-width: 100% !important;
}
blockquote {
    background: transparent !important;
    margin: 0;
    padding: 0;
    width: 100% !important;
    display: flex !important;
    justify-content: center !important;
}

/* The login card — the inner table */
CENTER > TABLE > TBODY > TR > TD {
    background: var(--bg-surface) !important;
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 30px !important;
    box-shadow: 0 0 20px rgba(0,0,0,0.15);
}

/* Kill the blue font tags */
font[color="#0000FF"],
font[color="#0000ff"],
FONT[color="#0000FF"] {
    color: var(--text-primary) !important;
    font-size: 15px !important;
}

/* Label text alignment */
DIV[align="right"] font,
DIV[align="right"] FONT {
    color: var(--text-secondary) !important;
}

/* Username/password inputs */
input[name="username"],
input[name="password"],
input[type="text"],
input[type="password"] {
    width: 100% !important;
    height: 34px !important;
    background-color: var(--bg-input) !important;
    border: 1px solid var(--border-color) !important;
    border-radius: 4px !important;
    color: var(--text-primary) !important;
    padding: 0 8px !important;
    box-sizing: border-box !important;
    outline: none !important;
    -webkit-tap-highlight-color: transparent !important;
}

input[name="username"]:focus,
input[name="password"]:focus,
input[type="text"]:focus,
input[type="password"]:focus {
    outline: none !important;
    box-shadow: none !important;
    border-color: var(--accent-color) !important; 
}

/* =========================================
   LOGIN SUBMIT BUTTON (.inner_btn STYLE)
   ========================================= */
input[name="save"][type="submit"] {
    -webkit-appearance: none !important;
    appearance: none !important;
    color: var(--text-secondary) !important;
    background: var(--bg-surface-hover) !important;
    border: 1px solid var(--border-color) !important;
    border-radius: 4px !important;
    padding: 5px 12px !important;
    height: 34px !important;
    font-size: 13px !important;
    font-weight: normal !important;
    cursor: pointer !important;
}

input[name="save"][type="submit"]:hover {
    color: var(--text-primary) !important;
    border-color: var(--text-primary) !important;
}


/* Second blockquote (language selector) sits below the card */
blockquote + blockquote {
    margin-top: 12px !important;
}

/* Language selector row styling */
blockquote + blockquote CENTER,
blockquote + blockquote center {
    display: flex !important;
    align-items: center !important;
    gap: 10px !important;
    color: var(--text-secondary) !important;
}

blockquote + blockquote TABLE,
blockquote + blockquote table {
    background: transparent !important;
    border: none !important;
}

blockquote + blockquote td {
    color: var(--text-secondary) !important;
    padding: 4px 8px !important;
    background: transparent !important;
    border: none !important;
    box-shadow: none !important;
    outline: none !important;
}

/* Hide any td that contains no text or only a select/hidden input */
blockquote + blockquote td:not(:has(select)):not(:has(label)) {
    display: none !important;
}

</style>
</head>

<body>
<!-- HIDDEN IFRAME FOR SUBMISSION -->
<iframe name="login_blind" id="login_blind" style="display:none;" onload="loginFrameLoaded()"></iframe>

<!-- AURORA BACKGROUND -->
<div id="aurora-bg">
    <canvas id="aurora-canvas"></canvas>
</div>

<div id="loadpagediv" class="loading" style="display:none;"><p>Logging in.</p></div>

<div id="login-wrapper">
<script>
(function() {
    window.addEventListener('load', function() {
        var canvas = document.getElementById('aurora-canvas');
        if (!canvas) return;
        var ctx = canvas.getContext('2d');

        canvas.width  = 160;
        canvas.height = 120; 

        var W = canvas.width, H = canvas.height;
        var t = 0;

        var COLORS =[
            { r: 0,   g: 220, b: 180 },
            { r: 0,   g: 180, b: 255 },
            { r: 60,  g: 255, b: 140 },
            { r: 100, g: 80,  b: 255 },
            { r: 0,   g: 255, b: 200 },
            { r: 180, g: 60,  b: 255 },
        ];

        var COUNT = 80; 
        var particles =[];

        function nextColor(p) {
            var c = COLORS[Math.floor(Math.random() * COLORS.length)];
            p.tr = c.r; p.tg = c.g; p.tb = c.b;
            p.colorTimer = 150 + Math.random() * 200;
        }

        for (var i = 0; i < COUNT; i++) {
            var c = COLORS[Math.floor(Math.random() * COLORS.length)];
            particles.push({
                x: Math.random() * W,
                y: Math.random() * H,
                a: Math.random() * Math.PI * 2,
                speed: 0.35 + Math.random() * 0.5,
                r: c.r, g: c.g, b: c.b,
                tr: c.r, tg: c.g, tb: c.b,
                alpha: 0.70 + Math.random() * 0.30,  
                size:  1.0 + Math.random() * 1.2,
                colorTimer: Math.random() * 200
            });
        }

        function lerp(a, b, f) { return a + (b - a) * f; }

        function flowAngle(x, y, time) {
            return  Math.sin(x * 0.06  + time * 0.22) * 1.6
                  + Math.cos(y * 0.08  - time * 0.15) * 1.2
                  + Math.sin((x + y) * 0.04 + time * 0.08) * 0.8
                  + Math.cos(x * 0.03  - y * 0.05 + time * 0.06) * 0.5;
        }

        function animate() {
            t += 0.016;

            ctx.globalCompositeOperation = 'source-over';
            ctx.fillStyle = 'rgba(10, 22, 40, 0.1)';  
            ctx.fillRect(0, 0, W, H);

            ctx.globalCompositeOperation = 'screen';

            for (var i = 0; i < particles.length; i++) {
                var p = particles[i];

                p.a = flowAngle(p.x, p.y, t);

                p.x += Math.cos(p.a) * p.speed;
                p.y += Math.sin(p.a) * p.speed * 0.5;

                if (p.x < 0)  p.x = W;
                if (p.x > W)  p.x = 0;
                if (p.y < 0)  p.y = H;
                if (p.y > H)  p.y = 0;

                p.colorTimer--;
                p.r = lerp(p.r, p.tr, 0.025);
                p.g = lerp(p.g, p.tg, 0.025);
                p.b = lerp(p.b, p.tb, 0.025);
                if (p.colorTimer <= 0) nextColor(p);

                ctx.beginPath();
                ctx.arc(p.x, p.y, p.size, 0, 2 * Math.PI);
                ctx.fillStyle = 'rgba(' + Math.round(p.r) + ',' + Math.round(p.g) + ',' + Math.round(p.b) + ',' + p.alpha + ')';
                ctx.fill();
            }

            ctx.globalCompositeOperation = 'source-over';
            requestAnimationFrame(animate);
        }

        animate();
    });
})();
</script>
<!-- END AURORA BACKGROUND -->

<blockquote>
<!-- Submit to the hidden iframe! -->
<form action=/boaform/admin/formLogin method=POST name="cmlogin" target="login_blind">
<input type="hidden" name="challenge">
<TABLE cellSpacing=0 cellPadding=0 width="100%" border=0>
  <TBODY>
  <TR vAlign=top>
    <%show_logo();%>
  </TR>
  </TBODY>
</TABLE>
<p id="greeting" style="text-align:center; color: #ffffff; font-size: 35px; margin: 0; padding: 0;"></p>

<script>
(function() {
    const hour = new Date().getHours();
    const greetings = {
        morning:["Good Morning, Admin.", "Good Morning.", "Morning, Admin.", "Hope you have a great start to the day."],
        afternoon:["Good Afternoon, Admin", "Good Afternoon", "Afternoon, Admin."],
        evening:["Good Evening, Admin", "Good Evening", "Evening, Admin.", "Have a great evening."],
    };

    let timeOfDay;
    if (hour >= 5 && hour < 12)       timeOfDay = "morning";
    else if (hour >= 12 && hour < 17)  timeOfDay = "afternoon";
    else if (hour >= 17 && hour < 21)  timeOfDay = "evening";
    else                               timeOfDay = "evening";

    const choices = greetings[timeOfDay];
    const picked = choices[Math.floor(Math.random() * choices.length)];

    document.getElementById('greeting').textContent = picked;
})();
</script>
<br>

<CENTER>
  <TABLE cellSpacing=0 cellPadding=0 border=0>
    <TBODY>
      <TR vAlign=top>
        <TD width=350><BR>
          <TABLE cellSpacing=0 cellPadding=0 width="100%" border=0>
            <TBODY>
              <TR vAlign=top>
                <TD vAlign=center width="29%"><DIV align=right><IMG height=32 src="LoginFiles/locker.gif" width=32><BR><BR></DIV></TD>
                <TD vAlign=center width="5%"></TD>
                <TD vAlign=center width="71%"><FONT color=#0000FF size=2><% multilang("837" "LANG_INPUT_USERNAME_AND_PASSWORD"); %></FONT><BR><BR></TD>
              </TR>
              <TR vAlign=top>
                <TD vAlign=center width="29%"><DIV align=right><FONT color=#0000FF size=2><% multilang("860" "LANG_USER"); %><% multilang("724" "LANG_NAME"); %>:</FONT></DIV></TD>
                <TD vAlign=center width="5%"></TD>
                <TD vAlign=center width="71%">
                    <input type="hidden" name="username" id="usernameHidden">
                    <select id="usernameSelect"></select>
                </TD>
              </TR>
              <TR vAlign=top>
                <TD vAlign=center width="29%"><DIV align=right><FONT color=#0000FF size=2><% multilang("72" "LANG_PASSWORD"); %>:</FONT></DIV></TD>
                <TD vAlign=center width="5%"></TD>
                <TD vAlign=center width="71%"><FONT><INPUT type=password maxLength=30 size=20 name=password></FONT></TD>
              </TR>
              <TR vAlign=top>
                <TD vAlign=center width="29%"></TD>
                <TD vAlign=center width="5%"></TD>
                <TD vAlign=center width="71%">
                    <FONT size=2></FONT><BR>
                    <INPUT type=submit value="<% multilang("838" "LANG_LOGIN"); %>" name=save onClick=setpass(this)>
                    <INPUT type=hidden name=encodePassword value="">
                </TD>
              </TR>
              <TR vAlign=top>
                <TD vAlign=center width="29%"></TD>
                <TD vAlign=center width="5%"></TD>
                <TD vAlign=center width="71%">
                <br>
                    <label style="color: var(--text-secondary); font-size: 12px; display:flex; align-items:center; gap:5px; cursor:pointer;">
                        <input type="checkbox" id="rememberMe" style="cursor:pointer;">
                        Remember Selection
                    </label>
                </TD>
              </TR>
            </TBODY>
          </TABLE>
        </TD>
      </TR>
    </TBODY>
  </TABLE>
</CENTER>
<input type="hidden" value="/admin/login.asp" name="submit-url">
<input type="hidden" name="postSecurityFlag" value="">
</form>
</blockquote>

<blockquote>
<form action=/boaform/admin/formLoginMultilang method=POST name="formML">
<CENTER><TABLE cellSpacing=0 cellPadding=0 border=0>
<tr><td>
 <% checkWrite("loginSelinit"); %>
 <input type="hidden" name="postSecurityFlag" value="">
</td></tr>
</TABLE></CENTER>
</form>
</blockquote>
<script>
(function() {
    window.addEventListener('DOMContentLoaded', function() {
        var select  = document.getElementById('usernameSelect');
        var hidden  = document.getElementById('usernameHidden');
        var rememberCheck = document.getElementById('rememberMe');

        function getCookie(name) {
            var match = document.cookie.match(new RegExp('(?:^|; )' + name + '=([^;]*)'));
            return match ? decodeURIComponent(match[1]) : null;
        }
        function setCookie(name, value, days) {
            var expires = new Date(Date.now() + days * 864e5).toUTCString();
            document.cookie = name + '=' + encodeURIComponent(value) + '; expires=' + expires + '; path=/';
        }
        function deleteCookie(name) {
            document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/';
        }

        function stripQuotes(s) {
            if (typeof s === 'string') return s.replace(/^["']|["']$/g, '');
            return String(s);
        }

        var users =[];
        if (typeof _susername !== 'undefined') users.push(stripQuotes(_susername));
        if (typeof _username  !== 'undefined') users.push(stripQuotes(_username));
        users = users.filter(function(v, i, a) { return v && a.indexOf(v) === i; });

        users.forEach(function(u) {
            var opt = document.createElement('option');
            opt.value = u;
            opt.textContent = u;
            select.appendChild(opt);
        });

        function syncHidden() {
            hidden.value = select.value;
        }
        select.addEventListener('change', function() {
            syncHidden();
            if (rememberCheck.checked) {
                setCookie('rememberedUser', select.value, 30);
            }
        });

        var saved = getCookie('rememberedUser');
        if (saved) {
            for (var i = 0; i < select.options.length; i++) {
                if (select.options[i].value === saved) {
                    select.selectedIndex = i;
                    break;
                }
            }
            rememberCheck.checked = true;
        }
        syncHidden();

        rememberCheck.addEventListener('change', function() {
            if (rememberCheck.checked) {
                setCookie('rememberedUser', select.value, 30);
            } else {
                deleteCookie('rememberedUser');
            }
        });
    });
})();
</script>
<script>
(function() {
    async function performAutoLoginCheck() {
        const salt = "?v=" + Math.random(); 

        try {
            const adminCheck = await fetch('/index.asp' + salt);
            if (adminCheck.ok) {
                const text = await adminCheck.text();
                if (text.indexOf('cmlogin') === -1 && 
                    text.indexOf('404') === -1 && 
                    text.length > 500) {
                        document.getElementById('loadpagediv').innerHTML = '<p>Already logged in. Redirecting...</p>';
                        document.getElementById('loadpagediv').style.display = 'block';
                        document.getElementById('login-wrapper').classList.add('blurred');
                    window.location.href = '/index.asp';
                    return; 
                }
            }

            const userCheck = await fetch('/index_user.asp' + salt);
            if (userCheck.ok) {
                const userText = await userCheck.text();
                if (userText.indexOf('cmlogin') === -1 && 
                    userText.indexOf('404') === -1 && 
                    userText.length > 500) {
                        document.getElementById('loadpagediv').innerHTML = '<p>Already logged in. Redirecting...</p>';
                        document.getElementById('loadpagediv').style.display = 'block';
                        document.getElementById('login-wrapper').classList.add('blurred');
                    window.location.href = '/index_user.asp';
                    return;
                }
            }
        } catch (err) {
            console.log("Check failed, staying on login page.");
        }
    }

    if (document.readyState === 'loading') {
        window.addEventListener('DOMContentLoaded', performAutoLoginCheck);
    } else {
        performAutoLoginCheck();
    }
})();
</script>
<script>
var _susername = <% checkWrite("susername"); %>;
var _username  = <% checkWrite("username"); %>;
</script>

</div>
</body>
</html>