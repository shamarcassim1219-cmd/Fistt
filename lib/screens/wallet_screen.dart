import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('My Wallet')),
      body: uid == null
          ? const Center(child: Text('Please log in', style: TextStyle(color: AppColors.hint)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final balance = (snapshot.data?.get('walletBalance') as num?)?.toDouble() ?? 0.0;

                return ListView(
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
                          Text('Available Balance',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            'LKR ${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showTopUpSheet(context),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Top Up'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showWithdrawSheet(context, balance),
                            icon: const Icon(Icons.arrow_circle_up_outlined),
                            label: const Text('Withdraw'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text('Transaction History',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary)),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('wallet_transactions')
                          .where('uid', isEqualTo: uid)
                          .orderBy('createdAt', descending: true)
                          .limit(30)
                          .snapshots(),
                      builder: (context, txSnap) {
                        if (!txSnap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          );
                        }
                        final docs = txSnap.data!.docs;
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                                child: Text('No transactions yet',
                                    style: TextStyle(color: AppColors.hint))),
                          );
                        }
                        return Column(
                          children: docs.map((d) {
                            final data = d.data() as Map<String, dynamic>;
                            return _TransactionTile(
                              type: data['type'] ?? 'unknown',
                              amount: (data['amount'] as num?)?.toDouble() ?? 0,
                              status: data['status'] ?? 'pending',
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _showTopUpSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Up Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount (LKR)',
                labelStyle: TextStyle(color: AppColors.hint),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Bank transfer top-up: after submitting, upload your bank slip. '
                'Admin confirms manually — balance updates within a few hours.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Top-up request submitted — upload your slip next')),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, double balance) {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Withdraw to Bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Available: LKR ${balance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: AppColors.hint)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount (LKR)',
                labelStyle: TextStyle(color: AppColors.hint),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Make sure your bank details are saved in Settings → Wallet & Bank Details before withdrawing.',
              style: TextStyle(fontSize: 12, color: AppColors.hint),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Withdrawal request submitted')),
                  );
                },
                child: const Text('Request Withdrawal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String type;
  final double amount;
  final String status;

  const _TransactionTile({required this.type, required this.amount, required this.status});

  Map<String, dynamic> get _display {
    switch (type) {
      case 'topup':
        return {'label': 'Wallet Top-Up', 'icon': Icons.add_circle_outline, 'positive': true};
      case 'withdrawal':
        return {'label': 'Withdrawal', 'icon': Icons.arrow_circle_up_outlined, 'positive': false};
      case 'sale_release':
        return {'label': 'Account Sale', 'icon': Icons.sell_outlined, 'positive': true};
      case 'commission':
        return {'label': 'Platform Commission', 'icon': Icons.percent, 'positive': false};
      case 'referral_bonus':
        return {'label': 'Referral Bonus', 'icon': Icons.card_giftcard, 'positive': true};
      default:
        return {'label': type, 'icon': Icons.receipt_long, 'positive': true};
    }
  }

  Color _statusColor() {
    switch (status) {
      case 'completed':
        return Colors.greenAccent;
      case 'failed':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _display;
    final positive = d['positive'] as bool;
    final color = positive ? Colors.greenAccent : Colors.redAccent;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(d['icon'] as IconData, color: color, size: 20),
      ),
      title: Text(d['label'] as String, style: const TextStyle(color: Colors.white)),
      subtitle: Text(status, style: TextStyle(color: _statusColor(), fontSize: 12)),
      trailing: Text(
        '${positive ? '+' : '-'} LKR ${amount.toStringAsFixed(2)}',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
