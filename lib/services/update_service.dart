import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class UpdateService {
  static const String versionCheckUrl =
      'https://api.finbassshamar.online/app-version';

  static const String _fileName = 'mygame_update.apk';
  static const String _stampKey = 'update_apk_for_version';

  static DownloadTask _task(String url) => DownloadTask(
        url: url,
        filename: _fileName,
        baseDirectory: BaseDirectory.applicationSupport,
      );

  static Future<File> _apkFile() async =>
      File(await _task('https://placeholder').filePath());

  static Future<String> _currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  static Future<void> _deleteApk() async {
    try {
      final f = await _apkFile();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// True when a fully downloaded APK for this app version is on disk and
  /// its size matches the APK currently on the server.
  static Future<bool> _isReadyFor(String apkUrl) async {
    try {
      final file = await _apkFile();
      if (!await file.exists()) return false;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_stampKey) != await _currentVersion()) return false;
      final res = await http
          .head(Uri.parse(apkUrl))
          .timeout(const Duration(seconds: 10));
      final remote = int.tryParse(res.headers['content-length'] ?? '');
      return remote != null && remote == await file.length();
    } catch (_) {
      return false;
    }
  }

  /// Call once after the app UI is up. If an update finished downloading
  /// while the app was hidden/closed, offer to install it.
  static Future<void> checkPendingInstall(BuildContext context) async {
    try {
      final file = await _apkFile();
      if (!await file.exists()) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_stampKey) != await _currentVersion()) {
        // App was updated already (or unknown file): clean up.
        await file.delete();
        await prefs.remove(_stampKey);
        return;
      }
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update ready'),
          content: const Text(
              'The update has finished downloading. Install it now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await OpenFilex.open(file.path);
              },
              child: const Text('Install'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Pending install check failed: $e');
    }
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final r = await ApiService.checkForUpdate(info.version);
      final url = (r['downloadUrl'] ?? '').toString();
      if (r['updateAvailable'] == true && url.isNotEmpty && context.mounted) {
        _showUpdateDialog(context, url, false, '');
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
                await downloadAndInstall(context, apkUrl);
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> downloadAndInstall(
      BuildContext context, String apkUrl) async {
    // Already downloaded earlier? Skip the download, go straight to install.
    if (await _isReadyFor(apkUrl)) {
      await OpenFilex.open((await _apkFile()).path);
      return;
    }

    // Remove any old/stale file and remember which app version this
    // download was started from (used to detect "already installed").
    await _deleteApk();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stampKey, await _currentVersion());

    final progress = ValueNotifier<double>(0);
    var dialogOpen = true;

    final task = _task(apkUrl);

    // Progress also shows in the notification bar, so the download keeps
    // going when the app is hidden or closed. Tap it when done to install.
    FileDownloader().configureNotification(
      running: const TaskNotification('Downloading update', '{progress}'),
      complete: const TaskNotification('Update downloaded', 'Tap to install'),
      error: const TaskNotification(
          'Update download failed', 'Open the app and try again'),
      progressBar: true,
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
                  'The update file is large (about 90 MB). Tap Hide to keep using the app. The download continues in the notification bar.',
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
          TextButton(
            onPressed: () {
              dialogOpen = false;
              Navigator.pop(dialogContext);
            },
            child: const Text('Hide'),
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
    if (dialogOpen && context.mounted) Navigator.pop(context);
    progress.dispose();

    if (result != null && result.status == TaskStatus.complete) {
      // Install prompt is triggered by the global taskStatusCallback in
      // main.dart, so it still shows even if this dialog was hidden or
      // this screen is gone by the time the download finishes.
    } else if (result != null && result.status == TaskStatus.canceled) {
      // cancelled by the user, nothing to show
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Check your internet and try again.')),
      );
    }
  }
}
