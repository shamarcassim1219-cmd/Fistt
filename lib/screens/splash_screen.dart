import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final seenIntro = prefs.getBool('seen_intro') ?? false;

    if (!mounted) return;

    Widget next = const HomeScreen(); // Guest browsing allowed - login only required for protected actions

    if (!seenIntro) {
      next = IntroScreen(next: next);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_esports_rounded, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('MYGame Marketplace',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Buy & Sell Game Accounts Safely',
                style: TextStyle(fontSize: 14, color: AppColors.hint)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
