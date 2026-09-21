import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  final int latestVersionCode;
  final int minimumVersionCode;
  final String latestVersion;
  final String minimumVersion;
  final String apkUrl;

  AppVersionInfo({
    required this.latestVersionCode,
    required this.minimumVersionCode,
    required this.latestVersion,
    required this.minimumVersion,
    required this.apkUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersionCode: json['latestVersionCode'] ?? 0,
      minimumVersionCode: json['minimumVersionCode'] ?? 0,
      latestVersion: json['latestVersion'] ?? '',
      minimumVersion: json['minimumVersion'] ?? '',
      apkUrl: json['apkUrl'] ?? '',
    );
  }
}

class AppVersionService {
  static const String versionUrl =
      'https://api.finbassshamar.online/app-version';
  static const String releaseFileUrl =
      'https://buysellgame.store/downloads/version.json';

  // App is blocked when it is MORE than this many releases behind the latest.
  static const int maxVersionsBehind = 5;

  static Future<AppVersionInfo?> checkVersion() async {
    AppVersionInfo? info;
    try {
      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        info = AppVersionInfo.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}

    final tooOld = await _tooFarBehind();
    if (tooOld != null) {
      final url = tooOld['apkUrl'] ?? '';
      return AppVersionInfo(
        latestVersionCode: info?.latestVersionCode ?? 0,
        minimumVersionCode: 1 << 30,
        latestVersion: tooOld['version'] ?? '',
        minimumVersion: info?.minimumVersion ?? '',
        apkUrl: url.isNotEmpty ? url : (info?.apkUrl ?? ''),
      );
    }
    return info;
  }

  static Future<Map<String, String>?> _tooFarBehind() async {
    try {
      final response = await http
          .get(Uri.parse(
              '$releaseFileUrl?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestStr = (data['version'] ?? '').toString();
      final latest = latestStr.split('.');
      final current = (await PackageInfo.fromPlatform()).version.split('.');
      if (latest.length < 3 || current.length < 3) return null;
      if (latest[0] != current[0] || latest[1] != current[1]) return null;

      final lp = int.tryParse(latest[2]);
      final cp = int.tryParse(current[2]);
      if (lp == null || cp == null) return null;

      if (lp - cp > maxVersionsBehind) {
        return {
          'version': latestStr,
          'apkUrl': (data['downloadUrl'] ?? '').toString(),
        };
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> mustUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      final info = await checkVersion();
      if (info == null) return false;

      return currentBuildNumber < info.minimumVersionCode;
    } catch (_) {
      return false;
    }
  }
}
