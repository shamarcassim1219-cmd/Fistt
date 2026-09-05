import 'package:flutter/material.dart';
import '../main.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Blocked Users')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text("You haven't blocked anyone yet.", style: TextStyle(color: AppColors.hint)),
        ),
      ),
    );
  }
}
