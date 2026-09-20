import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class NoInternetOverlay extends StatefulWidget {
  final Widget child;
  const NoInternetOverlay({super.key, required this.child});

  @override
  State<NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<NoInternetOverlay>
    with SingleTickerProviderStateMixin {
  bool _offline = false;
  Timer? _retryTimer;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _checkNow();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        _setOffline(true);
      } else {
        _checkNow();
      }
    });
  }

  Future<void> _checkNow() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    _setOffline(!hasConnection);
  }

  void _setOffline(bool offline) {
    if (!mounted) return;
    setState(() => _offline = offline);
    _retryTimer?.cancel();
    if (offline) {
      _retryTimer = Timer(const Duration(seconds: 5), _checkNow);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _retryTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned.fill(
            child: Material(
              color: AppColors.bg.withOpacity(0.97),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: _spinController,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.0),
                              AppColors.primary,
                            ],
                          ),
                        ),
                        child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reconnecting...',
                      style: TextStyle(color: AppColors.hint, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
