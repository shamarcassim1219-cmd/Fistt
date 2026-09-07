import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'listing_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final int sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  Map<String, dynamic>? _seller;
  List<dynamic> _listings = [];
  bool _loading = true;
  String? _error;
  bool _blocking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getSellerProfile(widget.sellerId);
      setState(() {
        _seller = data['seller'];
        _listings = data['listings'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _confirmBlock() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Block User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Block ${_seller?['displayName'] ?? 'this user'}? You will no longer see their listings or receive messages from them.',
          style: const TextStyle(color: AppColors.hint, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _blocking = true);
              try {
                await ApiService.blockUser(widget.sellerId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked')));
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                setState(() => _blocking = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Seller Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.block_outlined),
            onPressed: _blocking ? null : _confirmBlock,
            tooltip: 'Block user',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        backgroundImage: _seller?['profilePhotoUrl'] != null ? NetworkImage(_seller!['profilePhotoUrl']) : null,
                        child: _seller?['profilePhotoUrl'] == null
                            ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_seller?['displayName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (_seller?['verifiedStatus'] == 'verified') ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppColors.primary, size: 18),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatBox(label: 'Listings', value: '${_listings.length}'),
                        _StatBox(label: 'Sold', value: '${_seller?['totalSold'] ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Active Listings', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (_listings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(child: Text('No active listings', style: TextStyle(color: AppColors.hint))),
                      )
                    else
                      ..._listings.map((l) {
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
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: l['id'])));
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: screenshots.isNotEmpty
                                  ? Image.network(screenshots[0], width: 56, height: 56, fit: BoxFit.cover)
                                  : Container(width: 56, height: 56, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                            ),
                            title: Text(l['title'] ?? '', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('${l['game'] ?? ''} · LKR ${displayPrice.toStringAsFixed(0)}${allowBidding ? ' (bidding)' : ''}',
                                style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
      ],
    );
  }
}
