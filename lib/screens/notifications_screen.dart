import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notifications = await ApiService.getNotifications();
      await ApiService.markAllNotificationsRead();
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'offer_received': return Icons.local_offer_outlined;
      case 'offer_accepted': return Icons.check_circle_outline;
      case 'offer_rejected': return Icons.cancel_outlined;
      case 'order_completed': return Icons.shopping_bag_outlined;
      case 'topup_confirmed': return Icons.add_circle_outline;
      case 'withdrawal_confirmed': return Icons.arrow_circle_up_outlined;
      case 'verification_approved': return Icons.verified_outlined;
      case 'verification_rejected': return Icons.error_outline;
      case 'new_message': return Icons.chat_bubble_outline;
      default: return Icons.notifications_outlined;
    }
  }

  String _timeAgo(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _notifications.isEmpty
                  ? const Center(child: Text('No notifications yet', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final n = _notifications[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Icon(_iconFor(n['type'] ?? ''), color: AppColors.primary, size: 20),
                            ),
                            title: Text(n['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(n['body'] ?? '', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                            trailing: Text(_timeAgo(n['createdAt']), style: const TextStyle(color: AppColors.hint, fontSize: 10)),
                          );
                        },
                      ),
                    ),
    );
  }
}
