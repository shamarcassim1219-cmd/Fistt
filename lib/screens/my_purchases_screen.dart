import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../widgets/rental_info_card.dart';
import 'purchase_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('my_purchases'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                  : _orders.isEmpty
                      ? Center(child: Text(AppLocalizations.t('no_purchases_yet'), style: const TextStyle(color: AppColors.hint)))
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
                              final installment = o['installment'] as Map<String, dynamic>?;
                              final rental = o['rental'] as Map<String, dynamic>?;
                              String? nextDueLabel;
                              if (installment != null && installment['nextDueDate'] != null) {
                                try {
                                  final due = DateTime.parse(installment['nextDueDate']).toLocal();
                                  final daysLeft = due.difference(DateTime.now()).inDays;
                                  nextDueLabel = daysLeft < 0
                                      ? AppLocalizations.t('overdue')
                                      : daysLeft == 0
                                          ? AppLocalizations.t('due_today')
                                          : "${AppLocalizations.t('due_in_prefix')} $daysLeft ${AppLocalizations.t('days_suffix')}";
                                } catch (_) {}
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => PurchaseDetailScreen(order: Map<String, dynamic>.from(o))),
                                        );
                                        _load();
                                      },
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: screenshots.isNotEmpty
                                            ? Image.network(screenshots[0], width: 50, height: 50, fit: BoxFit.cover)
                                            : Container(width: 50, height: 50, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                                      ),
                                      title: Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      subtitle: Text('LKR ${(o['price'] as num).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                      trailing: _StatusBadge(status: status),
                                    ),
                                    if (rental != null)
                                      RentalInfoCard(rental: rental, createdAt: o['createdAt']),
                                    if (installment != null)
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: (installment['overdueCount'] as num? ?? 0) > 0
                                              ? Colors.redAccent.withOpacity(0.1)
                                              : AppColors.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${AppLocalizations.t('remaining_colon')} LKR ${(installment['remainingAmount'] as num).toStringAsFixed(2)}",
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            if (nextDueLabel != null)
                                              Text(
                                                nextDueLabel,
                                                style: TextStyle(
                                                  color: (installment['overdueCount'] as num? ?? 0) > 0 ? Colors.redAccent : AppColors.primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'escrow_held': (AppLocalizations.t('in_escrow'), Colors.orangeAccent),
      'completed': (AppLocalizations.t('completed'), Colors.greenAccent),
      'disputed': (AppLocalizations.t('disputed'), Colors.redAccent),
      'refunded': (AppLocalizations.t('refunded'), AppColors.hint),
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
