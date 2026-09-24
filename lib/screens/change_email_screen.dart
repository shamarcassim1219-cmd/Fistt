import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _currentPassCtrl = TextEditingController();
  final _newEmailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _codeSent = false;
  bool _submitting = false;
  String? _error;

  Future<void> _requestChange() async {
    if (_currentPassCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your current password');
      return;
    }
    if (!_newEmailCtrl.text.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ApiService.requestEmailChange(_currentPassCtrl.text, _newEmailCtrl.text.trim());
      setState(() => _codeSent = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmChange() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final newEmail = await ApiService.confirmEmailChange(_codeCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email updated to $newEmail')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('change_email'))),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_codeSent) ...[
                  Text(AppLocalizations.t('change_email_notice'), style: const TextStyle(color: AppColors.hint, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _currentPassCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('current_password')),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('new_email')),
                  ),
                ] else ...[
                  Text(AppLocalizations.t('confirm_email_code_notice'), style: const TextStyle(color: AppColors.hint, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: Colors.white, letterSpacing: 4),
                    decoration: InputDecoration(labelText: AppLocalizations.t('verification_code'), counterText: ''),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : (_codeSent ? _confirmChange : _requestChange),
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(_codeSent ? AppLocalizations.t('confirm') : AppLocalizations.t('send_verification_code'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
