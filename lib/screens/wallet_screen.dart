import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: uid == null
          ? const Center(child: Text('Please log in'))
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
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
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
                    Text('Transaction History',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary)),
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
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final docs = txSnap.data!.docs;
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                                child: Text('No transactions yet',
                                    style: TextStyle(color: Colors.grey))),
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
            const Text('Top Up Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (LKR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Bank transfer top-up: after submitting, upload your bank slip. '
                'Admin confirms manually — balance updates within a few hours.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
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
            const Text('Withdraw to Bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Available: LKR ${balance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (LKR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Make sure your bank details are saved in Settings → Wallet & Bank Details before withdrawing.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
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
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _display;
    final positive = d['positive'] as bool;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (positive ? Colors.green : Colors.red).withOpacity(0.1),
        child: Icon(d['icon'] as IconData, color: positive ? Colors.green : Colors.red, size: 20),
      ),
      title: Text(d['label'] as String),
      subtitle: Text(status, style: TextStyle(color: _statusColor(), fontSize: 12)),
      trailing: Text(
        '${positive ? '+' : '-'} LKR ${amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: positive ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
