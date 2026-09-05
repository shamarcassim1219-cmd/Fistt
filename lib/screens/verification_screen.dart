import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../main.dart';
import '../services/cloudinary_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  File? _nicImage;
  File? _selfieImage;
  bool _submitting = false;
  String? _error;

  Future<void> _pickImage(bool isNic) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: isNic ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      if (isNic) {
        _nicImage = File(picked.path);
      } else {
        _selfieImage = File(picked.path);
      }
    });
  }

  Future<void> _submit() async {
    if (_nicImage == null || _selfieImage == null) {
      setState(() => _error = 'Please upload both your NIC and a selfie');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final nicUrl = await CloudinaryService.uploadImage(
        _nicImage!,
        folder: 'verifications/$uid',
      );
      final selfieUrl = await CloudinaryService.uploadImage(
        _selfieImage!,
        folder: 'verifications/$uid',
      );

      await FirebaseFirestore.instance.collection('verifications').doc(uid).set({
        'nicImageUrl': nicUrl,
        'selfieImageUrl': selfieUrl,
        'feePaid': false,
        'status': 'pending',
        'reviewedBy': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'verifiedStatus': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted — pending admin review')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Submission failed: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Get Verified')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Get the Blue Checkmark',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        SizedBox(height: 4),
                        Text(
                          'One-time fee: LKR 150. Verified sellers get more trust and higher sales.',
                          style: TextStyle(fontSize: 12, color: AppColors.hint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const _StepLabel('1. Upload your NIC (front side)'),
            const SizedBox(height: 8),
            _UploadBox(
              image: _nicImage,
              icon: Icons.badge_outlined,
              label: 'Tap to upload NIC photo',
              onTap: () => _pickImage(true),
            ),

            const SizedBox(height: 24),
            const _StepLabel('2. Take a selfie'),
            const SizedBox(height: 8),
            _UploadBox(
              image: _selfieImage,
              icon: Icons.camera_alt_outlined,
              label: 'Tap to take a selfie',
              onTap: () => _pickImage(false),
            ),

            const SizedBox(height: 24),
            const _StepLabel('3. Pay LKR 150 Verification Fee'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Payment is confirmed by admin after reviewing your bank transfer slip, '
                'or automatically once a payment gateway is connected. Your badge appears '
                'in Settings once approved.',
                style: TextStyle(fontSize: 12, color: AppColors.hint),
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
                    : const Text('Submit for Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white));
  }
}

class _UploadBox extends StatelessWidget {
  final File? image;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadBox({
    required this.image,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
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
