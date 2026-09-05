import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

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
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ApiService.getProfile();
      _bankNameCtrl.text = profile['bankName'] ?? '';
      _accountNameCtrl.text = profile['bankAccountName'] ?? '';
      _accountNumberCtrl.text = profile['bankAccountNumber'] ?? '';
      _branchCtrl.text = profile['bankBranch'] ?? '';
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateBankDetails(
        _bankNameCtrl.text.trim(),
        _accountNameCtrl.text.trim(),
        _accountNumberCtrl.text.trim(),
        _branchCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank details saved')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Wallet & Bank Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('This account is used for withdrawal requests from your wallet.',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: _bankNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Bank Name')),
                  const SizedBox(height: 14),
                  TextField(controller: _accountNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Account Holder Name')),
                  const SizedBox(height: 14),
                  TextField(controller: _accountNumberCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Account Number')),
                  const SizedBox(height: 14),
                  TextField(controller: _branchCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Branch')),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Save Bank Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
