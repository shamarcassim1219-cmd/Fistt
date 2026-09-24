import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class IntroScreen extends StatefulWidget {
  final Widget next;
  const IntroScreen({super.key, required this.next});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _floatController;

  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _buttonFadeOnly;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;

  final List<Map<String, dynamic>> _chipData = [
    {'icon': Icons.gps_fixed_rounded, 'label': 'PUBG'},
    {'icon': Icons.local_fire_department_rounded, 'label': 'Free Fire'},
    {'icon': Icons.military_tech_rounded, 'label': 'CODM'},
    {'icon': Icons.shield_rounded, 'label': 'MLBB'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

    _iconFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _iconScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack)));

    _titleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)));

    _subtitleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.7, curve: Curves.easeOut));
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)));

    _buttonFade = CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeOut));
    _buttonFadeOnly = _buttonFade;
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _getStarted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_intro', true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  Widget _animatedChip(int index) {
    final data = _chipData[index];
    final start = 0.45 + (index * 0.08);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final entranceFade = CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOut));
    final entranceSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOutBack)));
    final phaseOffset = index * (pi / 2);

    return FadeTransition(
      opacity: entranceFade,
      child: SlideTransition(
        position: entranceSlide,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = _floatController.value * 2 * pi + phaseOffset;
            final floatY = sin(t) * 5;
            final glow = (sin(t) + 1) / 2;
            return Transform.translate(
              offset: Offset(0, floatY),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12 + glow * 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3 + glow * 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15 + glow * 0.25),
                          blurRadius: 12 + glow * 10,
                          spreadRadius: glow * 2,
                        ),
                      ],
                    ),
                    child: Icon(data['icon'] as IconData, size: 30, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(data['label'] as String, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.bg,
                AppColors.bg,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _iconFade,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        final t = _floatController.value * 2 * pi;
                        final glow = (sin(t) + 1) / 2;
                        final breathe = 1.0 + sin(t) * 0.04;
                        return Transform.scale(
                          scale: breathe,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25 + glow * 0.35),
                                  blurRadius: 24 + glow * 20,
                                  spreadRadius: glow * 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.sports_esports_rounded, size: 70, color: AppColors.primary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: const Text(
                      'Buy & Sell Game\nAccounts Safely',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _subtitleFade,
                  child: SlideTransition(
                    position: _subtitleSlide,
                    child: const Text(
                      'Trusted marketplace with secure escrow\nfor your favorite game accounts',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.hint, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_chipData.length, (i) => _animatedChip(i)),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _buttonFade,
                  child: SlideTransition(
                    position: _buttonSlide,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        final t = _floatController.value * 2 * pi;
                        final glow = (sin(t) + 1) / 2;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25 + glow * 0.3),
                                blurRadius: 16 + glow * 14,
                                spreadRadius: glow * 1.5,
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _getStarted(context),
                              child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
