import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final String purpose;
  final String? referralCode;
  final bool isGate;

  const OtpVerifyScreen({super.key, required this.email, required this.purpose, this.referralCode, this.isGate = false});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _codeCtrl = TextEditingController();
  bool _verifying = false;
  String? _error;
  bool _resending = false;
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resendCode() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ApiService.resendOtp(widget.email, widget.purpose);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new code has been sent')));
      _startCountdown();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      if (widget.purpose == 'register') {
        await ApiService.verifyRegistration(widget.email, code, referralCode: widget.referralCode);
      } else {
        await ApiService.verifyLogin(widget.email, code);
      }

      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) await ApiService.saveFcmToken(fcmToken);
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      if (widget.isGate) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(AppLocalizations.t('verify_your_email'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.t('enter_code_sent_to')}\n${widget.email}',
                    style: const TextStyle(color: AppColors.hint, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(counterText: '', hintText: '000000'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verify,
                      child: _verifying
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(AppLocalizations.t('verify'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: _secondsLeft > 0
                        ? Text(
                            'Resend code in ${_secondsLeft}s',
                            style: const TextStyle(color: AppColors.hint, fontSize: 13),
                          )
                        : TextButton(
                            onPressed: _resending ? null : _resendCode,
                            child: _resending
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                : const Text('Resend Code', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
