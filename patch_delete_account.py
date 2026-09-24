import re, sys
# ---------- api_service.dart ----------
p = 'lib/services/api_service.dart'
s = open(p, encoding='utf-8').read()
a = "  static Future<List<dynamic>> getMoreTools() async {"
fn = """  static Future<void> deleteAccount(String secret) async {
    final res = await http.post(
      Uri.parse('$baseUrl/account/delete'),
      headers: await _headers(),
      body: jsonEncode({'password': secret, 'confirm': secret}),
    );
    await _handle(res);
  }

"""
if 'deleteAccount(' in s:
    print('api_service: already patched')
elif s.count(a) == 1:
    open(p, 'w', encoding='utf-8').write(s.replace(a, fn + a))
    print('api_service: patched')
else:
    sys.exit('api_service: anchor not found')

# ---------- settings_screen.dart ----------
p = 'lib/screens/settings_screen.dart'
s = open(p, encoding='utf-8').read()
if '_confirmDeleteAccount' in s:
    sys.exit('settings: already patched')

old_btn = "? OutlinedButton.icon(onPressed: _confirmLogout, icon: const Icon(Icons.logout), label: Text(AppLocalizations.t('logout')))"
new_btn = """? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(onPressed: _confirmLogout, icon: const Icon(Icons.logout), label: Text(AppLocalizations.t('logout'))),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _confirmDeleteAccount,
                              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                              label: Text(_delTxt[_delLang()]!['btn']!, style: const TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        )"""
anchor = "  Future<void> _logout() async {"
method = """  Future<void> _confirmDeleteAccount() async {
    final t = _delTxt[_delLang()]!;
    final ctrl = TextEditingController();
    bool hide = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(t['title']!, style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['body']!, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  obscureText: hide,
                  decoration: InputDecoration(
                    labelText: t['hint'],
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(hide ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setD(() => hide = !hide),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t['cancel']!)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t['confirm']!, style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
    final secret = ctrl.text;
    if (ok != true || secret.isEmpty) return;
    try {
      await ApiService.deleteAccount(secret);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['done']!)));
      await _logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

"""
tail = """

String _delLang() {
  final l = AppLocalizations.currentLanguage.value.toLowerCase();
  if (l.startsWith('si') || l.contains('සිං')) return 'si';
  if (l.startsWith('ta') || l.contains('தம')) return 'ta';
  return 'en';
}

const Map<String, Map<String, String>> _delTxt = {
  'en': {
    'btn': 'Delete account',
    'title': 'Delete your account?',
    'body': 'Your account will be deleted. If you log in again within 30 days, it will be restored automatically. After 30 days it cannot be restored.',
    'hint': 'Password (Google users: type DELETE)',
    'cancel': 'Cancel',
    'confirm': 'Delete',
    'done': 'Account deleted. Log in within 30 days to restore it.',
  },
  'si': {
    'btn': 'ගිණුම මකන්න',
    'title': 'ඔබේ ගිණුම මකන්නද?',
    'body': 'ඔබේ ගිණුම මැකෙනු ඇත. දින 30ක් ඇතුළත නැවත ලොගින් වුවහොත් එය ස්වයංක්‍රීයව ප්‍රතිසාධනය වේ. දින 30කට පසු ප්‍රතිසාධනය කළ නොහැක.',
    'hint': 'මුරපදය (Google පරිශීලකයන්: DELETE ටයිප් කරන්න)',
    'cancel': 'අවලංගු කරන්න',
    'confirm': 'මකන්න',
    'done': 'ගිණුම මකා දමන ලදී. ප්‍රතිසාධනය සඳහා දින 30ක් ඇතුළත ලොගින් වන්න.',
  },
  'ta': {
    'btn': 'கணக்கை நீக்கு',
    'title': 'உங்கள் கணக்கை நீக்கவா?',
    'body': 'உங்கள் கணக்கு நீக்கப்படும். 30 நாட்களுக்குள் மீண்டும் உள்நுழைந்தால் அது தானாகவே மீட்கப்படும். 30 நாட்களுக்குப் பிறகு மீட்க முடியாது.',
    'hint': 'கடவுச்சொல் (Google பயனர்கள்: DELETE என தட்டச்சு செய்க)',
    'cancel': 'ரத்து',
    'confirm': 'நீக்கு',
    'done': 'கணக்கு நீக்கப்பட்டது. மீட்க 30 நாட்களுக்குள் உள்நுழையவும்.',
  },
};
"""
if s.count(old_btn) != 1 or s.count(anchor) != 1:
    sys.exit('settings: anchors not found (button=%d, logout=%d)' % (s.count(old_btn), s.count(anchor)))
s = s.replace(old_btn, new_btn).replace(anchor, method + anchor)
open(p, 'w', encoding='utf-8').write(s.rstrip('\n') + '\n' + tail)
print('settings: patched')
