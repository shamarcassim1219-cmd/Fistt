import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'vault_reveal_screen.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key});

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await ApiService.getMyPurchases();
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _showDisputeDialog(int orderId) {
    final reasonCtrl = TextEditingController();
    bool sending = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Raise a Dispute', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: reasonCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Describe the issue with this account...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: sending ? null : () async {
                if (reasonCtrl.text.trim().isEmpty) return;
                setDialogState(() => sending = true);
                try {
                  await ApiService.raiseDispute(orderId, reasonCtrl.text.trim());
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute raised — admin will review')));
                  _load();
                } catch (e) {
                  setDialogState(() => sending = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              },
              child: sending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('My Purchases')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _orders.isEmpty
                  ? const Center(child: Text('No purchases yet', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (context, i) {
                          final o = _orders[i];
                          final screenshots = (o['screenshots'] as List?) ?? [];
                          final status = o['status'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: screenshots.isNotEmpty
                                          ? Image.network(screenshots[0], width: 50, height: 50, fit: BoxFit.cover)
                                          : Container(width: 50, height: 50, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          Text('LKR ${(o['price'] as num).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    _StatusBadge(status: status),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (status == 'completed')
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => VaultRevealScreen(orderId: o['id'])));
                                      },
                                      icon: const Icon(Icons.lock_open_outlined, size: 16),
                                      label: const Text('View Account Credentials'),
                                    ),
                                  )
                                else if (status == 'escrow_held')
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showDisputeDialog(o['id']),
                                      icon: const Icon(Icons.report_problem_outlined, size: 16, color: Colors.orangeAccent),
                                      label: const Text('Raise a Dispute', style: TextStyle(color: Colors.orangeAccent)),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
                                    ),
                                  )
                                else if (status == 'disputed')
                                  const Text('Dispute under admin review', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'escrow_held': ('In Escrow', Colors.orangeAccent),
      'completed': ('Completed', Colors.greenAccent),
      'disputed': ('Disputed', Colors.redAccent),
      'refunded': ('Refunded', AppColors.hint),
    };
    final (label, color) = map[status] ?? (status, AppColors.hint);
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 10, color: color)),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
