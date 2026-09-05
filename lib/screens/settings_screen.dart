import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricLock = false;
  bool _notifyOrders = true;
  bool _notifyOffers = true;
  bool _notifyPromos = false;
  String _language = 'English';

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'This permanently deletes your profile, listings, and wallet history. This cannot be undone. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // TODO: call Cloud Function to wipe user data + delete auth user
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? 'Guest User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      const _VerifiedBadgeChip(status: 'not_verified'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          _SectionHeader('Account'),
          _tile(Icons.person_outline, 'Profile Management', 'Name, photo, phone/email', () {}),
          _tile(Icons.lock_reset, 'Change Password / PIN', null, () {}),
          _tile(
            Icons.verified_outlined,
            'Verified Badge Status',
            'Pending / Approved — LKR 150 fee',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerificationScreen()),
              );
            },
          ),
          _tile(Icons.list_alt_outlined, 'My Listings', 'Active, Sold, Expired', () {}),
          _tile(Icons.bookmark_border, 'Saved / Wishlist Accounts', null, () {}),
          _tile(Icons.account_balance_outlined, 'Wallet & Bank Details', 'Withdrawal accounts', () {}),
          _tile(Icons.card_giftcard_outlined, 'Referral Code', 'Share & earn LKR 100 per user', () {}),

          _SectionHeader('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Lock'),
            subtitle: const Text('Fingerprint / Face ID to open app'),
            value: _biometricLock,
            onChanged: (v) => setState(() => _biometricLock = v),
          ),
          _tile(Icons.block_outlined, 'Blocked Users', null, () {}),

          _SectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.receipt_long_outlined),
            title: const Text('Order Updates'),
            value: _notifyOrders,
            onChanged: (v) => setState(() => _notifyOrders = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.local_offer_outlined),
            title: const Text('Offers & Bids'),
            value: _notifyOffers,
            onChanged: (v) => setState(() => _notifyOffers = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined),
            title: const Text('Promotions'),
            value: _notifyPromos,
            onChanged: (v) => setState(() => _notifyPromos = v),
          ),

          _SectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: Text(_language),
            onTap: () async {
              final choice = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Wrap(
                    children: ['Sinhala', 'English', 'Tamil']
                        .map((l) => ListTile(
                              title: Text(l),
                              onTap: () => Navigator.pop(ctx, l),
                            ))
                        .toList(),
                  ),
                ),
              );
              if (choice != null) setState(() => _language = choice);
            },
          ),

          _SectionHeader('Privacy & Data'),
          _tile(Icons.download_outlined, 'Download My Data', null, () {}),
          _tile(Icons.privacy_tip_outlined, 'Privacy & Data Deletion Request', null, () {}),
          _tile(Icons.description_outlined, 'Terms & Conditions', null, () {}),
          _tile(Icons.policy_outlined, 'Privacy Policy', null, () {}),

          _SectionHeader('Support'),
          _tile(Icons.help_outline, 'Help & FAQ', null, () {}),
          _tile(Icons.report_gmailerrorred_outlined, 'Report a Problem / Contact Admin', null, () {}),

          _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _VerifiedBadgeChip extends StatelessWidget {
  final String status;
  const _VerifiedBadgeChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'not_verified': ('Not Verified', Colors.grey),
      'pending': ('Verification Pending', Colors.orange),
      'verified': ('Verified Seller', Colors.blue),
    };
    final (label, color) = map[status]!;
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      avatar: Icon(Icons.verified, size: 14, color: color),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
