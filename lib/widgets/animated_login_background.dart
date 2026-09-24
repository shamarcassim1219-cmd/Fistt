import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';

class AnimatedLoginBackground extends StatefulWidget {
  const AnimatedLoginBackground({super.key});

  @override
  State<AnimatedLoginBackground> createState() => _AnimatedLoginBackgroundState();
}

class _AnimatedLoginBackgroundState extends State<AnimatedLoginBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _bgController,
          builder: (context, child) {
            return CustomPaint(
              painter: _LoginBackgroundPainter(_bgController.value),
            );
          },
        ),
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  final double t;
  _LoginBackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(rect, Paint()..color = AppColors.bg);

    final sweep = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF2E1052).withOpacity(0.55),
        const Color(0xFF7A2C6B).withOpacity(0.25),
        AppColors.bg.withOpacity(0.0),
      ],
      stops: const [0.0, 0.4, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = sweep.createShader(rect));

    final angle1 = t * 2 * pi;
    final blob1Center = Offset(
      size.width * 0.2 + sin(angle1) * size.width * 0.12,
      size.height * 0.15 + cos(angle1) * size.height * 0.05,
    );
    final glow1 = (sin(angle1) + 1) / 2;
    canvas.drawCircle(
      blob1Center,
      size.width * 0.45,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF4D9D).withOpacity(0.18 + glow1 * 0.10),
            const Color(0xFFFF4D9D).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: blob1Center, radius: size.width * 0.45))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );

    final angle2 = (t * 2 * pi) + pi;
    final blob2Center = Offset(
      size.width * 0.85 + sin(angle2) * size.width * 0.10,
      size.height * 0.75 + cos(angle2) * size.height * 0.06,
    );
    final glow2 = (cos(angle2) + 1) / 2;
    canvas.drawCircle(
      blob2Center,
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6C4CF1).withOpacity(0.16 + glow2 * 0.10),
            const Color(0xFF6C4CF1).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: blob2Center, radius: size.width * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70),
    );

    final angle3 = t * 2 * pi + pi / 2;
    final blob3Center = Offset(
      size.width * 0.55 + sin(angle3) * size.width * 0.08,
      size.height * 0.45 + cos(angle3) * size.height * 0.08,
    );
    final glow3 = (sin(angle3) + 1) / 2;
    canvas.drawCircle(
      blob3Center,
      size.width * 0.3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFE85D5D).withOpacity(0.08 + glow3 * 0.06),
            const Color(0xFFE85D5D).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: blob3Center, radius: size.width * 0.3))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) => oldDelegate.t != t;
}
