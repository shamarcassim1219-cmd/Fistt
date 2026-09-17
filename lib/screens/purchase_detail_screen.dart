import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/secure_screen_mixin.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import 'vault_reveal_screen.dart';
import 'admin_chat_screen.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const PurchaseDetailScreen({super.key, required this.order});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> with SecureScreenMixin {
  late Map<String, dynamic> _order;
  bool _notifying = false;
  List<dynamic>? _installments;
  bool _loadingInstallments = false;
  int? _payingId;

  Future<void> _loadInstallments() async {
    setState(() => _loadingInstallments = true);
    try {
      final data = await ApiService.getInstallments(_order['id']);
      if (!mounted) return;
      setState(() {
        _installments = data['payments'];
        _loadingInstallments = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingInstallments = false);
    }
  }

  Future<void> _payInstallment(int paymentId) async {
    setState(() => _payingId = paymentId);
    try {
      await ApiService.payInstallment(paymentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Installment paid successfully')),
      );
      await _loadInstallments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _payingId = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order['installment'] != null) _loadInstallments();
  }

  bool get _deadlinePassed {
    final deadlineStr = _order['adminReviewDeadline'];
    if (deadlineStr == null || _order['adminReviewed'] == true) return false;
    final deadline = DateTime.parse(deadlineStr).toLocal();
    return DateTime.now().isAfter(deadline);
  }

  bool get _withinDisputeWindow {
    final createdStr = _order['createdAt'];
    if (createdStr == null) return true;
    final createdAt = DateTime.parse(createdStr).toLocal();
    final deadline = createdAt.add(const Duration(hours: 24));
    return DateTime.now().isBefore(deadline);
  }

  Future<void> _notifyAdmin() async {
    setState(() => _notifying = true);
    try {
      await ApiService.notifyAdminOverdue(_order['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin has been notified')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _notifying = false);
    }
  }

  void _showDisputeDialog() {
    final reasonCtrl = TextEditingController();
    bool sending = false;
    XFile? pickedPhoto;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(AppLocalizations.t('raise_dispute'), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: reasonCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Describe the issue with this account...'),
                ),
                const SizedBox(height: 12),
                if (pickedPhoto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(pickedPhoto!.path), height: 120, fit: BoxFit.cover, width: double.infinity),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (picked != null) {
                      setDialogState(() => pickedPhoto = picked);
                    }
                  },
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: Text(pickedPhoto == null ? AppLocalizations.t('attach_photo_optional') : AppLocalizations.t('change_photo')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'))),
            ElevatedButton(
              onPressed: sending ? null : () async {
                if (reasonCtrl.text.trim().isEmpty) return;
                setDialogState(() => sending = true);
                try {
                  String? photoUrl;
                  if (pickedPhoto != null) {
                    photoUrl = await ApiService.uploadImage(pickedPhoto!);
                  }
                  await ApiService.raiseDispute(_order['id'], reasonCtrl.text.trim(), photoUrl: photoUrl);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute raised — admin will review')));
                  setState(() => _order['status'] = 'disputed');
                } catch (e) {
                  setDialogState(() => sending = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              },
              child: sending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(AppLocalizations.t('submit')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        final screenshots = (_order['screenshots'] as List?) ?? [];
        final status = _order['status'];
        final adminReviewed = _order['adminReviewed'] == true;
        final canViewVault = status != 'disputed' && adminReviewed;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text('${AppLocalizations.t('my_purchases')} Details')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (screenshots.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: PageView(
                    children: screenshots.map<Widget>((url) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                        )).toList(),
                  ),
                ),
              const SizedBox(height: 16),
              Text(_order['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Chip(
                label: Text(_order['game'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: AppColors.fieldFill,
                side: const BorderSide(color: AppColors.border),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(AppLocalizations.t('order_id'), '#${_order['id']}'),
                    _row(AppLocalizations.t('amount_paid'), 'LKR ${(_order['price'] as num).toStringAsFixed(2)}'),
                    _row(AppLocalizations.t('status'), _statusLabel(status)),
                    if (_order['createdAt'] != null)
                      _row(AppLocalizations.t('purchased_on'), DateTime.parse(_order['createdAt']).toLocal().toString().substring(0, 16)),
                  ],
                ),
              ),
              if (_order['installment'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.t('installment_schedule'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),
                      if (_loadingInstallments)
                        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary)))
                      else if (_installments == null || _installments!.isEmpty)
                        Text(AppLocalizations.t('no_installment_data'), style: const TextStyle(color: AppColors.hint, fontSize: 12))
                      else
                        ..._installments!.map((p) {
                          final isPaid = p['status'] == 'paid';
                          final isOverdue = p['status'] == 'overdue';
                          final amount = (p['amount'] as num).toStringAsFixed(2);
                          String dateLabel = '';
                          try {
                            final d = DateTime.parse(p['dueDate'] ?? p['due_date']).toLocal();
                            dateLabel = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                          } catch (_) {}
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  isPaid ? Icons.check_circle : (isOverdue ? Icons.error_outline : Icons.schedule),
                                  color: isPaid ? Colors.greenAccent : (isOverdue ? Colors.redAccent : Colors.orangeAccent),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${AppLocalizations.t('installment_hash')}${p['installmentNumber'] ?? p['installment_number']} — LKR $amount${dateLabel.isNotEmpty ? ' · $dateLabel' : ''}",
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                if (!isPaid)
                                  SizedBox(
                                    height: 32,
                                    child: !adminReviewed
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4),
                                            child: Text('Awaiting admin approval', style: TextStyle(color: AppColors.hint, fontSize: 11)),
                                          )
                                        : ElevatedButton(
                                            onPressed: _payingId == p['id'] ? null : () => _payInstallment(p['id']),
                                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                                            child: _payingId == p['id']
                                                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                                : Text(AppLocalizations.t('pay_now'), style: const TextStyle(fontSize: 12)),
                                          ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],


              if (!adminReviewed && status != 'disputed') ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hourglass_top_outlined, color: Colors.orangeAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.t('admin_verifying'), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(AppLocalizations.t('admin_notify_message'), style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                      if (_deadlinePassed) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _notifying ? null : _notifyAdmin,
                            icon: _notifying
                                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.notifications_active_outlined, size: 16, color: Colors.orangeAccent),
                            label: Text(AppLocalizations.t('notify_admin_overdue'), style: const TextStyle(color: Colors.orangeAccent)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(orderId: _order['id'])));
                  },
                  icon: const Icon(Icons.support_agent_outlined),
                  label: Text(AppLocalizations.t('chat_with_admin')),
                ),
              ),

              if (canViewVault) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => VaultRevealScreen(orderId: _order['id'])));
                    },
                    icon: const Icon(Icons.lock_open_outlined),
                    label: Text(AppLocalizations.t('view_credentials')),
                  ),
                ),
              ],

              if (status == 'escrow_held' && _withinDisputeWindow) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _showDisputeDialog,
                    icon: const Icon(Icons.report_problem_outlined, color: Colors.orangeAccent),
                    label: Text(AppLocalizations.t('raise_dispute'), style: const TextStyle(color: Colors.orangeAccent)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
                  ),
                ),
              ] else if (status == 'disputed')
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
                  child: Text(AppLocalizations.t('dispute_under_review'), style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    final map = {
      'escrow_held': AppLocalizations.t('in_escrow'),
      'completed': AppLocalizations.t('completed'),
      'disputed': AppLocalizations.t('disputed'),
      'refunded': AppLocalizations.t('refunded'),
    };
    return map[status] ?? status;
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.hint, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
