import 'package:flutter/material.dart';
import '../services/app_version_service.dart';
import '../services/update_service.dart';

class ForceUpdateScreen extends StatefulWidget {
  final AppVersionInfo info;

  const ForceUpdateScreen({super.key, required this.info});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  String get _url => widget.info.apkUrl.isNotEmpty
      ? widget.info.apkUrl
      : 'https://buysellgame.store/downloads/app-release.apk';

  @override
  void initState() {
    super.initState();
    // Reopened while downloading, or download already finished?
    UpdateService.refreshPhase(_url);
  }

  Widget _action(UpdatePhase phase) {
    switch (phase) {
      case UpdatePhase.downloading:
        return Column(
          children: [
            ValueListenableBuilder<double>(
              valueListenable: UpdateService.progress,
              builder: (_, p, __) {
                final known = p > 0 && p <= 1;
                return Column(
                  children: [
                    LinearProgressIndicator(value: known ? p : null, minHeight: 8),
                    const SizedBox(height: 12),
                    Text(
                      known
                          ? 'Downloading... ${(p * 100).toStringAsFixed(0)}%'
                          : 'Downloading...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'You can close the app. The download continues in the notification bar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8E8E99), fontSize: 12),
            ),
            TextButton(
              onPressed: UpdateService.cancelDownload,
              child: const Text('Cancel'),
            ),
          ],
        );
      case UpdatePhase.ready:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: UpdateService.installNow,
            icon: const Icon(Icons.system_update_rounded),
            label: const Text('Install Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      case UpdatePhase.failed:
      case UpdatePhase.idle:
        return Column(
          children: [
            if (phase == UpdatePhase.failed)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('Download failed. Check your internet and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => UpdateService.startBackgroundDownload(_url),
                icon: const Icon(Icons.download_rounded),
                label: Text(phase == UpdatePhase.failed ? 'Retry' : 'Update Now',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B10),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.system_update_rounded,
                      size: 80, color: Color(0xFF6C4CF1)),
                  const SizedBox(height: 28),
                  const Text(
                    'Update Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'A new version of MYGame is available. '
                    'Please update the app to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF8E8E99), fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Text('New version: ${widget.info.latestVersion}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 30),
                  ValueListenableBuilder<UpdatePhase>(
                    valueListenable: UpdateService.phase,
                    builder: (_, phase, __) => _action(phase),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
