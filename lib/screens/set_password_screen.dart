import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _codeSent = false;
  bool _submitting = false;
  String? _error;

  Future<void> _requestCode() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ApiService.requestSetPassword();
      setState(() => _codeSent = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmSetPassword() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (_newPassCtrl.text.trim().length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ApiService.confirmSetPassword(_codeCtrl.text.trim(), _newPassCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password set! You can now log in with email and password too.')),
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Set Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_codeSent) ...[
              const Text(
                'Your account currently uses Google Sign-In only. Set a password so you can also log in with your email and password.',
                style: TextStyle(color: AppColors.hint, fontSize: 13),
              ),
            ] else ...[
              const Text(
                'Enter the 6-digit code sent to your email, and choose your new password.',
                style: TextStyle(color: AppColors.hint, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: const InputDecoration(labelText: 'Verification Code', counterText: ''),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPassCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'New Password'),
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
                onPressed: _submitting ? null : (_codeSent ? _confirmSetPassword : _requestCode),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(_codeSent ? 'Confirm' : 'Send Verification Code', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
