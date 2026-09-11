import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _loadingStatus = true;
  String _verifiedStatus = 'not_verified';
  String? _documentType;
  String? _statusLoadError;

  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _nicNumberCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _selectedProvince;
  String? _selectedDistrict;

  String _selectedDocType = 'nic';
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  bool _submitting = false;
  String? _error;

  static const Map<String, List<String>> _provinceDistricts = {
    'Western': ['Colombo', 'Gampaha', 'Kalutara'],
    'Central': ['Kandy', 'Matale', 'Nuwara Eliya'],
    'Southern': ['Galle', 'Matara', 'Hambantota'],
    'Northern': ['Jaffna', 'Kilinochchi', 'Mannar', 'Vavuniya', 'Mullaitivu'],
    'Eastern': ['Trincomalee', 'Batticaloa', 'Ampara'],
    'North Western': ['Kurunegala', 'Puttalam'],
    'North Central': ['Anuradhapura', 'Polonnaruwa'],
    'Uva': ['Badulla', 'Monaragala'],
    'Sabaragamuwa': ['Ratnapura', 'Kegalle'],
  };

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ApiService.getVerificationStatusFull();
      setState(() {
        _verifiedStatus = data['verifiedStatus'] ?? 'not_verified';
        _documentType = data['documentType'];
        _loadingStatus = false;
        _statusLoadError = null;
      });
    } catch (e) {
      setState(() {
        _loadingStatus = false;
        _statusLoadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickImage(String slot) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      if (slot == 'front') _frontImage = File(picked.path);
      if (slot == 'back') _backImage = File(picked.path);
      if (slot == 'selfie') _selfieImage = File(picked.path);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null || _selectedDistrict == null) {
      setState(() => _error = 'Please select province and district');
      return;
    }
    if (_frontImage == null) {
      setState(() => _error = 'Please upload the front document photo');
      return;
    }
    if (_selectedDocType == 'nic' && _backImage == null) {
      setState(() => _error = 'Please upload the back of your NIC');
      return;
    }
    if (_selfieImage == null) {
      setState(() => _error = 'Please take a live selfie');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final frontUrl = await ApiService.uploadImage(_frontImage!);
      String? backUrl;
      if (_backImage != null) {
        backUrl = await ApiService.uploadImage(_backImage!);
      }
      final selfieUrl = await ApiService.uploadImage(_selfieImage!);

      await ApiService.submitVerification(
        fullName: _fullNameCtrl.text.trim(),
        nicNumber: _nicNumberCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        province: _selectedProvince!,
        district: _selectedDistrict!,
        documentType: _selectedDocType,
        frontImageUrl: frontUrl,
        backImageUrl: backUrl,
        selfieImageUrl: selfieUrl,
        selfieVideoUrl: null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted — pending admin review')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('get_verified'))),
          body: _loadingStatus
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SafeArea(child: _buildBody()),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_statusLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load verification status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_statusLoadError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  setState(() => _loadingStatus = true);
                  _loadStatus();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_verifiedStatus == 'pending') {
      return _StatusMessage(
        icon: Icons.hourglass_top_outlined,
        color: Colors.orangeAccent,
        title: AppLocalizations.t('verification_pending'),
        message: 'Your ${_docTypeLabel(_documentType)} verification is under review. '
            'This usually takes 1-2 business days.',
      );
    }

    if (_verifiedStatus == 'verified') {
      return _StatusMessage(
        icon: Icons.verified,
        color: AppColors.primary,
        title: AppLocalizations.t('verified_seller'),
        message: 'Your account is verified. You now have the blue checkmark badge.',
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_verifiedStatus == 'rejected')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your previous verification was rejected. Please review your details and submit again.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppLocalizations.t('get_blue_checkmark'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(AppLocalizations.t('personal_details'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fullNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: AppLocalizations.t('full_name')),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nicNumberCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: AppLocalizations.t('nic_number')),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: AppLocalizations.t('address_field')),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: AppLocalizations.t('province')),
            items: _provinceDistricts.keys
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedProvince = v;
              _selectedDistrict = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: AppLocalizations.t('district')),
            items: (_selectedProvince != null ? _provinceDistricts[_selectedProvince]! : <String>[])
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: _selectedProvince == null ? null : (v) => setState(() => _selectedDistrict = v),
          ),

          const SizedBox(height: 24),
          Text(AppLocalizations.t('select_document_type'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DocTypeOption(
                  label: 'NIC',
                  selected: _selectedDocType == 'nic',
                  onTap: () => setState(() {
                    _selectedDocType = 'nic';
                    _backImage = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DocTypeOption(
                  label: AppLocalizations.t('driving_license'),
                  selected: _selectedDocType == 'driving_license',
                  onTap: () => setState(() {
                    _selectedDocType = 'driving_license';
                    _backImage = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DocTypeOption(
                  label: AppLocalizations.t('passport'),
                  selected: _selectedDocType == 'passport',
                  onTap: () => setState(() {
                    _selectedDocType = 'passport';
                    _backImage = null;
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(_frontLabelFor(_selectedDocType),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          const SizedBox(height: 8),
          _UploadBox(
            image: _frontImage,
            icon: Icons.badge_outlined,
            label: 'Tap to take a photo',
            onTap: () => _pickImage('front'),
          ),

          if (_selectedDocType == 'nic') ...[
            const SizedBox(height: 24),
            const Text('2. Back of NIC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            const SizedBox(height: 8),
            _UploadBox(
              image: _backImage,
              icon: Icons.badge_outlined,
              label: 'Tap to take a photo',
              onTap: () => _pickImage('back'),
            ),
          ],

          const SizedBox(height: 24),
          Text(AppLocalizations.t('take_selfie'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          const SizedBox(height: 4),
          Text(AppLocalizations.t('live_selfie_notice'), style: const TextStyle(color: AppColors.hint, fontSize: 11)),
          const SizedBox(height: 8),
          _UploadBox(
            image: _selfieImage,
            icon: Icons.camera_alt_outlined,
            label: 'Tap to take a live selfie',
            onTap: () => _pickImage('selfie'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(AppLocalizations.t('submit_for_review'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _frontLabelFor(String docType) {
    switch (docType) {
      case 'nic': return '1. Front of NIC';
      case 'driving_license': return '1. Front of Driving License';
      case 'passport': return '1. Passport Photo Page';
      default: return '1. Front of Document';
    }
  }

  String _docTypeLabel(String? docType) {
    switch (docType) {
      case 'driving_license': return 'driving license';
      case 'passport': return 'passport';
      default: return 'NIC';
    }
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusMessage({required this.icon, required this.color, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 64),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.hint, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _DocTypeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DocTypeOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : AppColors.hint, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final File? image;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadBox({required this.image, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.fieldFill, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: AppColors.hint),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: AppColors.hint, fontSize: 13)),
                ],
              ),
      ),
    );
  }
}
