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
    final progress = ValueNotifier<double>(0);

    final task = DownloadTask(
      url: apkUrl,
      filename: 'mygame_update.apk',
      baseDirectory: BaseDirectory.applicationSupport,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Downloading update'),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, p, __) {
            final known = p > 0 && p <= 1;
            final percent = (p * 100).clamp(0, 100).toStringAsFixed(0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: known ? p : null, minHeight: 8),
                const SizedBox(height: 12),
                Text(known ? '$percent%' : 'Connecting...'),
                const SizedBox(height: 4),
                const Text(
                  'The update file is large (about 90 MB). Please keep the app open.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => FileDownloader().cancelTaskWithId(task.taskId),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    TaskStatusUpdate? result;
    try {
      result = await FileDownloader().download(
        task,
        onProgress: (p) {
          if (p >= 0 && p <= 1) progress.value = p;
        },
      );
    } catch (e) {
      debugPrint('Update download error: $e');
    }
    if (context.mounted) Navigator.pop(context);
    progress.dispose();

    if (result != null && result.status == TaskStatus.complete) {
      final filePath = await task.filePath();
      await OpenFilex.open(filePath);
    } else if (result != null && result.status == TaskStatus.canceled) {
      // cancelled by the user, nothing to show
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Check your internet and try again.')),
      );
    }
  }
}
