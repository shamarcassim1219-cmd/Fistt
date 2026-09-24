import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';

class ReferralCodeScreen extends StatefulWidget {
  const ReferralCodeScreen({super.key});

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  String? _code;
  int _points = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        _code = profile['myReferralCode'];
        _points = profile['referralPoints'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('referral_code'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                  : SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 10),
                          const Icon(Icons.card_giftcard, size: 64, color: AppColors.primary),
                          const SizedBox(height: 20),
                          Text(AppLocalizations.t('your_referral_code'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            'Share your code. When someone you referred gets their account verified, you earn 15 points (worth LKR 22.50) to use as a discount on your next purchase.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.hint, fontSize: 13),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: Text(
                              _code ?? '------',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: _copyCode,
                              icon: const Icon(Icons.copy),
                              label: Text(AppLocalizations.t('copy_code')),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.stars, size: 32, color: Colors.amber),
                                const SizedBox(height: 10),
                                const Text('Your Points Balance', style: TextStyle(color: AppColors.hint, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text('$_points points', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Worth LKR ${(_points * 1.5).toStringAsFixed(2)} in discounts',
                                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                const Text(
                                  'Use your points as a discount at checkout when buying any account.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.hint, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
