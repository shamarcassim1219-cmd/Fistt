import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../services/api_service.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedGame = 'PUBG';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _uidCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final _vaultEmailCtrl = TextEditingController();
  final _vaultPasswordCtrl = TextEditingController();
  final _vaultRecoveryCtrl = TextEditingController();

  final List<File> _screenshots = [];
  bool _submitting = false;
  bool _allowBidding = false;
  String? _error;

  bool _loadingVerification = true;
  String _verifiedStatus = 'not_verified';

  final List<String> _games = ['PUBG', 'Free Fire', 'CODM', 'MLBB'];

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _verifiedStatus = profile['verifiedStatus'] ?? 'not_verified';
        _loadingVerification = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingVerification = false);
    }
  }

  Future<void> _pickScreenshots() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _screenshots.addAll(picked.map((x) => File(x.path)));
        if (_screenshots.length > 6) {
          _screenshots.removeRange(6, _screenshots.length);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  Future<List<String>> _uploadScreenshots() async {
    final urls = <String>[];
    for (final file in _screenshots) {
      final url = await ApiService.uploadImage(file);
      urls.add(url);
    }
    return urls;
  }

  Future<void> _resetForm() async {
    _titleCtrl.clear();
    _descCtrl.clear();
    _uidCtrl.clear();
    _priceCtrl.clear();
    _vaultEmailCtrl.clear();
    _vaultPasswordCtrl.clear();
    _vaultRecoveryCtrl.clear();
    if (mounted) {
      setState(() {
        _screenshots.clear();
        _allowBidding = false;
        _selectedGame = 'PUBG';
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_screenshots.isEmpty) {
      setState(() => _error = 'Add at least one screenshot');
      return;
    }
    if (_vaultEmailCtrl.text.trim().isEmpty || _vaultPasswordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Account email & password are required for the vault');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final screenshotUrls = await _uploadScreenshots();

      await ApiService.createListing(
        game: _selectedGame,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        inGameUID: _uidCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        screenshots: screenshotUrls,
        vaultEmail: _vaultEmailCtrl.text.trim(),
        vaultPassword: _vaultPasswordCtrl.text.trim(),
        vaultRecoveryCodes: _vaultRecoveryCtrl.text.trim(),
        allowBidding: _allowBidding,
      );

      if (!mounted) return;

      await _resetForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing posted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingVerification) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_verifiedStatus != 'verified') {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Sell an Account')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_outlined, color: AppColors.hint, size: 64),
                const SizedBox(height: 20),
                const Text('Verification Required', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  _verifiedStatus == 'pending'
                      ? 'Your verification is under review. You can post listings once approved.'
                      : 'Only verified sellers can post listings. Go to Settings to get verified.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.hint, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Sell an Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionLabel('Game'),
              Wrap(
                spacing: 8,
                children: _games.map((g) {
                  final selected = g == _selectedGame;
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedGame = g),
                    backgroundColor: AppColors.fieldFill,
                    selectedColor: AppColors.primary.withOpacity(0.3),
                    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.hint),
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const _SectionLabel('Listing Details'),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Title', hint
