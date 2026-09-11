import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

const List<String> kReportReasons = [
  'Scam',
  'Fake Listing',
  'Inappropriate Content',
  'Harassment',
  'Other',
];

Future<void> showReportDialog(BuildContext context, {required String targetType, required int targetId}) async {
  String selectedReason = kReportReasons[0];
  final detailsCtrl = TextEditingController();
  bool submitting = false;
  String? error;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Report ${targetType == 'listing' ? 'Listing' : 'User'}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason', style: TextStyle(color: AppColors.hint, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedReason,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(isDense: true),
              items: kReportReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setDialogState(() => selectedReason = v ?? kReportReasons[0]),
            ),
            const SizedBox(height: 14),
            const Text('Details (optional)', style: TextStyle(color: AppColors.hint, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: detailsCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Describe what happened...'),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: submitting
                ? null
                : () async {
                    setDialogState(() => submitting = true);
                    try {
                      await ApiService.reportContent(targetType, targetId, selectedReason, detailsCtrl.text.trim().isEmpty ? null : detailsCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Our team will review it shortly.')));
                      }
                    } catch (e) {
                      setDialogState(() {
                        error = e.toString().replaceFirst('Exception: ', '');
                        submitting = false;
                      });
                    }
                  },
            child: submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Submit Report'),
          ),
        ],
      ),
    ),
  );
}
