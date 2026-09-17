import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/auth_helper.dart';
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
import 'help_faq_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:background_downloader/background_downloader.dart';
import 'package:open_filex/open_filex.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadProfile();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (mounted) setState(() => _isLoggedIn = loggedIn);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() => _profile = profile);
    } catch (_) {}
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

  void _showReportProblemSheet() {
    final descCtrl = TextEditingController();
    bool submitting = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> submit() async {
            if (descCtrl.text.trim().isEmpty) {
              setSheetState(() => errorMsg = 'Please describe the problem');
              return;
            }
            setSheetState(() {
              submitting = true;
              errorMsg = null;
            });
            try {
              await ApiService.reportProblem(descCtrl.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Thanks — we'll get back to you via email.")),
              );
            } catch (e) {
              setSheetState(() {
                submitting = false;
                errorMsg = e.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.t('report_a_problem'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("Describe the issue and we'll follow up by email.", style: TextStyle(color: AppColors.hint, fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'What went wrong?'),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: submitting ? null : submit,
                    child: submitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
                          const SizedBox(height: 6),
                          if (user?['id'] != null)
                            InkWell(
                              onTap: () {
                                final code = 'MG-U${user!['id'].toString().padLeft(6, '0')}';
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppLocalizations.t('account_id_copied'))),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ID: MG-U${user!['id'].toString().padLeft(6, '0')}',
                                    style: const TextStyle(color: AppColors.hint, fontSize: 11),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy, size: 12, color: AppColors.hint),
                                ],
                              ),
                            ),
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
                if (!await requireLogin(context, reason: 'Login to manage your profile')) return;
                if (!context.mounted) return;
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileManagementScreen()));
                _loadProfile();
              }),
              _tile(
                Icons.verified_outlined,
                AppLocalizations.t('verification_center'),
                null,
                () async {
                  if (!await requireLogin(context, reason: 'Login to verify your account')) return;
                  if (!context.mounted) return;
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen()));
                  _loadProfile();
                },
              ),
              _tile(Icons.list_alt_outlined, AppLocalizations.t('my_listings'), null, () async {
                if (!await requireLogin(context, reason: 'Login to view your listings')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()));
              }),
              _tile(Icons.shopping_bag_outlined, AppLocalizations.t('my_purchases'), null, () async {
                if (!await requireLogin(context, reason: 'Login to view your purchases')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPurchasesScreen()));
              }),
              _tile(Icons.storefront_outlined, AppLocalizations.t('my_sales'), null, () async {
                if (!await requireLogin(context, reason: 'Login to view your sales')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MySalesScreen()));
              }),
              _tile(Icons.local_offer_outlined, AppLocalizations.t('offers'), null, () async {
                if (!await requireLogin(context, reason: 'Login to view your offers')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
              }),
              _tile(Icons.bookmark_border, AppLocalizations.t('saved_wishlist_accounts'), null, () async {
                if (!await requireLogin(context, reason: 'Login to view your saved accounts')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
              }),
              _tile(Icons.account_balance_outlined, AppLocalizations.t('wallet_bank_details'), null, () async {
                if (!await requireLogin(context, reason: 'Login to manage your bank details')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletBankDetailsScreen()));
              }),
              _tile(Icons.card_giftcard_outlined, AppLocalizations.t('referral_code'), null, () async {
                if (!await requireLogin(context, reason: 'Login to view your referral code')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralCodeScreen()));
              }),

              _SectionHeader(AppLocalizations.t('security')),
              _tile(Icons.email_outlined, AppLocalizations.t('change_email'), null, () async {
                if (!await requireLogin(context, reason: 'Login to change your email')) return;
                if (!context.mounted) return;
                final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailScreen()));
                if (changed == true) _loadProfile();
              }),
              _tile(Icons.lock_reset, AppLocalizations.t('change_password'), null, () async {
                if (!await requireLogin(context, reason: 'Login to change your password')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
              }),

              _tile(Icons.block_outlined, AppLocalizations.t('blocked_users'), null, () async {
                if (!await requireLogin(context, reason: 'Login to view blocked users')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
              }),

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
              _tile(Icons.description_outlined, AppLocalizations.t('terms_and_conditions'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(type: 'terms')));
              }),
              _tile(Icons.policy_outlined, AppLocalizations.t('privacy_policy'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(type: 'privacy')));
              }),

              _SectionHeader(AppLocalizations.t('support')),
              _tile(Icons.help_outline, AppLocalizations.t('help_and_faq'), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpFaqScreen()));
              }),
              _tile(Icons.support_agent_outlined, AppLocalizations.t('help_center'), null, () async {
                if (!await requireLogin(context, reason: 'Login to start a chat with support')) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveChatScreen()));
              }),
              _tile(Icons.report_problem_outlined, AppLocalizations.t('report_a_problem'), AppLocalizations.t('tell_us_what_went_wrong'), () async {
                if (!await requireLogin(context, reason: 'Login to report a problem')) return;
                if (!context.mounted) return;
                _showReportProblemSheet();
              }),

              _SectionHeader('About'),
              if (!kIsWeb)
              _tile(Icons.info_outline, 'App Version', '1.0.75 — Tap to check for updates', _checkForUpdate),
              if (kIsWeb)
                _tile(Icons.android, 'Download Android App', 'Get the app for a better experience', () {
                  launchUrl(
                    Uri.parse('https://buysellgame.store/downloads/app-release.apk'),
                    mode: LaunchMode.externalApplication,
                    webOnlyWindowName: '_blank',
                  );
                }),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: _isLoggedIn
                      ? OutlinedButton.icon(onPressed: _confirmLogout, icon: const Icon(Icons.logout), label: Text(AppLocalizations.t('logout')))
                      : ElevatedButton.icon(
                          onPressed: () async {
                            if (await requireLogin(context)) _checkLoginStatus();
                          },
                          icon: const Icon(Icons.login),
                          label: Text(AppLocalizations.t('login')),
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
      final result = await ApiService.checkForUpdate('1.0.75');
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
                  onPressed: () {
                    Navigator.pop(ctx);
                    _downloadAndInstallUpdate(result['downloadUrl']);
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

  Future<void> _downloadAndInstallUpdate(String url) async {
    double progress = 0;
    void Function(void Function())? refreshDialog;
    bool failed = false;
    String? failMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            refreshDialog = setDialogState;
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Downloading Update', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!failed) ...[
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      color: AppColors.primary,
                      backgroundColor: AppColors.border,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      progress > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : 'Starting download...',
                      style: const TextStyle(color: AppColors.hint, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please don't close or swipe away the app while the update downloads.",
                      style: TextStyle(color: AppColors.hint, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                    const SizedBox(height: 8),
                    Text(failMsg ?? 'Download failed', style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Close'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );

    try {
      final task = DownloadTask(
        url: url,
        filename: 'app-release.apk',
        baseDirectory: BaseDirectory.applicationSupport,
        updates: Updates.statusAndProgress,
        allowPause: false,
      );

      final result = await FileDownloader().download(
        task,
        onProgress: (p) {
          if (p >= 0 && p <= 1) {
            progress = p;
            refreshDialog?.call(() {});
          }
        },
      );

      if (result.status == TaskStatus.complete) {
        final filePath = await task.filePath();
        if (mounted) Navigator.pop(context);
        await OpenFilex.open(filePath);
      } else {
        failed = true;
        failMsg = 'Download ${result.status.name}. Please try again.';
        refreshDialog?.call(() {});
      }
    } catch (e) {
      failed = true;
      failMsg = e.toString().replaceFirst('Exception: ', '');
      refreshDialog?.call(() {});
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
