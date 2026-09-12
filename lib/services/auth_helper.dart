import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

/// Checks if user is logged in. If not, opens LoginScreen and waits.
/// Returns true if user is (or becomes) logged in, false if they cancelled.
Future<bool> requireLogin(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  if (isLoggedIn) return true;

  if (!context.mounted) return false;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen(isGate: true)),
  );

  final prefsAfter = await SharedPreferences.getInstance();
  return prefsAfter.getBool('is_logged_in') ?? false;
}
