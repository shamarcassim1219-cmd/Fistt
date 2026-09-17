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

  static Future<AppVersionInfo?> checkVersion() async {
    try {
      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final info = AppVersionInfo.fromJson(data);

      return AppVersionInfo(
        latestVersionCode: info.latestVersionCode,
        minimumVersionCode: info.minimumVersionCode,
        latestVersion: info.latestVersion,
        minimumVersion: info.minimumVersion,
        apkUrl: info.apkUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> mustUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      final info = await checkVersion();

      if (info == null) {
        return false;
      }

      return currentBuildNumber < info.minimumVersionCode;
    } catch (_) {
      return false;
    }
  }
}
