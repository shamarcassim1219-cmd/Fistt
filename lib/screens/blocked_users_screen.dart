import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<dynamic> _blockedIds = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        _blockedIds = profile['blockedUsers'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _unblock(int userId) async {
    try {
      await ApiService.unblockUser(userId);
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
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('blocked_users'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                  : _blockedIds.isEmpty
                      ? Center(child: Text(AppLocalizations.t('no_blocked_users'), style: const TextStyle(color: AppColors.hint)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _blockedIds.length,
                          itemBuilder: (context, i) {
                            final userId = _blockedIds[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.fieldFill,
                                  child: Icon(Icons.person, color: AppColors.hint),
                                ),
                                title: Text('User #$userId', style: const TextStyle(color: Colors.white)),
                                trailing: OutlinedButton(
                                  onPressed: () => _unblock(userId),
                                  child: Text(AppLocalizations.t('unblock')),
                                ),
                              ),
                            );
                          },
                        ),
        );
      },
    );
  }
}
