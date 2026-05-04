import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifs = raw
              .map((e) =>
                  AppNotification.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;  
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    try {
      await ApiService.markNotificationRead(n.id);
      if (mounted) {
        setState(() {
          final idx = _notifs.indexWhere((x) => x.id == n.id);
          if (idx != -1) {
            _notifs[idx] = AppNotification(
              id: n.id,
              message: n.message,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No notifications yet',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifs.length,
                      itemBuilder: (_, i) {
                        final n = _notifs[i];
                        return Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.blue.shade100,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.mark_email_read,
                                color: Colors.blue),
                          ),
                          onDismissed: (_) => _markRead(n),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _typeColor(n.type).withOpacity(0.15),
                              child: Icon(_typeIcon(n.type),
                                  color: _typeColor(n.type), size: 20),
                            ),
                            title: Text(
                              n.message,
                              style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _formatDate(n.createdAt),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            trailing: n.isRead
                                ? null
                                : const CircleAvatar(
                                    radius: 5,
                                    backgroundColor: Color(0xFF0D47A1),
                                  ),
                            onTap: () => _markRead(n),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Color _typeColor(String type) => switch (type) {
        'approved' => Colors.green,
        'rejected' => Colors.red,
        _ => Colors.blue,
      };

  IconData _typeIcon(String type) => switch (type) {
        'approved' => Icons.check_circle_outline,
        'rejected' => Icons.cancel_outlined,
        _ => Icons.notifications_outlined,
      };

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
