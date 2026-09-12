import 'package:flutter/material.dart';
import '../main.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I buy a game account?',
      'a': 'Browse listings, tap on an account you like, and tap "Buy Now" or make an offer. Once payment is confirmed, the funds go into escrow and the seller releases the account credentials to you.',
    },
    {
      'q': 'How does escrow protect me?',
      'a': 'When you pay for an account, your money is held safely by MYGame Marketplace instead of going directly to the seller. It is only released to the seller after the order is confirmed complete or after the review period ends without a dispute.',
    },
    {
      'q': 'How do I sell my game account?',
      'a': 'Go to "Sell an Account" from the home screen, fill in the game details, price, and upload proof of ownership. Once approved by our admin team, your listing goes live.',
    },
    {
      'q': 'Why do I need to verify my identity?',
      'a': 'Identity verification (NIC, Driving License, or Passport) helps keep the marketplace safe from scammers and fraud, protecting both buyers and sellers.',
    },
    {
      'q': 'What happens if there is a dispute?',
      'a': 'If a buyer or seller raises a dispute on an order, our admin team reviews the evidence from both sides and makes a final decision to resolve it fairly.',
    },
    {
      'q': 'How long does withdrawal take?',
      'a': 'Withdrawals are reviewed and processed by our admin team, typically within 24-48 hours after being requested from your Wallet.',
    },
    {
      'q': 'What fees does MYGame Marketplace charge?',
      'a': 'A commission is charged on each successful sale. The exact percentage is shown to sellers at the time of listing an account.',
    },
    {
      'q': 'Can I cancel an order?',
      'a': 'Orders can be cancelled before the seller confirms the handover. Once credentials are shared and confirmed, cancellations are handled through the dispute process instead.',
    },
    {
      'q': 'Is my payment information safe?',
      'a': 'Yes. We do not store your card details. Payments are processed securely and account credentials shared during transactions are encrypted.',
    },
    {
      'q': 'How do I contact support?',
      'a': 'Use "Live Chat with Admin" in Settings for direct help, or use the "Report a Problem" option for account-specific issues.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _faqs.length,
          itemBuilder: (context, index) {
            final item = _faqs[index];
            return Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.hint,
                  title: Text(item['q']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['a']!, style: const TextStyle(color: AppColors.hint, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
