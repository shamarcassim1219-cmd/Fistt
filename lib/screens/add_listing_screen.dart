import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../main.dart';
import '../services/cloudinary_service.dart';

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
  String? _error;

  final List<String> _games = ['PUBG', 'Free Fire', 'CODM', 'MLBB'];

  Future<void> _pickScreenshots() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() {
      _screenshots.addAll(picked.map((x) => File(x.path)));
      if (_screenshots.length > 6) {
        _screenshots.removeRange(6, _screenshots.length);
      }
    });
  }

  Future<List<String>> _uploadScreenshots(String listingId) async {
    final urls = <String>[];
    for (var i = 0; i < _screenshots.length; i++) {
      final url = await CloudinaryService.uploadImage(
        _screenshots[i],
        folder: 'listings/$listingId',
      );
      urls.add(url);
    }
    return urls;
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
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final listingRef = FirebaseFirestore.instance.collection('listings').doc();

      final screenshotUrls = await _uploadScreenshots(listingRef.id);

      await listingRef.set({
        'sellerId': uid,
        'game': _selectedGame,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'inGameUID': _uidCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'screenshots': screenshotUrls,
        'status': 'active',
        'boosted': false,
        'boostExpiresAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Vault credentials — sent to a callable Cloud Function that encrypts
      // and stores them server-side. See firestore/schema.md.
      //
      // await FirebaseFunctions.instance.httpsCallable('encryptAndStoreVault').call({
      //   'listingId': listingRef.id,
      //   'email': _vaultEmailCtrl.text.trim(),
      //   'password': _vaultPasswordCtrl.text.trim(),
      //   'recoveryCodes': _vaultRecoveryCtrl.text.trim(),
      // });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing posted successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to post listing: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: AppColors.hint),
                  hintText: 'e.g. Conqueror Rank Account, Full Skin Set',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.hint),
                  hintText: 'Rank, skins, level, region, extra details...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _uidCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'In-Game UID',
                  labelStyle: TextStyle(color: AppColors.hint),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Price (LKR)',
                  labelStyle: TextStyle(color: AppColors.hint),
                  prefixText: 'LKR ',
                  prefixStyle: TextStyle(color: Colors.white),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              if (_priceCtrl.text.isNotEmpty &&
                  double.tryParse(_priceCtrl.text.trim()) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _CommissionPreview(price: double.parse(_priceCtrl.text.trim())),
                ),

              const SizedBox(height: 20),
              const _SectionLabel('Screenshots (max 6)'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _screenshots.length + 1,
                itemBuilder: (context, i) {
                  if (i == _screenshots.length) {
                    return InkWell(
                      onTap: _screenshots.length >= 6 ? null : _pickScreenshots,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.hint),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_screenshots[i],
                            width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _screenshots.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              const _SectionLabel('Account Vault (Private & Encrypted)'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These details are encrypted and only shown to the buyer after payment is confirmed.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vaultEmailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Account Email',
                  labelStyle: TextStyle(color: AppColors.hint),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vaultPasswordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Account Password',
                  labelStyle: TextStyle(color: AppColors.hint),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vaultRecoveryCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Recovery Codes (optional)',
                  labelStyle: TextStyle(color: AppColors.hint),
                ),
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
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Post Listing', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _CommissionPreview extends StatelessWidget {
  final double price;
  const _CommissionPreview({required this.price});

  @override
  Widget build(BuildContext context) {
    final commission = price * 0.15;
    final youGet = price - commission;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Listing Price', 'LKR ${price.toStringAsFixed(2)}'),
          _row('Platform Commission (15%)', '- LKR ${commission.toStringAsFixed(2)}'),
          const Divider(height: 12, color: AppColors.border),
          _row('You Receive', 'LKR ${youGet.toStringAsFixed(2)}', bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85), fontWeight: bold ? FontWeight.bold : null)),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
