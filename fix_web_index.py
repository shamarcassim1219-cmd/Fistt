with open('web/index.html', 'r') as f:
    content = f.read()

meta_tag = '  <meta name="google-signin-client_id" content="354593690287-4snsdmlt1ij5q7a1grbadb28b5g5nm67.apps.googleusercontent.com">\n'

if 'google-signin-client_id' not in content:
    content = content.replace('<head>', '<head>\n' + meta_tag, 1)
    with open('web/index.html', 'w') as f:
        f.write(content)
    print("META TAG ADDED")
else:
    print("ALREADY EXISTS")
