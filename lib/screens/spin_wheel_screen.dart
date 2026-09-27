import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> with SingleTickerProviderStateMixin {
  static const List<Color> _segmentColors = [
    Color(0xFF6C4CF1),
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFFE76F51),
    Color(0xFF3A2BB8),
    Color(0xFF0F8F86),
    Color(0xFFA3245F),
    Color(0xFF264653),
  ];

  late AnimationController _controller;
  late Animation<double> _rotation;

  bool _loading = true;
  bool _spinning = false;
  String? _error;
  List<dynamic> _prizes = [];
  bool _canSpin = true;
  int _hoursLeft = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _rotation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _loadConfig();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getSpinConfig();
      if (!mounted) return;
      setState(() {
        _prizes = (data['prizes'] as List?) ?? [];
        _canSpin = data['canSpin'] == true;
        _hoursLeft = (data['hoursUntilNextSpin'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _spin() async {
    if (_spinning || !_canSpin || _prizes.isEmpty) return;
    setState(() {
      _spinning = true;
      _error = null;
    });
    try {
      final result = await ApiService.spinWheel();
      if (!mounted) return;
      final prizeId = result['prizeId'];
      var index = _prizes.indexWhere((p) => p['id'] == prizeId);
      if (index < 0) index = 0;

      final n = _prizes.length;
      final segAngle = 2 * pi / n;
      double target = -(index * segAngle + segAngle / 2);
      while (target < 0) target += 2 * pi;
      target += 2 * pi * 6;

      final from = _rotation.value;
      _rotation = Tween<double>(begin: from, end: from + target).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();

      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _spinning = false;
        _canSpin = false;
        _hoursLeft = 24;
      });
      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _spinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final type = result['type'];
    String title;
    String body;
    switch (type) {
      case 'points':
        title = 'You won points! 🎉';
        body = '+${result['value']} points added to your account.';
        break;
      case 'cashback':
        title = 'Cashback! 💰';
        body = 'Rs ${result['value']} added to your wallet.';
        break;
      case 'cash_jackpot':
        title = 'JACKPOT! 🏆';
        body = 'Rs ${result['value']} added to your wallet!';
        break;
      case 'coupon':
        title = 'Discount Coupon! 🎟️';
        body = 'Code: ${result['code']}\n${result['discountPercent']}% off your next purchase.\nCheck "My Coupons" to use it.';
        break;
      default:
        title = 'Better luck next time!';
        body = 'Come back tomorrow for another spin.';
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nice!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Spin & Win'), backgroundColor: AppColors.bg),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadConfig, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _rotation,
                              builder: (context, child) => Transform.rotate(
                                angle: _rotation.value,
                                child: child,
                              ),
                              child: CustomPaint(
                                size: const Size(300, 300),
                                painter: _WheelPainter(
                                  labels: _prizes.map((p) => p['label'].toString()).toList(),
                                  colors: _segmentColors,
                                ),
                              ),
                            ),
                            const Positioned(
                              top: -6,
                              child: Icon(Icons.arrow_drop_down, size: 48, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: (_canSpin && !_spinning) ? _spin : null,
                          child: _spinning
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _canSpin ? 'SPIN THE WHEEL' : 'Come back in ${_hoursLeft}h',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'One free spin every day. Good luck!',
                        style: TextStyle(color: AppColors.hint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> labels;
  final List<Color> colors;
  _WheelPainter({required this.labels, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.isEmpty ? 1 : labels.length;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = 2 * pi / n;
    final startAngle = -pi / 2;

    for (int i = 0; i < n; i++) {
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + i * segAngle,
        segAngle,
        true,
        paint,
      );

      final labelAngle = startAngle + i * segAngle + segAngle / 2;
      final textRadius = radius * 0.62;
      final labelOffset = Offset(
        center.dx + textRadius * cos(labelAngle),
        center.dy + textRadius * sin(labelAngle),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 70);

      canvas.save();
      canvas.translate(labelOffset.dx, labelOffset.dy);
      canvas.rotate(labelAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.labels != labels || oldDelegate.colors != colors;
}
