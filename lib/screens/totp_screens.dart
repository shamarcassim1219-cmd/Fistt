import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Small dialog that asks for a 6-digit authenticator code. Returns the code or null.
Future<String?> askTotpCode(BuildContext context, {String title = 'Enter authenticator code'}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Open your authenticator app and enter the 6-digit code for MYGame.',
              style: TextStyle(color: AppColors.hint, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 6),
            decoration: const InputDecoration(counterText: ''),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final c = ctrl.text.trim();
            if (c.length == 6) Navigator.pop(ctx, c);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

/// Remembers on the phone whether two-step verification is on.
Future<void> _saveTotpFlag(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('totp_enabled', enabled);
}

/// Called on app start (logged-in users). True when the authenticator code must be entered
/// before the app opens. Asks the server; falls back to the saved flag when offline.
Future<bool> needsTotpUnlock() async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getBool('totp_enabled') ?? false;
  try {
    final enabled = await ApiService.totpStatus().timeout(const Duration(seconds: 4));
    await prefs.setBool('totp_enabled', enabled);
    return enabled;
  } catch (_) {
    return cached;
  }
}

// ---------------------------------------------------------------------------
// App unlock (shown when the app is opened and two-step verification is on)
// ---------------------------------------------------------------------------
class TotpUnlockScreen extends StatefulWidget {
  const TotpUnlockScreen({super.key});

  @override
  State<TotpUnlockScreen> createState() => _TotpUnlockScreenState();
}

class _TotpUnlockScreenState extends State<TotpUnlockScreen> {
  final _codeCtrl = TextEditingController();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final enabled = await ApiService.totpVerifyUnlock(code);
      await _saveTotpFlag(enabled);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _verifying = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.setBool('totp_enabled', false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 60, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Welcome back',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Open your authenticator app and enter the 6-digit code for MYGame.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.hint, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    onSubmitted: (_) => _verifying ? null : _unlock(),
                    style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
                    decoration: const InputDecoration(labelText: 'Authenticator code'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _unlock,
                      child: _verifying
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Unlock'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _verifying ? null : _logout,
                    child: const Text('Log out', style: TextStyle(color: AppColors.hint)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login step 2 (password login when two-step verification is on)
// ---------------------------------------------------------------------------
class TotpLoginScreen extends StatefulWidget {
  final String ticket;
  final bool isGate;
  const TotpLoginScreen({super.key, required this.ticket, this.isGate = false});

  @override
  State<TotpLoginScreen> createState() => _TotpLoginScreenState();
}

class _TotpLoginScreenState extends State<TotpLoginScreen> {
  final _codeCtrl = TextEditingController();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final userData = await ApiService.verifyTotpLogin(widget.ticket, code);

      try {
        await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) await ApiService.saveFcmToken(fcmToken);
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      final displayName = userData['displayName'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        await prefs.setString('pending_welcome_name', displayName);
        await prefs.setBool('pending_welcome_is_new', false);
        await prefs.setBool('pending_welcome_restored', userData['restored'] == true);
      }

      if (!mounted) return;
      if (widget.isGate) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _verifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Two-step verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.phonelink_lock, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Open your authenticator app and enter the 6-digit code for MYGame.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.hint, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                onSubmitted: (_) => _verifying ? null : _verify(),
                style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
                decoration: const InputDecoration(labelText: 'Authenticator code'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  child: _verifying
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings: turn two-step verification on / off
// ---------------------------------------------------------------------------
class TwoFactorSettingsScreen extends StatefulWidget {
  const TwoFactorSettingsScreen({super.key});

  @override
  State<TwoFactorSettingsScreen> createState() => _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState extends State<TwoFactorSettingsScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  bool _enabled = false;
  bool _setup = false; // showing QR
  String? _secret;
  Uint8List? _qrBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enabled = await ApiService.totpStatus();
      await _saveTotpFlag(enabled);
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _startSetup() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await ApiService.totpGenerate();
      final qr = (data['qrCode'] ?? '').toString();
      Uint8List? bytes;
      if (qr.contains(',')) {
        try {
          bytes = base64Decode(qr.split(',').last);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _secret = data['secret']?.toString();
        _qrBytes = bytes;
        _setup = true;
        _codeCtrl.clear();
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _busy = false;
      });
    }
  }

  Future<void> _confirm() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from the app');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.totpConfirm(_secret ?? '', code);
      await _saveTotpFlag(true);
      if (!mounted) return;
      setState(() {
        _enabled = true;
        _setup = false;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Two-step verification is now on')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _busy = false;
      });
    }
  }

  Future<void> _disable() async {
    final code = await askTotpCode(context, title: 'Turn off two-step verification');
    if (code == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.totpDisable(code);
      await _saveTotpFlag(false);
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Two-step verification is now off')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _busy = false;
      });
    }
  }

  Widget _errorText() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        );

  Widget _spinner() => const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Two-step verification')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _setup ? _setupView() : _statusView(),
              ),
      ),
    );
  }

  Widget _statusView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Icon(_enabled ? Icons.verified_user : Icons.shield_outlined,
            size: 64, color: _enabled ? Colors.greenAccent : AppColors.primary),
        const SizedBox(height: 16),
        Text(_enabled ? 'Two-step verification is ON' : 'Two-step verification is OFF',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          _enabled
              ? 'When you log in, we ask for the 6-digit code from your authenticator app.'
              : 'Protect your account with Google Authenticator (or any authenticator app). At login you will enter a 6-digit code from the app.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.hint, fontSize: 13),
        ),
        const SizedBox(height: 24),
        _errorText(),
        SizedBox(
          height: 52,
          child: _enabled
              ? OutlinedButton(onPressed: _busy ? null : _disable, child: _busy ? _spinner() : const Text('Turn off'))
              : ElevatedButton(onPressed: _busy ? null : _startSetup, child: _busy ? _spinner() : const Text('Turn on')),
        ),
        if (!_enabled) ...[
          const SizedBox(height: 16),
          const Text(
            'Important: if you lose the phone that has the authenticator app, you will not be able to log in. Keep the setup key somewhere safe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _setupView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '1. Open Google Authenticator (or any authenticator app)\n2. Tap + and scan this QR code\n3. Enter the 6-digit code it shows',
          style: TextStyle(color: AppColors.hint, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),
        if (_qrBytes != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Image.memory(_qrBytes!, width: 220, height: 220),
            ),
          ),
        const SizedBox(height: 14),
        const Text("Can't scan? Enter this key in the app:",
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint, fontSize: 12)),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _secret ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key copied')));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SelectableText(_secret ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 6),
          decoration: const InputDecoration(labelText: '6-digit code'),
        ),
        const SizedBox(height: 6),
        _errorText(),
        SizedBox(
          height: 52,
          child: ElevatedButton(onPressed: _busy ? null : _confirm, child: _busy ? _spinner() : const Text('Verify & turn on')),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() {
            _setup = false;
            _error = null;
          }),
          child: const Text('Cancel', style: TextStyle(color: AppColors.hint)),
        ),
      ],
    );
  }
}
