import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Blocked Users')),
      body: uid == null
          ? const Center(child: Text('Please log in', style: TextStyle(color: AppColors.hint)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final blocked = (snapshot.data?.get('blockedUsers') as List?) ?? [];
                if (blocked.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "You haven't blocked anyone yet.",
                        style: TextStyle(color: AppColors.hint),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: blocked.length,
                  itemBuilder: (context, i) {
                    final blockedUid = blocked[i] as String;
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.fieldFill,
                        child: Icon(Icons.person, color: AppColors.hint),
                      ),
                      title: Text(blockedUid, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      trailing: TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('users').doc(uid).update({
                            'blockedUsers': FieldValue.arrayRemove([blockedUid]),
                          });
                        },
                        child: const Text('Unblock'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
