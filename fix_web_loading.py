path = 'web/index.html'
content = open(path).read()

loading_css = '''  <style>
    #app-loading {
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      background: #0B0B10;
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 9999;
    }
    #app-loading .spinner {
      width: 36px;
      height: 36px;
      border: 3px solid rgba(255,255,255,0.15);
      border-top-color: #6C5CE7;
      border-radius: 50%;
      animation: app-spin 0.8s linear infinite;
    }
    @keyframes app-spin {
      to { transform: rotate(360deg); }
    }
  </style>'''

if 'app-loading' not in content:
    content = content.replace('</head>', loading_css + '\n</head>')

loading_html = '''  <div id="app-loading"><div class="spinner"></div></div>
  <script>
    window.addEventListener('flutter-first-frame', function () {
      var el = document.getElementById('app-loading');
      if (el) el.remove();
    });
    setTimeout(function () {
      var el = document.getElementById('app-loading');
      if (el) el.remove();
    }, 15000);
  </script>'''

if 'app-loading' not in (content.split('<body>')[1] if '<body>' in content else content):
    content = content.replace('<body>', '<body>\n' + loading_html)

open(path, 'w').write(content)
print("LIGHTWEIGHT LOADING SCREEN ADDED")
