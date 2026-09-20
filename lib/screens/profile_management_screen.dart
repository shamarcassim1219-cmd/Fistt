import 'package:flutter/material.dart';
import '../services/safe_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import 'verification_screen.dart';
import 'my_listings_screen.dart';
import 'my_purchases_screen.dart';
import 'my_sales_screen.dart';
import 'offers_screen.dart';
import 'favorites_screen.dart';
import 'wallet_bank_details_screen.dart';
import 'security_screen.dart';
import 'blocked_users_screen.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _email = '';
  String? _photoUrl;
  XFile? _pickedPhoto;
  bool _profileLocked = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;
  String _verifiedStatus = 'not_verified';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        _nameCtrl.text = profile['displayName'] ?? '';
        _phoneCtrl.text = profile['phone'] ?? '';
        _email = profile['email'] ?? '';
        _photoUrl = profile['profilePhotoUrl'];
        _profileLocked = profile['profileLocked'] ?? false;
        _verifiedStatus = profile['verifiedStatus'] ?? 'not_verified';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImageSafe(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _pickedPhoto = picked;
      _uploadingPhoto = true;
    });
    try {
      final url = await ApiService.uploadImage(_pickedPhoto!);
      await ApiService.updateProfilePhoto(url);
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _save() async {
    if (_profileLocked) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.updateProfile(_nameCtrl.text.trim(), _phoneCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated and locked')),
      );
      _loadProfile();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
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

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
    );
  }

  String _verificationSubtitle() {
    switch (_verifiedStatus) {
      case 'verified':
        return 'Verified Seller';
      case 'pending':
        return 'Pending review';
      case 'rejected':
        return 'Rejected — tap to re-upload';
      default:
        return 'Not verified yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('profile_management'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 30),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppColors.primary.withOpacity(0.2),
                                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                                    child: _photoUrl == null
                                        ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: _uploadingPhoto ? null : _pickPhoto,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.primary,
                                        child: _uploadingPhoto
                                            ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (_profileLocked)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_outline, color: Colors.orangeAccent, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.t('profile_locked_msg'),
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            TextField(
                              enabled: false,
                              controller: TextEditingController(text: _email),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(labelText: AppLocalizations.t('email')),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _nameCtrl,
                              enabled: !_profileLocked,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(labelText: AppLocalizations.t('display_name')),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _phoneCtrl,
                              enabled: !_profileLocked,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(labelText: AppLocalizations.t('phone_number')),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                            ],

                            if (!_profileLocked) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  child: _saving
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : Text(AppLocalizations.t('save_profile'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      _sectionHeader('Trust & Activity'),
                      _tile(Icons.verified_outlined, AppLocalizations.t('verification_center'), _verificationSubtitle(), () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen()));
                        _loadProfile();
                      }),
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
                      _tile(Icons.bookmark_border, AppLocalizations.t('saved_wishlist_accounts'), null, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                      }),

                      _sectionHeader('Payments & Security'),
                      _tile(Icons.account_balance_outlined, AppLocalizations.t('wallet_bank_details'), null, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletBankDetailsScreen()));
                      }),
                      _tile(Icons.shield_outlined, 'Security', 'Email, password, two-step verification', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()));
                      }),
                      _tile(Icons.block_outlined, AppLocalizations.t('blocked_users'), null, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
                      }),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
