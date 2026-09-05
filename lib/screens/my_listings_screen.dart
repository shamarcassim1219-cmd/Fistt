import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('My Listings')),
      body: uid == null
          ? const Center(child: Text('Please log in', style: TextStyle(color: AppColors.hint)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('sellerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No listings yet.\nTap "Sell" to post your first account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.hint),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'active';
                    final screenshots = (data['screenshots'] as List?) ?? [];
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
                              : Container(
                                  width: 56, height: 56,
                                  color: AppColors.fieldFill,
                                  child: const Icon(Icons.image_outlined, color: AppColors.hint),
                                ),
                        ),
                        title: Text(data['title'] ?? '', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${data['game'] ?? ''} · LKR ${data['price'] ?? 0}',
                            style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                        trailing: _StatusChip(status: status),
                      ),
                    );
                  },
                );
              },
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
