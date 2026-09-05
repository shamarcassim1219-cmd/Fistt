import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('My Sales')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _orders.isEmpty
                  ? const Center(child: Text('No sales yet', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (context, i) {
                          final o = _orders[i];
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          Text('Sale price: LKR ${(o['price'] as num).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                          Text('You receive: LKR ${(o['sellerPayout'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    _StatusBadge(status: status),
                                  ],
                                ),
                                if (status == 'escrow_held' && o['escrowReleaseAt'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Releases: ${DateTime.parse(o['escrowReleaseAt']).toLocal().toString().substring(0, 16)}',
                                    style: const TextStyle(color: AppColors.hint, fontSize: 11),
                                  ),
                                ],
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
      'completed': ('Paid Out', Colors.greenAccent),
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
