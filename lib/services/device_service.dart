import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static String? _cachedFingerprint;
  static String? _cachedModel;

  static Future<void> _load() async {
    if (_cachedFingerprint != null) return;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _cachedFingerprint = androidInfo.id; // Android ID — stable per device install
      _cachedModel = '${androidInfo.manufacturer} ${androidInfo.model}'.trim();
    } catch (e) {
      _cachedFingerprint = 'unknown-device';
      _cachedModel = 'Unknown Device';
    }
  }

  static Future<String> getFingerprint() async {
    await _load();
    return _cachedFingerprint ?? 'unknown-device';
  }

  static Future<String> getModel() async {
    await _load();
    return _cachedModel ?? 'Unknown Device';
  }
}
