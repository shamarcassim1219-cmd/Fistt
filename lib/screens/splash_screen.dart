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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _bgFade;
  late final Animation<double> _characterFade;
  late final Animation<Offset> _characterSlide;
  late final Animation<double> _progress;
  late final Animation<double> _readyFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

    _logoFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack)));

    _bgFade = CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.5, curve: Curves.easeOut));

    _characterFade = CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.75, curve: Curves.easeOut));
    _characterSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic)));

    _progress = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.95, curve: Curves.easeInOut)));

    _readyFade = CurvedAnimation(parent: _controller, curve: const Interval(0.88, 1.0, curve: Curves.easeOut));

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
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 3000));
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final seenIntro = prefs.getBool('seen_intro') ?? false;

    if (!mounted) return;

    Widget next = isLoggedIn ? const HomeScreen() : const LoginScreen();

    if (!seenIntro) {
      next = IntroScreen(next: next);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => next,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF160B2E),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ---- Sunset gradient + sun + palm silhouettes ----
              Opacity(
                opacity: _bgFade.value,
                child: CustomPaint(
                  size: Size(size.width, size.height),
                  painter: _MiamiBackgroundPainter(),
                ),
              ),

              // ---- Character slot (add assets/images/splash_character.png) ----
              Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _characterFade,
                  child: SlideTransition(
                    position: _characterSlide,
                    child: SizedBox(
                      height: size.height * 0.55,
                      width: size.width,
                      child: Image.asset(
                        'assets/images/splash_character.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),

              // ---- Logo + title ----
              Padding(
                padding: const EdgeInsets.only(top: 70),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Column(
                          children: [
                            const Icon(Icons.sports_esports_rounded, size: 56, color: Colors.white),
                            const SizedBox(height: 8),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(text: 'My', style: TextStyle(color: Colors.white)),
                                  TextSpan(text: 'Game', style: TextStyle(color: Color(0xFFFF4D9D))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('PLAY · TRADE · LEVEL UP',
                                style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 2)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Progress bar + status text ----
              Positioned(
                left: 32,
                right: 32,
                bottom: 40,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 5,
                        color: Colors.white.withOpacity(0.15),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progress.value,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFFFF4D9D), Color(0xFF6C4CF1)]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _readyFade.value > 0.5
                        ? FadeTransition(
                            opacity: _readyFade,
                            child: const Text('Welcome to MyGame ❤',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          )
                        : const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiamiBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Sunset gradient sky
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E1052), Color(0xFF7A2C6B), Color(0xFFE85D5D), Color(0xFFFFA45B)],
        stops: [0.0, 0.45, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Glowing sun
    final sunCenter = Offset(size.width / 2, size.height * 0.34);
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFD36E).withOpacity(0.9), const Color(0xFFFF7A5C).withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 120));
    canvas.drawCircle(sunCenter, 120, sunPaint);
    canvas.drawCircle(sunCenter, 55, Paint()..color = const Color(0xFFFFE29A));

    // Sun horizontal stripes (retro synthwave look)
    final stripePaint = Paint()..color = const Color(0xFF2E1052).withOpacity(0.5);
    for (int i = 0; i < 6; i++) {
      final y = sunCenter.dy - 5 + i * 9.0;
      canvas.drawRect(Rect.fromLTWH(sunCenter.dx - 55, y, 110, 3), stripePaint);
    }

    // Palm tree silhouettes (simple shapes)
    _drawPalm(canvas, Offset(size.width * 0.12, size.height * 0.62), size.height * 0.28, flip: false);
    _drawPalm(canvas, Offset(size.width * 0.9, size.height * 0.58), size.height * 0.32, flip: true);
  }

  void _drawPalm(Canvas canvas, Offset base, double height, {required bool flip}) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final trunkPath = Path();
    final dir = flip ? -1 : 1;
    trunkPath.moveTo(base.dx, base.dy);
    trunkPath.quadraticBezierTo(base.dx + dir * height * 0.15, base.dy - height * 0.5, base.dx + dir * height * 0.05, base.dy - height);
    canvas.drawPath(
      trunkPath,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * 0.06,
    );

    final topCenter = Offset(base.dx + dir * height * 0.05, base.dy - height);
    for (int i = 0; i < 6; i++) {
      final angle = (-pi / 2) + (i - 2.5) * 0.35 * dir;
      final frondEnd = topCenter + Offset(cos(angle), sin(angle)) * height * 0.35;
      final frondPath = Path()
        ..moveTo(topCenter.dx, topCenter.dy)
        ..quadraticBezierTo(
          topCenter.dx + (frondEnd.dx - topCenter.dx) * 0.5,
          topCenter.dy + (frondEnd.dy - topCenter.dy) * 0.3,
          frondEnd.dx,
          frondEnd.dy,
        );
      canvas.drawPath(
        frondPath,
        Paint()
          ..color = Colors.black.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = height * 0.035
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiamiBackgroundPainter oldDelegate) => false;
}
