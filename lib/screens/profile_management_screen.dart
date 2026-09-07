import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';

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
  File? _pickedPhoto;
  bool _profileLocked = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;

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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _pickedPhoto = File(picked.path);
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
                    padding: const EdgeInsets.all(16),
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
        );
      },
    );
  }
}
