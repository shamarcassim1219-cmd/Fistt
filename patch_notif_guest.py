import os, re, sys
p = 'lib/screens/notifications_screen.dart'
s = open(p, encoding='utf-8').read()
if '_guestView' in s:
    sys.exit('already patched')

def rep(old, new):
    global s
    if s.count(old) != 1:
        sys.exit('anchor not found (%d): %s' % (s.count(old), old.strip()[:60]))
    s = s.replace(old, new)

# where is requireLogin defined? make sure it is imported here
defin = None
for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            fp = os.path.join(root, f)
            if re.search(r'Future<bool>\s+requireLogin\s*\(', open(fp, encoding='utf-8').read()):
                defin = fp.replace(os.sep, '/')
if defin is None:
    sys.exit('requireLogin definition not found')
rel = defin[len('lib/'):]
imp = "import '%s';" % (os.path.basename(defin) if defin.startswith('lib/screens/') else '../' + rel)
if imp not in s:
    s = s.replace("import 'package:flutter/material.dart';\n", "import 'package:flutter/material.dart';\n" + imp + "\n", 1)
sp = "import 'package:shared_preferences/shared_preferences.dart';"
if sp not in s:
    s = s.replace("import 'package:flutter/material.dart';\n", "import 'package:flutter/material.dart';\n" + sp + "\n", 1)

rep("  bool _loading = true;\n  String? _error;\n", "  bool _loading = true;\n  bool _guest = false;\n  String? _error;\n")

rep("  Future<void> _load() async {\n    try {\n",
"""  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('is_logged_in') ?? false)) {
      if (mounted) setState(() { _guest = true; _loading = false; });
      return;
    }
    try {
""")

guest = """  Widget _guestView() {
    final t = _guestTxt[_gLang()]!;
    return Scaffold(
      appBar: Navigator.of(context).canPop() ? AppBar(title: Text(t['title']!)) : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(t['msg']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  if (await requireLogin(context, reason: t['msg']!)) {
                    if (!mounted) return;
                    setState(() { _guest = false; _loading = true; });
                    _load();
                  }
                },
                icon: const Icon(Icons.login),
                label: Text(t['btn']!),
              ),
            ],
          ),
        ),
      ),
    );
  }

"""
m = re.findall(r'  @override\n  Widget build\(BuildContext context\) \{\n', s)
if len(m) != 1:
    sys.exit('build() anchor count = %d, paste the build method' % len(m))
rep("  @override\n  Widget build(BuildContext context) {\n",
    guest + "  @override\n  Widget build(BuildContext context) {\n    if (_guest) return _guestView();\n")

s = s.rstrip('\n') + """

String _gLang() {
  final l = AppLocalizations.currentLanguage.value.toLowerCase();
  if (l.startsWith('si') || l.contains('සිං')) return 'si';
  if (l.startsWith('ta') || l.contains('தம')) return 'ta';
  return 'en';
}

const Map<String, Map<String, String>> _guestTxt = {
  'en': {'title': 'Notifications', 'msg': 'Login to see your notifications', 'btn': 'Login'},
  'si': {'title': 'දැනුම්දීම්', 'msg': 'ඔබේ දැනුම්දීම් බැලීමට ලොගින් වන්න', 'btn': 'ලොගින් වන්න'},
  'ta': {'title': 'அறிவிப்புகள்', 'msg': 'உங்கள் அறிவிப்புகளைப் பார்க்க உள்நுழையவும்', 'btn': 'உள்நுழை'},
};
"""
open(p, 'w', encoding='utf-8').write(s)
print('patched (requireLogin from %s)' % defin)
