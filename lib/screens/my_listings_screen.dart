import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<dynamic> _listings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final listings = await ApiService.getMyListings();
      setState(() {
        _listings = listings;
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
      appBar: AppBar(title: const Text('My Listings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _listings.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No listings yet.\nTap "Sell" to post your first account.',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _listings.length,
                        itemBuilder: (context, i) {
                          final l = _listings[i];
                          final status = l['status'] ?? 'active';
                          final screenshots = (l['screenshots'] as List?) ?? [];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: screenshots.isNotEmpty
                                    ? Image.network(screenshots[0], width: 56, height: 56, fit: BoxFit.cover)
                                    : Container(width: 56, height: 56, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                              ),
                              title: Text(l['title'] ?? '', style: const TextStyle(color: Colors.white)),
                              subtitle: Text('${l['game'] ?? ''} · LKR ${l['price'] ?? 0}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                              trailing: _StatusChip(status: status),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'active': ('Active', Colors.greenAccent),
      'pending_escrow': ('Pending', Colors.orangeAccent),
      'sold': ('Sold', AppColors.primary),
      'expired': ('Expired', AppColors.hint),
    };
    final (label, color) = map[status] ?? ('Unknown', AppColors.hint);
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
