import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import 'login_screen.dart';
import 'verification_screen.dart';
import 'profile_management_screen.dart';
import 'change_password_screen.dart';
import 'wallet_bank_details_screen.dart';
import 'my_listings_screen.dart';
import 'my_purchases_screen.dart';
import 'my_sales_screen.dart';
import 'referral_code_screen.dart';
import 'blocked_users_screen.dart';
import 'offers_screen.dart';
import 'report_problem_screen.dart';
import 'favorites_screen.dart';

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
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBiometricSetting();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() => _profile = profile);
    } catch (_) {}
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _biometricLock = prefs.getBool('biometric_lock_enabled') ?? false);
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_lock_enabled', value);
    setState(() => _biometricLock = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Biometric lock enabled — takes effect next time you open the app' : 'Biometric lock disabled')),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
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
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This permanently deletes your profile, listings, and wallet history. This cannot be undone. Continue?',
          style: TextStyle(color: AppColors.hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final user = _profile;

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('settings'))),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: user?['profilePhotoUrl'] != null ? NetworkImage(user!['profilePhotoUrl']) : null,
                      child: user?['profilePhotoUrl'] == null
                          ? const Icon(Icons.person, size: 32, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?['displayName'] ?? user?['email'] ?? 'Guest User',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 4),
                          _VerifiedBadgeChip(status: user?['verifiedStatus'] ?? 'not_verified'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.hint),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileManagementScreen()));
                        _loadProfile();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              _SectionHeader(AppLocalizations.t('account')),
              _tile(Icons.person_outline, AppLocalizations.t('profile_management'), null, () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileManagementScreen()));
                _loadProfile();
              }),
              _tile(Icons.lock_reset, AppLocalizations.t('change_password'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
              }),
              _tile(
                Icons.verified_outlined,
                AppLocalizations.t('verified_badge'),
                null,
                () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen()));
                  _loadProfile();
                },
              ),
              _tile(Icons.list_alt_outlined, AppLocalizations.t('my_listings'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()));
              }),
              _tile(Icons.shopping_bag_outlined, AppLocalizations.t('my_purchases'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPurchasesScreen()));
              }),
              _tile(Icons.storefront_outlined, AppLocalizations.t('my_sales'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MySalesScreen()));
              }),
              _tile(Icons.local_offer_outlined, AppLocalizations.t('offers'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
              }),
              _tile(Icons.bookmark_border, 'Saved / Wishlist Accounts', null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
              }),
              _tile(Icons.account_balance_outlined, AppLocalizations.t('wallet_bank_details'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletBankDetailsScreen()));
              }),
              _tile(Icons.card_giftcard_outlined, AppLocalizations.t('referral_code'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralCodeScreen()));
              }),

              _SectionHeader(AppLocalizations.t('security')),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint, color: AppColors.hint),
                title: Text(AppLocalizations.t('biometric_lock'), style: const TextStyle(color: Colors.white)),
                subtitle: const Text('Fingerprint / Face ID to open app', style: TextStyle(color: AppColors.hint)),
                value: _biometricLock,
                onChanged: _toggleBiometric,
              ),
              _tile(Icons.block_outlined, AppLocalizations.t('blocked_users'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
              }),

              _SectionHeader(AppLocalizations.t('notifications')),
              SwitchListTile(
                secondary: const Icon(Icons.receipt_long_outlined, color: AppColors.hint),
                title: Text(AppLocalizations.t('order_updates'), style: const TextStyle(color: Colors.white)),
                value: _notifyOrders,
                onChanged: (v) => setState(() => _notifyOrders = v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.local_offer_outlined, color: AppColors.hint),
                title: Text(AppLocalizations.t('offers_bids'), style: const TextStyle(color: Colors.white)),
                value: _notifyOffers,
                onChanged: (v) => setState(() => _notifyOffers = v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.campaign_outlined, color: AppColors.hint),
                title: Text(AppLocalizations.t('promotions'), style: const TextStyle(color: Colors.white)),
                value: _notifyPromos,
                onChanged: (v) => setState(() => _notifyPromos = v),
              ),

              _SectionHeader(AppLocalizations.t('preferences')),
              ListTile(
                leading: const Icon(Icons.language_outlined, color: AppColors.hint),
                title: Text(AppLocalizations.t('language'), style: const TextStyle(color: Colors.white)),
                subtitle: Text(lang, style: const TextStyle(color: AppColors.hint)),
                onTap: () async {
                  final choice = await showModalBottomSheet<String>(
                    context: context,
                    backgroundColor: AppColors.surface,
                    builder: (ctx) => SafeArea(
                      child: Wrap(
                        children: ['English', 'Sinhala', 'Tamil']
                            .map((l) => ListTile(
                                  title: Text(l, style: const TextStyle(color: Colors.white)),
                                  trailing: lang == l ? const Icon(Icons.check, color: AppColors.primary) : null,
                                  onTap: () => Navigator.pop(ctx, l),
                                ))
                            .toList(),
                      ),
                    ),
                  );
                  if (choice != null) await AppLocalizations.setLanguage(choice);
                },
              ),

              _SectionHeader('Privacy & Data'),
              _tile(Icons.download_outlined, 'Download My Data', null, () => _comingSoon('Data export')),
              _tile(Icons.privacy_tip_outlined, 'Privacy & Data Deletion Request', null, () => _comingSoon('Deletion request')),
              _tile(Icons.description_outlined, 'Terms & Conditions', null, () => _comingSoon('Terms viewer')),
              _tile(Icons.policy_outlined, 'Privacy Policy', null, () => _comingSoon('Privacy Policy viewer')),

              _SectionHeader(AppLocalizations.t('support')),
              _tile(Icons.help_outline, 'Help & FAQ', null, () => _comingSoon('Help & FAQ')),
              _tile(Icons.report_gmailerrorred_outlined, AppLocalizations.t('report_problem'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportProblemScreen()));
              }),

              _SectionHeader('About'),
              const ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.hint),
                title: Text('App Version', style: TextStyle(color: Colors.white)),
                subtitle: Text('1.0.0', style: TextStyle(color: AppColors.hint)),
              ),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: Text(AppLocalizations.t('logout'))),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _confirmDeleteAccount,
                    icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                    label: Text(AppLocalizations.t('delete_account'), style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.hint),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AppColors.hint)) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
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
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
    );
  }
}

class _VerifiedBadgeChip extends StatelessWidget {
  final String status;
  const _VerifiedBadgeChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'not_verified': ('Not Verified', AppColors.hint),
      'pending': ('Verification Pending', Colors.orange),
      'verified': ('Verified Seller', AppColors.primary),
      'rejected': ('Verification Rejected', Colors.redAccent),
    };
    final (label, color) = map[status] ?? ('Not Verified', AppColors.hint);
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      avatar: Icon(Icons.verified, size: 14, color: color),
      backgroundColor: AppColors.fieldFill,
      side: BorderSide(color: color.withOpacity(0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
