import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';

class WalletBankDetailsScreen extends StatefulWidget {
  const WalletBankDetailsScreen({super.key});

  @override
  State<WalletBankDetailsScreen> createState() => _WalletBankDetailsScreenState();
}

class _WalletBankDetailsScreenState extends State<WalletBankDetailsScreen> {
  final _bankNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  bool _codeSent = false;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        _profile = profile;
        _bankNameCtrl.text = profile['bankName'] ?? '';
        _accountNameCtrl.text = profile['bankAccountName'] ?? '';
        _accountNumberCtrl.text = profile['bankAccountNumber'] ?? '';
        _branchCtrl.text = profile['bankBranch'] ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _requestChange() async {
    if (_bankNameCtrl.text.trim().isEmpty ||
        _accountNameCtrl.text.trim().isEmpty ||
        _accountNumberCtrl.text.trim().isEmpty ||
        _branchCtrl.text.trim().isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ApiService.requestBankDetailsChange(
        _bankNameCtrl.text.trim(),
        _accountNameCtrl.text.trim(),
        _accountNumberCtrl.text.trim(),
        _branchCtrl.text.trim(),
      );
      setState(() => _codeSent = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmChange() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ApiService.confirmBankDetailsChange(_codeCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('wallet_bank_details'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(AppLocalizations.t('bank_details_notice'), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _bankNameCtrl,
                        enabled: !_codeSent,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: AppLocalizations.t('bank_name')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _accountNameCtrl,
                        enabled: !_codeSent,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: AppLocalizations.t('account_holder_name')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _accountNumberCtrl,
                        enabled: !_codeSent,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: AppLocalizations.t('account_number')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _branchCtrl,
                        enabled: !_codeSent,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: AppLocalizations.t('branch')),
                      ),

                      if (_codeSent) ...[
                        const SizedBox(height: 20),
                        Text(AppLocalizations.t('enter_verification_code'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(color: Colors.white, letterSpacing: 4),
                          decoration: InputDecoration(labelText: AppLocalizations.t('verification_code'), counterText: ''),
                        ),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : (_codeSent ? _confirmChange : _requestChange),
                          child: _submitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(_codeSent ? AppLocalizations.t('confirm') : AppLocalizations.t('send_verification_code'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
