import sys
p = 'lib/screens/settings_screen.dart'
s = open(p, encoding='utf-8').read()

if '_loggingOut' in s:
    sys.exit('already patched')
if '_confirmDeleteAccount' not in s:
    sys.exit('run patch_delete_account.py first')

def rep(old, new):
    global s
    if s.count(old) != 1:
        sys.exit('anchor not found (%d): %s' % (s.count(old), old[:70]))
    s = s.replace(old, new)

SPIN = "const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2%s))"

# 1. logout wrapper with spinner state
rep("  Future<void> _logout() async {",
"""  bool _loggingOut = false;
  bool _deleting = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      await _logoutCore();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _logoutCore() async {""")

# 2. logout button
rep("child: OutlinedButton.icon(onPressed: _confirmLogout, icon: const Icon(Icons.logout), label: Text(AppLocalizations.t('logout'))),",
"""child: OutlinedButton.icon(
                                onPressed: (_loggingOut || _deleting) ? null : _confirmLogout,
                                icon: _loggingOut ? %s : const Icon(Icons.logout),
                                label: Text(AppLocalizations.t('logout')),
                              ),""" % (SPIN % ""))

# 3. delete button
rep("onPressed: _confirmDeleteAccount,", "onPressed: (_loggingOut || _deleting) ? null : _confirmDeleteAccount,")
rep("icon: const Icon(Icons.delete_forever, color: Colors.redAccent),",
    "icon: _deleting ? %s : const Icon(Icons.delete_forever, color: Colors.redAccent)," % (SPIN % ", color: Colors.redAccent"))
rep("label: Text(_delTxt[_delLang()]!['btn']!, style: const TextStyle(color: Colors.redAccent)),",
    "label: Text(_deleting ? _delTxt[_delLang()]!['deleting']! : _delTxt[_delLang()]!['btn']!, style: const TextStyle(color: Colors.redAccent)),")

# 4. delete flow with loading state
rep("""    try {
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
  }""",
"""    setState(() => _deleting = true);
    try {
      await ApiService.deleteAccount(secret);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['done']!)));
      await _logoutCore();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }""")

# 5. "Deleting..." text in 3 languages
rep("'btn': 'Delete account',", "'btn': 'Delete account',\n    'deleting': 'Deleting...',")
rep("'btn': 'ගිණුම මකන්න',", "'btn': 'ගිණුම මකන්න',\n    'deleting': 'මකමින්...',")
rep("'btn': 'கணக்கை நீக்கு',", "'btn': 'கணக்கை நீக்கு',\n    'deleting': 'நீக்குகிறது...',")

open(p, 'w', encoding='utf-8').write(s)
print('patched')
