content = open('lib/screens/login_screen.dart').read()

old = '''      final googleSignIn = GoogleSignIn(
        serverClientId: '354593690287-4snsdmlt1ij5q7a1grbadb28b5g5nm67.apps.googleusercontent.com',
      );'''

new = '''      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '354593690287-4snsdmlt1ij5q7a1grbadb28b5g5nm67.apps.googleusercontent.com' : null,
        serverClientId: kIsWeb ? null : '354593690287-4snsdmlt1ij5q7a1grbadb28b5g5nm67.apps.googleusercontent.com',
      );'''

if old in content:
    content = content.replace(old, new)
    open('lib/screens/login_screen.dart', 'w').write(content)
    print("REPLACED OK")
else:
    print("NOT FOUND")
