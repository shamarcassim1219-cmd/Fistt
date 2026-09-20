import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small UI preferences shared across screens (saved on the phone).
class UiPrefs {
  /// Glass (frosted) bottom navigation bar. On by default.
  static final ValueNotifier<bool> glassNav = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    glassNav.value = p.getBool('glass_nav') ?? true;
  }

  static Future<void> setGlassNav(bool v) async {
    glassNav.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('glass_nav', v);
  }
}
