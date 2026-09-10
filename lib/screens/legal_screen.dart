import 'package:flutter/material.dart';
import '../main.dart';

class LegalScreen extends StatelessWidget {
  final String type; // 'terms' or 'privacy'
  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isTerms = type == 'terms';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(isTerms ? 'Terms & Conditions' : 'Privacy Policy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              isTerms ? 'MYGame Marketplace — Terms & Conditions' : 'MYGame Marketplace — Privacy Policy',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Last updated: September 2026', style: TextStyle(color: AppColors.hint, fontSize: 12)),
            const SizedBox(height: 24),
            if (isTerms) ..._termsSections() else ..._privacySections(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<Widget> _termsSections() {
    return [
      _section('1. Acceptance of Terms', 'By using MYGame Marketplace, you agree to these Terms & Conditions. If you do not agree, please do not use the app.'),
      _section('2. Eligibility', 'You must be at least 18 years old, or the age of majority in your jurisdiction, to buy or sell on MYGame Marketplace.'),
      _section('3. Account Verification', 'Selling accounts requires identity verification (NIC, Driving License, or Passport). Providing false information may result in account suspension.'),
      _section('4. Escrow & Payments', 'All purchases are held in escrow for 24 hours or until admin review, whichever comes first. Funds are released to the seller after this period unless a dispute is raised.'),
      _section('5. Prohibited Activities', 'You may not list stolen accounts, engage in fraud, harass other users, or attempt to bypass the platform\'s payment or verification systems.'),
      _section('6. Fees', 'MYGame Marketplace charges a commission on each successful sale. The current rate is displayed at the time of listing.'),
      _section('7. Disputes', 'Disputes between buyers and sellers are reviewed and resolved by MYGame Marketplace admins. Their decision is final.'),
      _section('8. Account Suspension', 'We reserve the right to suspend or terminate accounts that violate these terms, engage in fraudulent activity, or pose a risk to other users.'),
      _section('9. Limitation of Liability', 'MYGame Marketplace acts as an intermediary and is not responsible for the quality, legality, or ownership status of accounts listed by sellers, beyond our verification process.'),
      _section('10. Changes to Terms', 'We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the new terms.'),
    ];
  }

  List<Widget> _privacySections() {
    return [
      _section('1. Information We Collect', 'We collect your email, phone number, NIC/License/Passport details, profile photo, and transaction history to operate the marketplace and verify your identity.'),
      _section('2. How We Use Your Information', 'Your information is used to process transactions, verify your identity, prevent fraud, communicate with you about orders, and improve our services.'),
      _section('3. Data Storage', 'Your data is stored securely on our servers. Sensitive account credentials shared during transactions are encrypted.'),
      _section('4. Data Sharing', 'We do not sell your personal data. Information is shared with buyers/sellers only as necessary to complete a transaction (e.g. account credentials after payment).'),
      _section('5. Verification Documents', 'NIC, Driving License, and Passport images along with selfie photos/videos are used solely for identity verification and are only accessible to authorized admins.'),
      _section('6. Your Rights', 'You may request a copy of your data or request account deletion by contacting support through the app.'),
      _section('7. Cookies & Tracking', 'The app may use device identifiers for push notifications and analytics to improve app performance.'),
      _section('8. Data Retention', 'We retain your data as long as your account is active, and for a reasonable period afterward to comply with legal and dispute-resolution obligations.'),
      _section('9. Security', 'We use industry-standard measures including encryption for sensitive data such as account credentials in escrow.'),
      _section('10. Contact Us', 'For privacy-related questions, use the "Report a Problem" feature in Settings to contact our support team.'),
    ];
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AppColors.hint, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
