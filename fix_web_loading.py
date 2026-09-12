path = 'web/index.html'
content = open(path).read()

# 1. Add CSS for custom loading screen in <head>
loading_css = '''  <style>
    #app-loading {
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      background: #0B0B10;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      z-index: 9999;
    }
    #app-loading .spinner {
      width: 48px;
      height: 48px;
      border: 4px solid rgba(255,255,255,0.15);
      border-top-color: #6C5CE7;
      border-radius: 50%;
      animation: app-spin 0.8s linear infinite;
    }
    #app-loading .brand {
      margin-top: 16px;
      color: #ffffff;
      font-family: sans-serif;
      font-size: 16px;
      font-weight: 600;
      letter-spacing: 1px;
    }
    @keyframes app-spin {
      to { transform: rotate(360deg); }
    }
  </style>'''

if 'app-loading' not in content:
    content = content.replace('</head>', loading_css + '\n</head>')

# 2. Add loading div + hide script right after <body>
loading_html = '''  <div id="app-loading">
    <div class="spinner"></div>
    <div class="brand">MYGame</div>
  </div>
  <script>
    window.addEventListener('flutter-first-frame', function () {
      var el = document.getElementById('app-loading');
      if (el) { el.style.transition = 'opacity 0.3s'; el.style.opacity = '0'; setTimeout(function(){ el.remove(); }, 300); }
    });
    // fallback in case the event never fires
    setTimeout(function () {
      var el = document.getElementById('app-loading');
      if (el) el.remove();
    }, 8000);
  </script>'''

if 'app-loading' not in content.split('<body>')[1] if '<body>' in content else True:
    content = content.replace('<body>', '<body>\n' + loading_html)

open(path, 'w').write(content)
print("LOADING SCREEN ADDED")
