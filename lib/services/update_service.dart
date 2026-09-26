import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

enum UpdatePhase { idle, downloading, ready, failed }

class UpdateService {
  static const String versionCheckUrl =
      'https://api.finbassshamar.online/app-version';

  static const String _fileName = 'mygame_update.apk';
  static const String _stampKey = 'update_apk_for_version';
  static const String _doneKey = 'update_apk_complete';

  /// Live state, used by the force-update screen.
  static final ValueNotifier<UpdatePhase> phase =
      ValueNotifier(UpdatePhase.idle);
  static final ValueNotifier<double> progress = ValueNotifier(0);

  // ParallelDownloadTask splits the file into chunks and downloads them
  // over several connections at once, instead of one connection start-to-
  // finish. This is what was making updates slow -- a single connection was
  // capped by the server's per-connection speed limit.
  static ParallelDownloadTask _task(String url) => ParallelDownloadTask(
        url: url,
        filename: _fileName,
        baseDirectory: BaseDirectory.applicationSupport,
        updates: Updates.statusAndProgress,
        retries: 3,
        chunks: 6,
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

  static void _configureNotification() {
    FileDownloader().configureNotification(
      running: const TaskNotification('Downloading update', '{progress}'),
      complete: const TaskNotification('Update downloaded', 'Tap to install'),
      error: const TaskNotification(
          'Update download failed', 'Open the app and try again'),
      progressBar: true,
    );
  }

  // ---- called from the global callbacks in main.dart ----
  static Future<void> onStatus(TaskStatus s) async {
    if (s == TaskStatus.complete) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_doneKey, true);
      progress.value = 1;
      phase.value = UpdatePhase.ready;
    } else if (s == TaskStatus.failed || s == TaskStatus.notFound) {
      if (phase.value == UpdatePhase.downloading) phase.value = UpdatePhase.failed;
    } else if (s == TaskStatus.canceled) {
      if (phase.value == UpdatePhase.downloading) phase.value = UpdatePhase.idle;
    }
  }

  static void onProgress(double p) {
    if (p >= 0 && p <= 1) progress.value = p;
  }

  /// True when a fully finished APK for this app version is on disk.
  static Future<bool> isReady([String? apkUrl]) async {
    try {
      final file = await _apkFile();
      if (!await file.exists()) return false;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_stampKey) != await _currentVersion()) return false;
      if (prefs.getBool(_doneKey) != true) return false;
      if (apkUrl != null && apkUrl.isNotEmpty) {
        try {
          final res = await http
              .head(Uri.parse(apkUrl))
              .timeout(const Duration(seconds: 10));
          final remote = int.tryParse(res.headers['content-length'] ?? '');
          if (remote != null && remote != await file.length()) return false;
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isDownloading() async {
    try {
      final tasks = await FileDownloader().allTasks();
      return tasks.any((t) => t.filename == _fileName);
    } catch (_) {
      return false;
    }
  }

  /// Force-update screen calls this on open: finished? still downloading?
  static Future<void> refreshPhase(String apkUrl) async {
    if (await isReady(apkUrl)) {
      progress.value = 1;
      phase.value = UpdatePhase.ready;
    } else if (await isDownloading()) {
      phase.value = UpdatePhase.downloading;
    } else if (phase.value != UpdatePhase.failed) {
      phase.value = UpdatePhase.idle;
    }
  }

  /// Starts a background download (no dialog). Keeps going when the app is
  /// hidden or closed; progress shows in the notification bar.
  static Future<void> startBackgroundDownload(String apkUrl) async {
    await _deleteApk();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stampKey, await _currentVersion());
    await prefs.setBool(_doneKey, false);
    progress.value = 0;
    phase.value = UpdatePhase.downloading;
    _configureNotification();
    final ok = await FileDownloader().enqueue(_task(apkUrl));
    if (!ok) phase.value = UpdatePhase.failed;
  }

  static Future<void> cancelDownload() async {
    try {
      final tasks = await FileDownloader().allTasks();
      for (final t in tasks.where((t) => t.filename == _fileName)) {
        await FileDownloader().cancelTaskWithId(t.taskId);
      }
    } catch (_) {}
    phase.value = UpdatePhase.idle;
  }

  static Future<void> installNow() async {
    await OpenFilex.open((await _apkFile()).path);
  }

  /// Optional-update flow: if an update finished downloading while the app
  /// was closed, offer to install it (not used while force-update is showing).
  static Future<void> checkPendingInstall(BuildContext context) async {
    try {
      final file = await _apkFile();
      if (!await file.exists()) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_stampKey) != await _currentVersion()) {
        await file.delete();
        await prefs.remove(_stampKey);
        await prefs.remove(_doneKey);
        return;
      }
      if (!await isReady()) return;
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
                await installNow();
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

  /// Optional-update flow (Settings > Check for updates): dialog with progress.
  static Future<void> downloadAndInstall(
      BuildContext context, String apkUrl) async {
    if (await isReady(apkUrl)) {
      await installNow();
      return;
    }

    await _deleteApk();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stampKey, await _currentVersion());
    await prefs.setBool(_doneKey, false);

    final progressN = ValueNotifier<double>(0);
    var dialogOpen = true;
    final task = _task(apkUrl);
    _configureNotification();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Downloading update'),
        content: ValueListenableBuilder<double>(
          valueListenable: progressN,
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
          if (p >= 0 && p <= 1) progressN.value = p;
        },
      );
    } catch (e) {
      debugPrint('Update download error: $e');
    }
    if (dialogOpen && context.mounted) Navigator.pop(context);
    progressN.dispose();

    if (result != null && result.status == TaskStatus.complete) {
      await onStatus(TaskStatus.complete);
      // Install prompt is opened by the global callback in main.dart.
    } else if (result != null && result.status == TaskStatus.canceled) {
      // cancelled by the user
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Check your internet and try again.')),
      );
    }
  }
}
