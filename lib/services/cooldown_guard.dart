import 'package:flutter/material.dart';
import '../main.dart';
import 'api_service.dart';
import 'app_localizations.dart';

String _formatWait(int hours) {
  final d = hours ~/ 24;
  final h = hours % 24;
  if (d > 0 && h > 0) {
    return AppLocalizations.t('cooldown_time_days_hours').replaceAll('{d}', '$d').replaceAll('{h}', '$h');
  }
  if (d > 0) {
    return AppLocalizations.t('cooldown_time_days').replaceAll('{d}', '$d');
  }
  return AppLocalizations.t('cooldown_time_hours').replaceAll('{h}', '$hours');
}

/// Checks the server-side 2-day cooldown BEFORE a sensitive screen opens.
/// Returns true when the user may continue. When still locked it shows a
/// dialog with the remaining time and returns false.
/// If the check itself fails (offline, endpoint not deployed yet) it returns
/// true, because the server still enforces the cooldown on submit.
Future<bool> passCooldown(BuildContext context, {required bool bank}) async {
  Map<String, dynamic> data;
  try {
    data = bank ? await ApiService.getBankDetailsCooldown() : await ApiService.getPasswordCooldown();
  } catch (_) {
    return true;
  }
  if (data['allowed'] != false) return true;

  final raw = data['hoursLeft'];
  var hours = raw is num ? raw.ceil() : (int.tryParse('$raw') ?? 1);
  if (hours < 1) hours = 1;

  if (!context.mounted) return false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(AppLocalizations.t('cooldown_title'), style: const TextStyle(color: Colors.white)),
      content: Text(
        '${AppLocalizations.t(bank ? 'cooldown_bank_message' : 'cooldown_password_message')}\n\n${AppLocalizations.t('cooldown_remaining')}: ${_formatWait(hours)}',
        style: const TextStyle(color: AppColors.hint, fontSize: 13, height: 1.5),
      ),
      actions: [
        ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('close'))),
      ],
    ),
  );
  return false;
}
