import 'package:flutter/material.dart';
import '../main.dart';
import '../services/app_localizations.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'totp_screens.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  Widget _tile(BuildContext context, IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.hint),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AppColors.hint)) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        children: [
          _tile(context, Icons.email_outlined, AppLocalizations.t('change_email'), null, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailScreen()));
          }),
          _tile(context, Icons.lock_reset, AppLocalizations.t('change_password'), null, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
          }),
          _tile(context, Icons.security, 'Two-step verification', 'Google Authenticator', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFactorSettingsScreen()));
          }),
        ],
      ),
    );
  }
}
