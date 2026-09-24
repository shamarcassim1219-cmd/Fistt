import 'package:flutter/material.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

/// Mixin for any State that shows sensitive content (account credentials,
/// admin chat with shared passwords, etc). Enables FLAG_SECURE on enter,
/// which blocks screenshots, screen recording, and recent-apps thumbnail
/// on Android — and disables it again on exit so the rest of the app is
/// unaffected.
mixin SecureScreenMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _enableSecure();
  }

  @override
  void dispose() {
    _disableSecure();
    super.dispose();
  }

  Future<void> _enableSecure() async {
    try {
      await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    } catch (_) {}
  }

  Future<void> _disableSecure() async {
    try {
      await FlutterWindowManagerPlus.clearFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    } catch (_) {}
  }
}
