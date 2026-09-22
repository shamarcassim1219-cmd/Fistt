import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../widgets/rental_info_card.dart';
import 'sale_detail_screen.dart';

class MySalesScreen extends StatefulWidget {
  const MySalesScreen({super.key});

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> {
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
      final orders = await ApiService.getMySales();
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
          appBar: AppBar(title: Text(AppLocalizations.t('my_sales'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                  : _orders.isEmpty
                      ? Center(child: Text(AppLocalizations.t('no_sales_yet'), style: const TextStyle(color: AppColors.hint)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _orders.length,
                            itemBuilder: (context, i) {
                              final o = _orders[i];
                              final status = o['status'];
                              final rental = o['rental'] as Map<String, dynamic>?;
                              final installment = o['installment'] as Map<String, dynamic>?;
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
                                          MaterialPageRoute(builder: (_) => SaleDetailScreen(order: Map<String, dynamic>.from(o))),
                                        );
                                        _load();
                                      },
                                      title: Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Sale: LKR ${(o['price'] as num).toStringAsFixed(2)} · You get: LKR ${(o['sellerPayout'] as num).toStringAsFixed(2)}',
                                            style: const TextStyle(color: AppColors.hint, fontSize: 12),
                                          ),
                                          if ((rental != null || installment != null) && o['createdAt'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                'Given on: ${DateTime.parse(o['createdAt']).toLocal().toString().substring(0, 16)}',
                                                style: const TextStyle(color: AppColors.hint, fontSize: 11),
                                              ),
                                            ),
                                        ],
                                      ),
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
                                          color: AppColors.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${AppLocalizations.t('installments_colon')} LKR ${(installment['paidAmount'] as num).toStringAsFixed(2)} ${AppLocalizations.t('paid_of')} LKR ${(installment['totalAmount'] as num).toStringAsFixed(2)} · LKR ${(installment['remainingAmount'] as num).toStringAsFixed(2)} ${AppLocalizations.t('remaining_suffix')}",
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
      'completed': (AppLocalizations.t('paid_out'), Colors.greenAccent),
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
