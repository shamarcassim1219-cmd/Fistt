import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _submitting = false;
  bool _sending = false;
  bool _codeMode = false; // false: current password form, true: email code form
  String? _error;
  String? _email;

  Map<String, String> get _t => _txt[_lc()]!;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<String?> _findEmail() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys()) {
      final v = prefs.get(k);
      if (v is String && k.toLowerCase().contains('email') && v.contains('@')) return v;
    }
    return null;
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final email = _email ?? await _findEmail();
      if (email == null) throw Exception(_t['noEmail']);
      await ApiService.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _email = email;
        _codeMode = true;
        _formKey.currentState?.reset();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t['sent']} $email')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = _t['mismatch']);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (_codeMode) {
        await ApiService.resetPassword(_email!, _codeCtrl.text.trim(), _newPassCtrl.text);
      } else {
        await ApiService.changePassword(_currentPassCtrl.text, _newPassCtrl.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t['success']!)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        final t = _t;
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('change_password'))),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_codeMode) ...[
                    Text(
                      '${t['info']}\n$_email',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(labelText: t['code']),
                      validator: (v) => (v == null || v.trim().isEmpty) ? t['required'] : null,
                    ),
                  ] else
                    TextFormField(
                      controller: _currentPassCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(labelText: AppLocalizations.t('current_password')),
                      validator: (v) => (v == null || v.isEmpty) ? t['required'] : null,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('new_password')),
                    validator: (v) => (v == null || v.length < 6) ? t['min6'] : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('confirm_new_password')),
                    validator: (v) => (v == null || v.isEmpty) ? t['required'] : null,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(
                              _codeMode ? t['change']! : AppLocalizations.t('update_password'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_codeMode)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: _sending ? null : _sendCode,
                        child: _sending
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  const SizedBox(width: 8),
                                  Text(t['sending']!),
                                ],
                              )
                            : Text(t['forgot']!),
                      ),
                    )
                  else
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _sending ? null : _sendCode,
                          child: Text(_sending ? t['sending']! : t['resend']!),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _codeMode = false;
                            _error = null;
                            _codeCtrl.clear();
                          }),
                          child: Text(t['useCurrent']!),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _lc() {
  final l = AppLocalizations.currentLanguage.value.toLowerCase();
  if (l.startsWith('si') || l.contains('සිං')) return 'si';
  if (l.startsWith('ta') || l.contains('தம')) return 'ta';
  return 'en';
}

const Map<String, Map<String, String>> _txt = {
  'en': {
    'forgot': 'Forgot password?',
    'useCurrent': 'Use current password',
    'code': 'Verification code',
    'sending': 'Sending...',
    'sent': 'Code sent to',
    'info': 'Enter the code we sent to your email and choose a new password.',
    'resend': 'Resend code',
    'change': 'Change password',
    'mismatch': 'New passwords do not match',
    'success': 'Password updated successfully',
    'noEmail': 'Could not find your email. Please log in again.',
    'required': 'Required',
    'min6': 'Min 6 characters',
  },
  'si': {
    'forgot': 'මුරපදය අමතකද?',
    'useCurrent': 'වර්තමාන මුරපදය භාවිතා කරන්න',
    'code': 'තහවුරු කිරීමේ කේතය',
    'sending': 'යවමින්...',
    'sent': 'කේතය යවන ලදී:',
    'info': 'ඔබේ ඊමේල් එකට එවූ කේතය ඇතුළත් කර නව මුරපදයක් තෝරන්න.',
    'resend': 'කේතය නැවත යවන්න',
    'change': 'මුරපදය වෙනස් කරන්න',
    'mismatch': 'නව මුරපද ගැළපෙන්නේ නැත',
    'success': 'මුරපදය සාර්ථකව යාවත්කාලීන විය',
    'noEmail': 'ඔබේ ඊමේල් සොයාගත නොහැක. නැවත ලොගින් වන්න.',
    'required': 'අවශ්‍යයි',
    'min6': 'අවම අක්ෂර 6ක්',
  },
  'ta': {
    'forgot': 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?',
    'useCurrent': 'தற்போதைய கடவுச்சொல்லைப் பயன்படுத்து',
    'code': 'சரிபார்ப்புக் குறியீடு',
    'sending': 'அனுப்புகிறது...',
    'sent': 'குறியீடு அனுப்பப்பட்டது:',
    'info': 'உங்கள் மின்னஞ்சலுக்கு அனுப்பிய குறியீட்டை உள்ளிட்டு புதிய கடவுச்சொல்லைத் தேர்ந்தெடுக்கவும்.',
    'resend': 'குறியீட்டை மீண்டும் அனுப்பு',
    'change': 'கடவுச்சொல்லை மாற்று',
    'mismatch': 'புதிய கடவுச்சொற்கள் பொருந்தவில்லை',
    'success': 'கடவுச்சொல் வெற்றிகரமாக புதுப்பிக்கப்பட்டது',
    'noEmail': 'உங்கள் மின்னஞ்சலைக் கண்டுபிடிக்க முடியவில்லை. மீண்டும் உள்நுழையவும்.',
    'required': 'தேவை',
    'min6': 'குறைந்தது 6 எழுத்துகள்',
  },
};
