import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'agreement_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

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

    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final agreedTerms = prefs.getBool('agreed_terms') ?? false;
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!mounted) return;

    Widget next;
    if (!seenOnboarding) {
      next = const OnboardingScreen();
    } else if (!agreedTerms) {
      next = const AgreementScreen();
    } else if (!isLoggedIn) {
      next = const LoginScreen();
    } else {
      next = const HomeScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports_rounded,
                size: 90, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(height: 16),
            Text(
              'MYGame Marketplace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buy & Sell Game Accounts Safely',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
