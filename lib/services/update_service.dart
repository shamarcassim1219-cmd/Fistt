import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  static const String versionCheckUrl =
      'https://api.finbassshamar.online/app-version';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http
          .get(Uri.parse(versionCheckUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersionCode = data['latestVersionCode'] as int;
      final apkUrl = data['apkUrl'] as String;
      final forceUpdate = data['force_update'] as bool? ?? false;
      final notes = data['update_notes'] as String? ?? '';

      final info = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(info.buildNumber);

      if (currentVersionCode < latestVersionCode && context.mounted) {
        _showUpdateDialog(context, apkUrl, forceUpdate, notes);
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static void _showUpdateDialog(
      BuildContext context, String apkUrl, bool forceUpdate, String notes) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          title: const Text('අලුත් Update එකක් තියෙනවා'),
          content: Text(notes.isEmpty
              ? 'App එකේ අලුත් version එකක් available. Update කරන්න.'
              : notes),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('පස්සේ'),
              ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _downloadAndInstall(context, apkUrl);
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _downloadAndInstall(
      BuildContext context, String apkUrl) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Downloading...'),
        ]),
      ),
    );

    final task = DownloadTask(
      url: apkUrl,
      filename: 'mygame_update.apk',
      baseDirectory: BaseDirectory.applicationSupport,
    );

    final result = await FileDownloader().download(task);
    if (context.mounted) Navigator.pop(context);

    if (result.status == TaskStatus.complete) {
      final filePath = await task.filePath();
      await OpenFilex.open(filePath);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download fail උනා, ආයෙත් try කරන්න')),
      );
    }
  }
}
