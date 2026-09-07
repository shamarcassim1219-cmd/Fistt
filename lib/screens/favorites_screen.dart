import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'listing_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
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
      final listings = await ApiService.getFavorites();
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

  Future<void> _removeFavorite(int listingId) async {
    try {
      await ApiService.removeFavorite(listingId);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Saved Accounts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _listings.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No saved accounts yet.\nTap the heart icon on a listing to save it here.',
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
                          final screenshots = (l['screenshots'] as List?) ?? [];
                          final allowBidding = l['allowBidding'] == true;
                          final highestBid = l['highestBid'] != null ? (l['highestBid'] as num).toDouble() : null;
                          final displayPrice = highestBid ?? (l['price'] as num).toDouble();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: l['id'])),
                                ).then((_) => _load());
                              },
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: screenshots.isNotEmpty
                                    ? Image.network(screenshots[0], width: 56, height: 56, fit: BoxFit.cover)
                                    : Container(width: 56, height: 56, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                              ),
                              title: Row(
                                children: [
                                  Flexible(child: Text(l['title'] ?? '', style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                                  if (l['sellerVerified'] == true) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, size: 14, color: AppColors.primary),
                                  ],
                                ],
                              ),
                              subtitle: Text('${l['game'] ?? ''} · LKR ${displayPrice.toStringAsFixed(0)}${allowBidding ? ' (bidding)' : ''}',
                                  style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                                onPressed: () => _removeFavorite(l['id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
