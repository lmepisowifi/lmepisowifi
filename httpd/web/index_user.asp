<!DOCTYPE HTML>
<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=utf-8">
<TITLE><% multilang("3314" "LANG_TITLE"); %></TITLE>
 <link rel="stylesheet" href="admin/style.css">
 <link rel="stylesheet" href="admin/reset.css" />
 <link rel="stylesheet" href="admin/base.css" />
 <link href="favicon.ico" type="image/x-icon" rel="shortcut icon" />
    <script src="admin/jquip_sizzle.js" type="text/javascript" ></script>
    <script src="admin/jquip.js" type="text/javascript" ></script>
    <script src="admin/juicer.js" type="text/javascript" ></script>
    <script src="admin/ui.js" type="text/javascript" ></script>
<style>
#loadpagediv.no-spinner::before,
#loadpagediv.no-spinner::after { display: none !important; }

/* Shade overlay - semi-transparent only, no backdrop-filter here */
#shade {
    background: rgba(0, 0, 0, 0.4) !important;
    pointer-events: auto;
}

/* Blur is applied directly to the wrapper content behind the shade */
#wrapper.blurred {
    -webkit-filter: blur(5px);
    filter: blur(5px);
    -webkit-transition: -webkit-filter 0.15s ease, filter 0.15s ease;
    transition: -webkit-filter 0.15s ease, filter 0.15s ease;
}
#wrapper {
    -webkit-transition: -webkit-filter 0.15s ease, filter 0.15s ease;
    transition: -webkit-filter 0.15s ease, filter 0.15s ease;
}

<!-- In <style> block, replace the flowfield CSS -->
.header-canvas-container {
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    z-index: 0;
    pointer-events: none;
    background: #060d18;
    overflow: hidden;
}

.flowfield {
    display: block;
    position: absolute;
    top: 50%; left: 50%;
    /* Low-res canvas blown up — the blur smooths pixel edges into soft aurora bands */
    width: 12.5%;
    transform: translate(-50%, -50%) scale(8);
    filter: blur(4px) saturate(1.4);
    opacity: 0.85;
}

.header-text-container {
    position: relative;
    z-index: 10;
    float: right;
    margin-top: 15px;
    margin-right: 20px;
}
.header-text-container td {
    color: #ffffff !important;
    font-weight: bold;
    text-align: right;
    text-shadow: 0 0 8px rgba(0,0,0,0.9), 1px 1px 3px rgba(0,0,0,0.8);
}
</style>
<script>
document.write("<s"+"cript type='text/javascript' src='/admin/userMenu.js?v="+Math.random()+"'></scr"+"ipt>");
</script>
    <script type="text/javascript" src="admin/init.js"></script>
    <script id="nav-tmpl" type="text/template">
        {@each items as item}
            <li><a href="javascript:void(0)" rel="${item.sub}" class="">${item.name}</a><span></span></li>
        {@/each}
    </script>
    <script id="side-tmpl" type="text/x-template">
        {@each items as item}
            <li class="{@if item.collapsed}collapsed{@/if}">
                <h3><a href="#">${item.name}</a></h3>
                <ul>
                    {@each item.items as it}
                        <li><a target="contentIframe" href="${it.href}" class="">${it.name}</a></li>
                    {@/each}
                </ul>
            </li>
        {@/each}
    </script>
 <script>
// --- START FLOWFIELD SCRIPT ---
// Replace the START FLOWFIELD SCRIPT block
window.addEventListener('load', function() {
    var canvas = document.getElementById('flowfield');
    if (!canvas) return;
    var ctx = canvas.getContext('2d');

    // Low internal resolution — CSS scale(8)+blur does the magic
    canvas.width  = 160;
    canvas.height = 48;

    var W = canvas.width, H = canvas.height;
    var t = 0;

    // Aurora color palette: each particle gets a hue that slowly drifts
    var COLORS = [
        { r: 0,   g: 220, b: 180 },  // teal-green
        { r: 0,   g: 180, b: 255 },  // ice blue
        { r: 60,  g: 255, b: 140 },  // lime
        { r: 100, g: 80,  b: 255 },  // violet
        { r: 0,   g: 255, b: 200 },  // aqua
        { r: 180, g: 60,  b: 255 },  // purple
    ];

    // Build particles
    var COUNT = 55;
    var particles = [];
    for (var i = 0; i < COUNT; i++) {
        var c = COLORS[Math.floor(Math.random() * COLORS.length)];
        particles.push({
            x:     Math.random() * W,
            y:     Math.random() * H,
            a:     Math.random() * Math.PI * 2,
            speed: 0.4 + Math.random() * 0.5,
            r: c.r, g: c.g, b: c.b,
            // Each particle slowly shifts toward a target color
            tr: c.r, tg: c.g, tb: c.b,
            alpha: 0.6 + Math.random() * 0.4,
            size:  1.0 + Math.random() * 1.0,
            colorTimer: Math.random() * 200
        });
    }

    function nextColor(p) {
        var c = COLORS[Math.floor(Math.random() * COLORS.length)];
        p.tr = c.r; p.tg = c.g; p.tb = c.b;
        p.colorTimer = 150 + Math.random() * 200;
    }

    function lerp(a, b, f) { return a + (b - a) * f; }

    function flowAngle(x, y, time) {
        // Layered sines — gives the slow curl and horizontal drift of real aurora
        return  Math.sin(x * 0.06  + time * 0.22) * 1.6
              + Math.cos(y * 0.10  - time * 0.15) * 1.0
              + Math.sin((x + y) * 0.04 + time * 0.08) * 0.7
              + Math.cos(x * 0.02  - time * 0.05) * 0.4;
    }

    function animate() {
        t += 0.018;

        // Fade trail — controls how long the glow persists
        ctx.fillStyle = 'rgba(6, 13, 24, 0.18)';
        ctx.fillRect(0, 0, W, H);

        ctx.globalCompositeOperation = 'screen';

        for (var i = 0; i < particles.length; i++) {
            var p = particles[i];

            // Update angle from flow field
            p.a = flowAngle(p.x, p.y, t);

            // Bias horizontal movement — aurora stretches sideways
            p.x += Math.cos(p.a) * p.speed;
            p.y += Math.sin(p.a) * p.speed * 0.28;

            // Wrap around edges
            if (p.x < 0)  p.x = W;
            if (p.x > W)  p.x = 0;
            if (p.y < 0)  p.y = H;
            if (p.y > H)  p.y = 0;

            // Gradually lerp toward target color
            p.colorTimer--;
            var cf = 0.03;
            p.r = lerp(p.r, p.tr, cf);
            p.g = lerp(p.g, p.tg, cf);
            p.b = lerp(p.b, p.tb, cf);
            if (p.colorTimer <= 0) nextColor(p);

            var r = Math.round(p.r), g = Math.round(p.g), b = Math.round(p.b);
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, 2 * Math.PI);
            ctx.fillStyle = 'rgba(' + r + ',' + g + ',' + b + ',' + p.alpha + ')';
            ctx.fill();
        }

        ctx.globalCompositeOperation = 'source-over';
        requestAnimationFrame(animate);
    }

    animate();
});
      function confirmlogout()
      {
       if ( !confirm('do you confirm to logout?') ) {
      return false;
      }
      else
   {
     return true;
   }
     }
var rebooting = false;

function cleanload() {
    if (rebooting) return;

    try {
        var iframe = document.getElementById('contentIframe');
        var doc = iframe.contentDocument || iframe.contentWindow.document;
        var body = doc && doc.body ? doc.body.innerHTML : '';

        // 1. CHANGE SETTINGS MESSAGE
        if (body.indexOf('Change setting successfully!') !== -1) {
            iframe.style.visibility = 'hidden';
            document.getElementById('loadpagediv').querySelector('p').textContent = 'Changes applied.';
            document.getElementById('shade').style.display = 'block'; setBlur(true);
            document.getElementById('loadpagediv').style.display = 'block';

            var okBtn = doc.querySelector('input[type="button"]');
            if (okBtn) okBtn.click();

            iframe.addEventListener('load', function onNextLoad() {
                iframe.removeEventListener('load', onNextLoad);
                iframe.style.visibility = '';
                document.getElementById('shade').style.display = 'none'; setBlur(false);
                document.getElementById('loadpagediv').style.display = 'none';
                document.getElementById('loadpagediv').querySelector('p').textContent = 'Applying Changes.';
                try {
                    var height = iframe.contentWindow.document.body.scrollHeight;
                    if (height > 0) iframe.style.height = height + 'px';
                    
                    if (iframe.contentWindow && typeof iframe.contentWindow.checkSpeedWarning === 'function') {
                        setTimeout(function() {
                            iframe.contentWindow.checkSpeedWarning();
                            var newHeight = iframe.contentWindow.document.body.scrollHeight;
                            if (newHeight > 0) iframe.style.height = newHeight + 'px';
                        }, 150);
                    }
                } catch(e) {}
            });
            return;
        }
        
        // 2. CONNECTED SUCCESSFULLY MESSAGE
        if (body.indexOf('Connect successfully!') !== -1) {
            iframe.style.visibility = 'hidden';
            var loadDiv = document.getElementById('loadpagediv');
            
            // HIDE THE LOADING ICON
            loadDiv.className = 'no-spinner'; 
            
            loadDiv.querySelector('p').textContent = 'Successfully connected to WiFi Network, you can view the status in the wlan status.';
            
            var customOkBtn = document.createElement('input');
            customOkBtn.type = 'button';
            customOkBtn.value = 'OK';
            customOkBtn.className = 'link_bg'; 
            customOkBtn.style.marginTop = '15px';
            customOkBtn.style.cursor = 'pointer';

            customOkBtn.onclick = function() {
                customOkBtn.style.display = 'none'; 
                // RESTORE THE LOADING ICON AND TEXT
                loadDiv.className = 'loading'; 
                loadDiv.querySelector('p').textContent = 'Applying Changes...'; 
                var iframeOkBtn = doc.querySelector('input[type="button"]');
                if (iframeOkBtn) iframeOkBtn.click();
            };

            loadDiv.appendChild(customOkBtn); 

            document.getElementById('shade').style.display = 'block'; setBlur(true);
            loadDiv.style.display = 'block';

            iframe.addEventListener('load', function onNextLoad() {
                iframe.removeEventListener('load', onNextLoad);
                iframe.style.visibility = '';
                document.getElementById('shade').style.display = 'none'; setBlur(false);
                loadDiv.style.display = 'none';
                
                // RESET TO DEFAULT FOR FUTURE USE
                loadDiv.className = 'loading'; 
                loadDiv.querySelector('p').textContent = 'Applying Changes.';
                
                if (customOkBtn.parentNode) {
                    customOkBtn.parentNode.removeChild(customOkBtn);
                }

                try {
                    var height = iframe.contentWindow.document.body.scrollHeight;
                    if (height > 0) iframe.style.height = height + 'px';
                } catch(e) {}
            });
            return;
        }
        
        // 3. CONNECTION FAILED MESSAGE
        if (body.indexOf('Connect failed 4!') !== -1) {
            iframe.style.visibility = 'hidden';
            var loadDiv = document.getElementById('loadpagediv');
            
            // HIDE THE LOADING ICON
            loadDiv.className = 'no-spinner'; 
            
            loadDiv.querySelector('p').textContent = 'Failed to connect to the WiFi Network, the password was incorrect.';
            
            var customErrBtn = document.createElement('input');
            customErrBtn.type = 'button';
            customErrBtn.value = 'OK';
            customErrBtn.className = 'link_bg';
            customErrBtn.style.marginTop = '15px';
            customErrBtn.style.cursor = 'pointer';

            customErrBtn.onclick = function() {
                customErrBtn.style.display = 'none';
                // RESTORE THE LOADING ICON AND TEXT
                loadDiv.className = 'loading'; 
                loadDiv.querySelector('p').textContent = 'Applying Changes...';
                var iframeOkBtn = doc.querySelector('input[type="button"]');
                if (iframeOkBtn) iframeOkBtn.click();
            };

            loadDiv.appendChild(customErrBtn);

            document.getElementById('shade').style.display = 'block'; setBlur(true);
            loadDiv.style.display = 'block';

            iframe.addEventListener('load', function onNextLoad() {
                iframe.removeEventListener('load', onNextLoad);
                iframe.style.visibility = '';
                document.getElementById('shade').style.display = 'none'; setBlur(false);
                loadDiv.style.display = 'none';
                
                // RESET TO DEFAULT FOR FUTURE USE
                loadDiv.className = 'loading'; 
                loadDiv.querySelector('p').textContent = 'Applying Changes.';
                
                if (customErrBtn.parentNode) {
                    customErrBtn.parentNode.removeChild(customErrBtn);
                }

                try {
                    var height = iframe.contentWindow.document.body.scrollHeight;
                    if (height > 0) iframe.style.height = height + 'px';
                } catch(e) {}
            });
            return;
        }

        if (body.indexOf('You have not logined') !== -1) {
            iframe.style.visibility = 'hidden';
            top.window.location.href = '/admin/login.asp';
            return;
        }

    } catch(e) {}

    // Normal cleanload
    document.getElementById('shade').style.display = 'none'; setBlur(false);
    document.getElementById('loadpagediv').style.display = 'none';

    try {
        var iframe = document.getElementById('contentIframe');
        
        var height = iframe.contentWindow.document.body.scrollHeight;
        if (height > 0) iframe.style.height = height + 'px';
        
        if (iframe.contentWindow && typeof iframe.contentWindow.checkSpeedWarning === 'function') {
            setTimeout(function() {
                iframe.contentWindow.checkSpeedWarning();
                var newHeight = iframe.contentWindow.document.body.scrollHeight;
                if (newHeight > 0) iframe.style.height = newHeight + 'px';
            }, 150);
        }
    } catch(e) {}
}

function setBlur(on) {
    var wrapper = document.getElementById('wrapper');
    if (!wrapper) return;
    if (on) {
        wrapper.classList.add('blurred');
    } else {
        wrapper.classList.remove('blurred');
    }
}

// Auto-trigger blur whenever shade is shown/hidden by any child page
document.addEventListener("DOMContentLoaded", function() {
    var shade = document.getElementById('shade');
    if (!shade) return;
    var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.attributeName === 'style') {
                setBlur(shade.style.display !== 'none' && shade.style.display !== '');
            }
        });
    });
    observer.observe(shade, { attributes: true, attributeFilter: ['style'] });
});

function pollSession() {
    if (rebooting) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', '/admin/status.asp', true);
    xhr.onload = function() {
        if (xhr.status === 200) {
            var finalUrl = xhr.responseURL || '';
            var text = xhr.responseText;
            if (finalUrl.indexOf('login.asp') !== -1 ||
                text.indexOf('You have not logined') !== -1 ||
                text.indexOf('name="loginusr"') !== -1 ||
                text.indexOf('formLogin') !== -1) {
                top.window.location.href = '/admin/login.asp';
                return;
            }
        }
        setTimeout(pollSession, 2000);
    };
    xhr.onerror = function() {
        setTimeout(pollSession, 2000);
    };
    xhr.send();
}

setTimeout(pollSession, 2000);
    </script>
</head>
<body>
<div id="shade"></div>
<div id="loadpagediv" class="loading" style="display:none;">
<p>Applying Changes.</p></div>
<div id="wrapper">
    <div id="header">
  <!-- ADDED: position relative and overflow hidden -->
  <div class="top_bg" style="position: relative; overflow: hidden;">
    
    <!-- ADDED: The new Animated Flowfield background -->
    <div class="header-canvas-container">
        <canvas id="flowfield" class="flowfield"></canvas>
    </div>

    <div style="position:absolute; left:0px; top:0px; border:#000 solid 0px;"></div>
    
    <!-- WRAPPED AND CLEANED: The top right info text -->
    <table class="header-text-container">
      <tr><td>Firmware: <% getInfo("fwVersion"); %>&nbsp;&nbsp;</td></tr>
      <tr><td>Logged in as: <% checkWrite("username"); %>&nbsp;&nbsp;</td></tr>
      <tr><td>
      <form action=/boaform/admin/formLogout method=POST name="cmlogout">
          <input type="submit" value="Logout?" name="save" style="color:#ffffff;text-decoration:underline;cursor:pointer;border:0px;background:transparent; font-weight:bold; text-shadow: 1px 1px 3px rgba(0,0,0,0.8); margin-right:7.5px;">
          <input type="hidden" value="/admin/login.asp" name="submit-url">
      </form>
      </td></tr>
    </table>
    <!-- Clearfix so the floating table doesn't break layout -->
    <div style="clear: both;"></div>
    
  </div>
  
 <div class="nav_side clearfix">
            <div class="nav_left"></div>
            <ul id="nav"></ul>
            <div class="nav_right"></div>
        </div>
    </div>
    <div id="main" class="clearfix">
  <div id="side_wrapper">
   <div class="box_wrapper">
    <h3 class="box_top"></h3>
    <div class="box_content">
     <ul id="side"></ul>
    </div>
   </div>
   <div class="box_wrapper none" id="attention">
    <h3 class="box_top"></h3>
    <div class="box_content">
      <div class="page_confirm">
      <form name="formAttensave" method="POST" action="form2AttenSave.cgi">
       <div class="page_confirm">
        <p>Attention Config is modified to make it effective forever!</p>
        <input type="submit" value="save" class="link_bg" />
        <input type="hidden" name="submit.htm?index.htm" value="Send"/>
       </div>
      </form>
      </div>
    </div>
   </div>
  </div>
        <div id="content">
            <iframe src="#" frameborder="0" name="contentIframe" id="contentIframe" scrolling="no" onload="cleanload()"></iframe>
        </div>
    </div>
</div>
</body>
</html>