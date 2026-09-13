import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final double delay;
  _Particle({required this.angle, required this.distance, required this.size, required this.delay});
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconRotate;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    final rand = Random();
    _particles = List.generate(28, (i) {
      return _Particle(
        angle: rand.nextDouble() * 2 * pi,
        distance: 90 + rand.nextDouble() * 70,
        size: 2 + rand.nextDouble() * 3,
        delay: rand.nextDouble() * 0.3,
      );
    });

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _iconScale = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.65, curve: Curves.elasticOut)));
    _iconFade = CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.55, curve: Curves.easeOut));
    _iconRotate = Tween<double>(begin: -0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.65, curve: Curves.easeOutBack)));

    _titleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.55, 0.8, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.55, 0.8, curve: Curves.easeOut)));

    _subtitleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.9, curve: Curves.easeOut));
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.9, curve: Curves.easeOut)));

    _loaderFade = CurvedAnimation(parent: _controller, curve: const Interval(0.85, 1.0, curve: Curves.easeOut));

    _controller.forward();
    _decideNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decideNextScreen() async {
    if (kIsWeb) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 2400));
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final seenIntro = prefs.getBool('seen_intro') ?? false;

    if (!mounted) return;

    Widget next = isLoggedIn ? const HomeScreen() : const LoginScreen();

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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(260, 260),
                        painter: _ParticlePainter(
                          particles: _particles,
                          progress: _controller.value,
                          color: AppColors.primary,
                        ),
                      ),
                      Opacity(
                        opacity: _iconFade.value,
                        child: Transform.rotate(
                          angle: _iconRotate.value,
                          child: Transform.scale(
                            scale: _iconScale.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.sports_esports_rounded, size: 60, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: const Text('MYGame Marketplace',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _subtitleFade,
                  child: SlideTransition(
                    position: _subtitleSlide,
                    child: const Text('Buy & Sell Game Accounts Safely',
                        style: TextStyle(fontSize: 14, color: AppColors.hint)),
                  ),
                ),
                const SizedBox(height: 40),
                Opacity(
                  opacity: _loaderFade.value,
                  child: const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final start = p.delay * 0.3;
      final end = 0.5 + p.delay * 0.1;
      double t = ((progress - start) / (end - start)).clamp(0.0, 1.0);
      final eased = 1 - pow(1 - t, 3).toDouble();

      final startOffset = Offset(cos(p.angle), sin(p.angle)) * p.distance;
      final pos = Offset.lerp(center + startOffset, center, eased)!;

      double opacity;
      if (progress < start) {
        opacity = 0;
      } else if (progress < end) {
        opacity = (1 - t) * (t < 0.15 ? t / 0.15 : 1.0);
      } else {
        opacity = 0;
      }
      opacity = opacity.clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => oldDelegate.progress != progress;
}
