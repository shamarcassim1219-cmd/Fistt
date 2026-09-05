import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final bank = doc.data()?['bankDetails'] as Map<String, dynamic>?;
    if (bank != null) {
      _bankNameCtrl.text = bank['bankName'] ?? '';
      _accountNameCtrl.text = bank['accountName'] ?? '';
      _accountNumberCtrl.text = bank['accountNumber'] ?? '';
      _branchCtrl.text = bank['branch'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'bankDetails': {
          'bankName': _bankNameCtrl.text.trim(),
          'accountName': _accountNameCtrl.text.trim(),
          'accountNumber': _accountNumberCtrl.text.trim(),
          'branch': _branchCtrl.text.trim(),
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details saved')),
      );
      Navigator.pop(context);
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
                          child: Text(
                            'This account is used for withdrawal requests from your wallet.',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bankNameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      labelStyle: TextStyle(color: AppColors.hint),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _accountNameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      labelStyle: TextStyle(color: AppColors.hint),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _accountNumberCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      labelStyle: TextStyle(color: AppColors.hint),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _branchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Branch',
                      labelStyle: TextStyle(color: AppColors.hint),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Save Bank Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
