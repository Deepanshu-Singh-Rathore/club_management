import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.getNotifications();

      final items = raw
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _notifs = raw
              .map((e) =>
                  AppNotification.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;  
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;

    final id = int.tryParse(n.id);
    if (id == null) return;

    try {
      await ApiService.markNotificationRead(id);

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
              eventId: n.eventId,
              clubId: n.clubId,
              registrationId: n.registrationId,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("MARK READ ERROR: $e");
    }
  }

  Future<void> _openEvent(AppNotification n) async {
    await _markRead(n);

    if (!mounted) return;

    if (n.eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event not available")),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/event-detail',
      arguments: n.eventId,
    );
  }

  Future<void> _approve(AppNotification n) async {
    if (n.eventId == null || n.registrationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration not available")),
      );
      return;
    }

    try {
      await ApiService.approveRegistration(
        n.eventId!,
        n.registrationId!,
      );

      await _markRead(n);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Application approved")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _reject(AppNotification n) async {
    if (n.eventId == null || n.registrationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration not available")),
      );
      return;
    }

    try {
      await ApiService.rejectRegistration(
        n.eventId!,
        n.registrationId!,
      );

      await _markRead(n);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Application rejected")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _notifs.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 250),
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No notifications yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _notifs.length,
                          itemBuilder: (_, i) {
                            final n = _notifs[i];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _typeColor(n.type).withOpacity(0.15),
                                      child: Icon(
                                        _typeIcon(n.type),
                                        color: _typeColor(n.type),
                                      ),
                                    ),
                                    title: Text(
                                      n.message,
                                      style: TextStyle(
                                        fontWeight: n.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(_formatDate(n.createdAt)),
                                    trailing: n.isRead
                                        ? null
                                        : const CircleAvatar(
                                            radius: 5,
                                            backgroundColor: Color(0xFF0D47A1),
                                          ),
                                    onTap: () {
                                      if (n.type == 'event') {
                                        _openEvent(n);
                                      } else {
                                        _markRead(n);
                                      }
                                    },
                                  ),

                                  // ✅ Admin apply notification buttons
                                  if (n.type == 'apply' &&
                                      n.registrationId != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _approve(n),
                                              child: const Text("Accept"),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _reject(n),
                                              child: const Text("Reject"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // ✅ Event notification button
                                  if (n.type == 'event' && n.eventId != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 12,
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _openEvent(n),
                                          child: const Text("Check it out"),
                                        ),
                                      ),
                                    ),
                                ],
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
        'event' => Colors.orange,
        'apply' => Colors.blue,
        _ => Colors.blue,
      };

  IconData _typeIcon(String type) => switch (type) {
        'approved' => Icons.check_circle_outline,
        'rejected' => Icons.cancel_outlined,
        'event' => Icons.event,
        'apply' => Icons.notifications_active_outlined,
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