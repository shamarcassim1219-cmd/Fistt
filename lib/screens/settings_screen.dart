import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import 'login_screen.dart';
import 'verification_screen.dart';
import 'profile_management_screen.dart';
import 'change_password_screen.dart';
import 'change_email_screen.dart';
import 'wallet_bank_details_screen.dart';
import 'my_listings_screen.dart';
import 'my_purchases_screen.dart';
import 'my_sales_screen.dart';
import 'referral_code_screen.dart';
import 'blocked_users_screen.dart';
import 'offers_screen.dart';
import 'live_chat_screen.dart';
import 'favorites_screen.dart';
import 'legal_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  bool _loadingPrefs = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBiometricSetting();
    _loadNotificationPreferences();
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

  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await ApiService.getNotificationPreferences();
      if (!mounted) return;
      setState(() {
        _notifyOrders = prefs['notifyOrders'] ?? true;
        _notifyOffers = prefs['notifyOffers'] ?? true;
        _notifyPromos = prefs['notifyPromos'] ?? false;
        _loadingPrefs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _saveNotificationPreferences() async {
    try {
      await ApiService.updateNotificationPreferences(_notifyOrders, _notifyOffers, _notifyPromos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
    // Clear the server-side FCM token first (while we still have a valid
    // auth token) so this device stops receiving this account's push
    // notifications, and invalidate the local FCM token too so a fresh
    // one is issued whoever logs in next on this device.
    await ApiService.clearFcmToken();
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
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
              _tile(
                Icons.verified_outlined,
                'Verification Center',
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
              _tile(Icons.email_outlined, 'Change Email', null, () async {
                final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailScreen()));
                if (changed == true) _loadProfile();
              }),
              _tile(Icons.lock_reset, AppLocalizations.t('change_password'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
              }),
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
              if (_loadingPrefs)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else ...[
                SwitchListTile(
                  secondary: const Icon(Icons.receipt_long_outlined, color: AppColors.hint),
                  title: Text(AppLocalizations.t('order_updates'), style: const TextStyle(color: Colors.white)),
                  subtitle: const Text('Order, escrow & dispute updates', style: TextStyle(color: AppColors.hint, fontSize: 11)),
                  value: _notifyOrders,
                  onChanged: (v) {
                    setState(() => _notifyOrders = v);
                    _saveNotificationPreferences();
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.local_offer_outlined, color: AppColors.hint),
                  title: Text(AppLocalizations.t('offers_bids'), style: const TextStyle(color: Colors.white)),
                  subtitle: const Text('Offers, bids & new messages', style: TextStyle(color: AppColors.hint, fontSize: 11)),
                  value: _notifyOffers,
                  onChanged: (v) {
                    setState(() => _notifyOffers = v);
                    _saveNotificationPreferences();
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.campaign_outlined, color: AppColors.hint),
                  title: Text(AppLocalizations.t('promotions'), style: const TextStyle(color: Colors.white)),
                  subtitle: const Text('Deals and platform announcements', style: TextStyle(color: AppColors.hint, fontSize: 11)),
                  value: _notifyPromos,
                  onChanged: (v) {
                    setState(() => _notifyPromos = v);
                    _saveNotificationPreferences();
                  },
                ),
              ],

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
              _tile(Icons.description_outlined, 'Terms & Conditions', null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(type: 'terms')));
              }),
              _tile(Icons.policy_outlined, 'Privacy Policy', null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(type: 'privacy')));
              }),

              _SectionHeader(AppLocalizations.t('support')),
              _tile(Icons.help_outline, 'Help & FAQ', null, () => _comingSoon('Help & FAQ')),
              _tile(Icons.support_agent_outlined, 'Live Chat with Admin', null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveChatScreen()));
              }),

              _SectionHeader('About'),
              _tile(Icons.info_outline, 'App Version', '1.0.4 — Tap to check for updates', _checkForUpdate),
              if (kIsWeb)
                _tile(Icons.android, 'Download Android App', 'Get the app for a better experience', () {
                  launchUrl(
                    Uri.parse('https://buysellgame.store/downloads/app-release.apk'),
                    mode: LaunchMode.externalApplication,
                  );
                }),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(onPressed: _confirmLogout, icon: const Icon(Icons.logout), label: Text(AppLocalizations.t('logout'))),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkForUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Text('Checking for updates...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final result = await ApiService.checkForUpdate('1.0.4');
      if (!mounted) return;
      Navigator.pop(context);

      if (result['updateAvailable'] == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Update Available', style: TextStyle(color: Colors.white)),
            content: Text(
              'Version ${result['latestVersion']} is available.\n\n${result['releaseNotes'] ?? ''}',
              style: const TextStyle(color: AppColors.hint, fontSize: 13),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
              if (result['downloadUrl'] != null)
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.tryParse(result['downloadUrl']);
                    bool launched = false;
                    if (uri != null) {
                      try {
                        launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        launched = false;
                      }
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open download link. Copy this URL: ${result['downloadUrl']}',
                          ),
                          duration: const Duration(seconds: 8),
                        ),
                      );
                    }
                  },
                  child: const Text('Download'),
                ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're on the latest version")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
