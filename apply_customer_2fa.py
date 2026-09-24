#!/usr/bin/env python3
"""Customer app (Fistt): adds two-step verification (Google Authenticator).
Run from the project root (~/Fistt):  python3 apply_customer_2fa.py
Safe to run twice; a change whose code was not found is skipped and reported."""
import os, sys

applied, skipped = [], []


def read(p):
    with open(p, encoding='utf-8') as f:
        return f.read()


def write(p, t):
    with open(p, 'w', encoding='utf-8') as f:
        f.write(t)


def add_import(s, line):
    if line in s:
        return s
    key = "import 'package:flutter/material.dart';\n"
    return s.replace(key, key + line, 1) if key in s else line + s


def patch(path, name, fn):
    if not os.path.exists(path):
        skipped.append(f'{name}: file not found ({path})')
        return
    s = read(path)
    new = fn(s)
    if new is None:
        skipped.append(f'{name}: code not found (file changed?)')
    elif new == s:
        skipped.append(f'{name}: already applied')
    else:
        write(path, new)
        applied.append(name)


API = 'lib/services/api_service.dart'
LOGIN = 'lib/screens/login_screen.dart'
SETTINGS = 'lib/screens/settings_screen.dart'


# ---------- api_service.dart ----------
def api_login(s):
    if 'static Future<Map<String, dynamic>> login(String email, String password)' in s:
        return s
    old = """  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    await _handle(res);
  }"""
    new = """  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    // {requiresTotp: true, ticket} when two-step verification is on, otherwise {message, email}
    return await _handle(res);
  }"""
    return s.replace(old, new, 1) if old in s else None


def api_google(s):
    if 'String? totpCode' in s:
        return s
    old1 = 'static Future<Map<String, dynamic>> googleSignIn(String idToken) async {'
    old2 = """        'idToken': idToken,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),"""
    old3 = """    final data = await _handle(res);
    await saveToken(data['token']);
    return data;
  }

  // ---------- UPLOAD ----------"""
    if old1 not in s or old2 not in s or old3 not in s:
        return None
    s = s.replace(old1, 'static Future<Map<String, dynamic>> googleSignIn(String idToken, {String? totpCode}) async {', 1)
    s = s.replace(old2, """        'idToken': idToken,
        if (totpCode != null) 'totpCode': totpCode,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),""", 1)
    s = s.replace(old3, """    final data = await _handle(res);
    if (data['requiresTotp'] == true) return data; // needs the authenticator code first
    await saveToken(data['token']);
    return data;
  }

  // ---------- UPLOAD ----------""", 1)
    return s


def api_methods(s):
    if 'verifyTotpLogin' in s:
        return s
    body = s.rstrip()
    if not body.endswith('}'):
        return None
    methods = '''
  // ---------- TWO-STEP VERIFICATION (Google Authenticator) ----------
  static Future<Map<String, dynamic>> verifyTotpLogin(String ticket, String code) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-totp-login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'ticket': ticket, 'code': code,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  static Future<bool> totpStatus() async {
    final res = await http.get(Uri.parse('$baseUrl/auth/totp/status'), headers: await _headers());
    final data = await _handle(res);
    return data['enabled'] == true;
  }

  static Future<Map<String, dynamic>> totpGenerate() async {
    final res = await http.post(Uri.parse('$baseUrl/auth/totp/generate'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> totpConfirm(String secret, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/totp/confirm'),
      headers: await _headers(),
      body: jsonEncode({'secret': secret, 'code': code}),
    );
    await _handle(res);
  }

  static Future<void> totpDisable(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/totp/disable'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    await _handle(res);
  }
'''
    return body[:-1].rstrip() + '\n' + methods + '}\n'


patch(API, 'API: login returns 2FA info', api_login)
patch(API, 'API: Google sign-in with code', api_google)
patch(API, 'API: 2FA methods', api_methods)


# ---------- login_screen.dart ----------
def login_submit(s):
    if 'TotpLoginScreen(' in s:
        return s
    old = """      } else {
        await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      }

      if (!mounted) return;
      Navigator.of(context).push("""
    new = """      } else {
        final loginData = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
        if (loginData['requiresTotp'] == true) {
          if (!mounted) return;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TotpLoginScreen(ticket: loginData['ticket'].toString(), isGate: widget.isGate),
          ));
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).push("""
    if old not in s:
        return None
    return add_import(s.replace(old, new, 1), "import 'totp_screens.dart';\n")


def login_google(s):
    if 'askTotpCode(context)' in s:
        return s
    old = '      final signInData = await ApiService.googleSignIn(idToken);\n'
    if s.count(old) < 1:
        return None
    new = """      var signInData = await ApiService.googleSignIn(idToken);
      if (signInData['requiresTotp'] == true) {
        if (!mounted) return;
        final totpCode = await askTotpCode(context);
        if (totpCode == null) return;
        signInData = await ApiService.googleSignIn(idToken, totpCode: totpCode);
      }
"""
    return add_import(s.replace(old, new), "import 'totp_screens.dart';\n")


patch(LOGIN, 'Login: authenticator code step', login_submit)
patch(LOGIN, 'Login: Google sign-in code step', login_google)


# ---------- settings_screen.dart ----------
def settings_tile(s):
    if 'TwoFactorSettingsScreen' in s:
        return s
    anchor = "              _tile(Icons.block_outlined, AppLocalizations.t('blocked_users'), null, () async {"
    if s.count(anchor) != 1:
        return None
    tile = """              _tile(Icons.security, 'Two-step verification', 'Google Authenticator', () async {
                if (!await requireLogin(context, reason: 'Login to manage two-step verification')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFactorSettingsScreen()));
              }),
"""
    return add_import(s.replace(anchor, tile + anchor, 1), "import 'totp_screens.dart';\n")


patch(SETTINGS, 'Settings: Two-step verification entry', settings_tile)

print('\nApplied:')
for a in applied:
    print('  +', a)
print('Skipped:')
for k in skipped:
    print('  -', k)
if not os.path.exists('lib/screens/totp_screens.dart'):
    print('\nWARNING: lib/screens/totp_screens.dart is missing - copy it into lib/screens/ first!')
    sys.exit(1)
