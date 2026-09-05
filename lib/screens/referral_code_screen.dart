import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class ReferralCodeScreen extends StatefulWidget {
  const ReferralCodeScreen({super.key});

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  String? _myCode;
  bool _loading = true;
  final _enterCodeCtrl = TextEditingController();
  bool _redeeming = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadOrCreateCode();
  }

  Future<void> _loadOrCreateCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await ref.get();
    var code = doc.data()?['myReferralCode'] as String?;

    if (code == null) {
      code = 'MYG${uid.substring(0, 6).toUpperCase()}';
      await ref.set({'myReferralCode': code}, SetOptions(merge: true));
    }

    setState(() {
      _myCode = code;
      _loading = false;
    });
  }

  Future<void> _redeem() async {
    final code = _enterCodeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _redeeming = true;
      _message = null;
    });
    try {
      // NOTE: This calls the processReferralBonus Cloud Function once deployed.
      // For now this is a placeholder until Cloud Functions are wired into the app.
      setState(() => _message = 'Referral bonus will be credited once Cloud Functions are connected.');
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Referral Code')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4A2FD6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Referral Code',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_myCode ?? '',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _myCode ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Share this code — earn LKR 100 per signup',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Have a referral code?',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _enterCodeCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter code',
                            hintStyle: TextStyle(color: AppColors.hint),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _redeeming ? null : _redeem,
                        child: _redeeming
                            ? const SizedBox(
                                height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('Redeem'),
                      ),
                    ],
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                  ],
                ],
              ),
            ),
    );
  }
}
