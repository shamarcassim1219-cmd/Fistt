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
      _section('1. Acceptance of Terms',
          'By downloading, accessing, or using MYGame Marketplace ("the Platform", "we", "us"), you agree to be legally bound by these Terms & Conditions and our Privacy Policy. If you do not agree with any part of these terms, you must not access or use the Platform. We may update these Terms at any time, and your continued use of the app after such changes constitutes your acceptance of the revised Terms.'),
      _section('2. Eligibility',
          'You must be at least 18 years old, or the age of majority in your jurisdiction, to create an account, buy, or sell on MYGame Marketplace. By using the Platform, you represent and warrant that you meet this requirement and that all registration information you submit is accurate and truthful. Accounts found to belong to minors may be suspended or terminated at any time.'),
      _section('3. Account Registration & Verification',
          'To sell accounts on the Platform, you must complete identity verification by submitting a valid NIC, Driving License, or Passport, along with any additional documents or selfie/video verification we may request. Providing false, misleading, or fraudulent information during verification is strictly prohibited and may result in immediate account suspension, forfeiture of pending funds, and reporting to relevant authorities where applicable. You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account.'),
      _section('4. Listings & Accuracy of Information',
          'Sellers are solely responsible for the accuracy, completeness, and legality of the information provided in their listings, including account rank, skins, items, and ownership history. Misrepresenting a listing may result in the listing being removed, the seller\'s account being suspended, and funds being withheld pending investigation.'),
      _section('5. Escrow & Payments',
          'All purchases made through the Platform are processed via our escrow system. Buyer payments are held securely by MYGame Marketplace and are not released to the seller until the buyer confirms receipt of the account, the review/holding period expires without a dispute being raised, or an admin resolves a dispute in the seller\'s favor. Sellers acknowledge that funds may be withheld or reversed if fraud, misrepresentation, or a valid dispute is identified.'),
      _section('6. Prohibited Activities',
          'You may not: (a) list stolen, hacked, or unauthorized accounts; (b) engage in fraud, phishing, or deceptive practices; (c) harass, threaten, or abuse other users or Platform staff; (d) attempt to bypass, circumvent, or manipulate the Platform\'s escrow, payment, verification, or dispute systems; (e) use the Platform to launder money or conduct any illegal transaction; or (f) create multiple accounts to evade a suspension or ban. Violation of this section may result in immediate and permanent termination of your account without refund.'),
      _section('7. Fees & Commission',
          'MYGame Marketplace charges a commission on each successful sale completed through the Platform, calculated as a percentage of the final sale price. The applicable commission rate is displayed to sellers at the time of listing an account and may vary by game category or promotional period. Withdrawal of funds from your wallet may also be subject to processing fees or minimum withdrawal thresholds as displayed in the app.'),
      _section('8. Disputes & Resolution',
          'In the event of a disagreement between a buyer and seller regarding an order, either party may raise a dispute through the app before the escrow period ends. Our admin team will review all evidence submitted by both parties, including chat logs, screenshots, and account access records, and will make a final and binding decision. MYGame Marketplace reserves the right to refund the buyer, release funds to the seller, or take any other action deemed appropriate based on the evidence provided.'),
      _section('9. Account Suspension & Termination',
          'We reserve the right, at our sole discretion, to suspend, restrict, or permanently terminate any account that violates these Terms, engages in fraudulent or suspicious activity, receives repeated valid complaints, or poses a risk to the safety or integrity of the Platform or its users. Upon termination, any pending balances may be withheld pending investigation, and access to the account and its associated data may be revoked without prior notice.'),
      _section('10. Limitation of Liability',
          'MYGame Marketplace acts solely as an intermediary platform connecting buyers and sellers of game accounts. While we perform identity verification and operate an escrow and dispute resolution system, we do not guarantee the quality, legality, continued ownership status, or performance of any account listed by a seller beyond what our verification process covers. To the fullest extent permitted by law, MYGame Marketplace shall not be liable for any indirect, incidental, or consequential damages arising from your use of the Platform, including loss of account access outside of our systems, in-game bans issued by third-party game publishers, or disputes arising after a transaction has been marked complete.'),
      _section('11. Intellectual Property',
          'All game titles, logos, and trademarks referenced on the Platform (including PUBG, Free Fire, Call of Duty Mobile, and Mobile Legends: Bang Bang) belong to their respective owners. MYGame Marketplace is an independent, third-party marketplace and is not affiliated with, endorsed by, or sponsored by any of these game publishers.'),
      _section('12. Governing Law',
          'These Terms shall be governed by and construed in accordance with the laws applicable in the jurisdiction in which MYGame Marketplace operates, without regard to conflict of law principles. Any disputes arising from these Terms that cannot be resolved through our internal dispute process may be subject to the exclusive jurisdiction of the applicable courts.'),
      _section('13. Changes to These Terms',
          'We may revise these Terms & Conditions from time to time to reflect changes in our services, legal requirements, or business practices. We will make reasonable efforts to notify users of material changes through the app. Your continued use of MYGame Marketplace after any such update constitutes your acceptance of the revised Terms.'),
    ];
  }

  List<Widget> _privacySections() {
    return [
      _section('1. Information We Collect',
          'We collect information you provide directly, including your name, email address, phone number, profile photo, and payment/bank details used for withdrawals. To enable secure transactions, we also collect government-issued identification (NIC, Driving License, or Passport) and, where required, selfie photos or short verification videos. Additionally, we automatically collect certain technical information such as device identifiers, app usage logs, IP address, and transaction history to help operate, secure, and improve the Platform.'),
      _section('2. How We Use Your Information',
          'Your information is used to: create and manage your account; verify your identity and prevent fraud; process purchases, sales, escrow, and withdrawals; facilitate communication between buyers and sellers and our support team; send you order, security, and promotional notifications (which you can manage in Settings); investigate and resolve disputes; and improve the performance, safety, and features of the Platform over time.'),
      _section('3. Data Storage & Retention',
          'Your data is stored securely on servers operated or contracted by MYGame Marketplace. We retain your personal information for as long as your account remains active, and for a reasonable additional period afterward as necessary to comply with legal obligations, resolve disputes, enforce our agreements, and maintain accurate business and financial records.'),
      _section('4. Data Sharing & Disclosure',
          'We do not sell your personal information to third parties. Limited information is shared between a buyer and seller only as strictly necessary to complete a transaction — for example, account login credentials are shared with the buyer only after payment has been confirmed and held in escrow. We may also disclose information where required by law, to comply with a valid legal process, to protect the rights and safety of our users, or to prevent fraud or security incidents.'),
      _section('5. Verification Documents',
          'Identification documents (NIC, Driving License, Passport) and any selfie photos or videos submitted for verification purposes are used solely to confirm your identity and eligibility to use the Platform. These documents are stored securely, encrypted where applicable, and are accessible only to authorized MYGame Marketplace administrators for verification and fraud-prevention purposes — they are never shared with other users or third parties.'),
      _section('6. Your Rights',
          'Depending on your jurisdiction, you may have the right to request access to the personal data we hold about you, request corrections to inaccurate data, request deletion of your account and associated data (subject to legal and financial record-keeping requirements), or object to certain uses of your data. You can exercise these rights by contacting our support team through the "Report a Problem" or "Live Chat with Admin" features in Settings.'),
      _section('7. Cookies, Device Data & Notifications',
          'The app may use device identifiers, push notification tokens, and similar technologies to deliver order updates, security alerts, and (optionally) promotional notifications, and to help us understand app performance and usage patterns. You can manage your notification preferences at any time from the Notifications section in Settings on supported platforms.'),
      _section('8. Data Security',
          'We implement industry-standard technical and organizational security measures to protect your data, including encryption of sensitive information such as account credentials exchanged during escrow transactions and restricted, role-based access to verification documents. However, no method of transmission or storage is completely secure, and we cannot guarantee absolute security of your information.'),
      _section('9. Children\'s Privacy',
          'MYGame Marketplace is not intended for use by individuals under the age of 18. We do not knowingly collect personal information from minors. If we become aware that a minor has provided us with personal information, we will take steps to delete such information and terminate the associated account.'),
      _section('10. International Data Handling',
          'If you access MYGame Marketplace from outside the country in which our servers are located, your information may be transferred to, stored, and processed in a different jurisdiction. By using the Platform, you consent to this transfer, storage, and processing in accordance with this Privacy Policy.'),
      _section('11. Changes to This Policy',
          'We may update this Privacy Policy from time to time to reflect changes in our practices, technology, or legal requirements. We will make reasonable efforts to notify users of material changes through the app. Your continued use of MYGame Marketplace after such updates constitutes your acceptance of the revised Privacy Policy.'),
      _section('12. Contact Us',
          'If you have any questions, concerns, or requests regarding this Privacy Policy or how your data is handled, please contact our support team using the "Report a Problem" feature or "Live Chat with Admin" option available in the Settings section of the app.'),
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
