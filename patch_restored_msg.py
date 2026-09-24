import sys
p = 'lib/services/api_service.dart'
s = open(p, encoding='utf-8').read()
if 'accountRestored' in s:
    sys.exit('already patched')
old = "    if (res.statusCode >= 200 && res.statusCode < 300) {\n      return body;\n"
if s.count(old) != 1:
    sys.exit('anchor not found (%d)' % s.count(old))
new = """    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is Map && body['accountRestored'] == true) _showRestoredMessage();
      return body;
"""
s = s.replace(old, new)

helper = """  static void _showRestoredMessage() {
    final l = AppLocalizations.currentLanguage.value.toLowerCase();
    final msg = (l.startsWith('si') || l.contains('සිං'))
        ? 'ආයුබෝවන්! ඔබේ ගිණුම නැවත ප්‍රතිසාධනය කරන ලදී.'
        : (l.startsWith('ta') || l.contains('தம'))
            ? 'மீண்டும் வருக! உங்கள் கணக்கு மீட்டெடுக்கப்பட்டது.'
            : 'Welcome back! Your account has been restored.';
    Future.delayed(const Duration(milliseconds: 700), () {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
        );
      }
    });
  }

"""
anchor = "  static Future<Map<String, dynamic>> _handle(http.Response res) async {"
if s.count(anchor) != 1:
    sys.exit('_handle anchor not found')
s = s.replace(anchor, helper + anchor)
if "app_localizations.dart" not in s:
    s = s.replace("import 'package:http/http.dart' as http;", "import 'package:http/http.dart' as http;\nimport 'app_localizations.dart';", 1)
    if "app_localizations.dart" not in s:
        s = "import 'app_localizations.dart';\n" + s
open(p, 'w', encoding='utf-8').write(s)
print('patched')
