import '../services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_version_service.dart';

class ForceUpdateScreen extends StatelessWidget {
  final AppVersionInfo info;

  const ForceUpdateScreen({
    super.key,
    required this.info,
  });

  Future<void> _update(BuildContext context) async {
    final url = info.apkUrl.isNotEmpty
        ? info.apkUrl
        : 'https://buysellgame.store/downloads/app-release.apk';
    await UpdateService.downloadAndInstall(context, url);
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
                  const Icon(
                    Icons.system_update_rounded,
                    size: 80,
                    color: Color(0xFF6C4CF1),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Update Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'A new version of MYGame is available. '
                    'Please update the app to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8E8E99),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'New version: ${info.latestVersion}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _update(context),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
