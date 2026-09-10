import 'package:flutter/material.dart';
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
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ApiService.changePassword(_currentPassCtrl.text, _newPassCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      Navigator.pop(context);
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
          appBar: AppBar(title: Text(AppLocalizations.t('change_password'))),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _currentPassCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('current_password')),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('new_password')),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('confirm_new_password')),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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
                          : Text(AppLocalizations.t('update_password'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
