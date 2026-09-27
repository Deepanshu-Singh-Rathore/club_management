import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isEmbedded;
  const NotificationsScreen({super.key, this.isEmbedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifs = [];
  bool _loading = true;
  String? _error;
  String _selectedFilter = 'all';

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
      if (mounted) {
        setState(() {
          _notifs = raw
              .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
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

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      if (mounted) {
        setState(() {
          _notifs = _notifs.map((n) => AppNotification(
            id: n.id,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
            eventId: n.eventId,
            clubId: n.clubId,
            registrationId: n.registrationId,
          )).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("MARK ALL READ ERROR: $e");
    }
  }

  Future<void> _openEvent(AppNotification n) async {
    await _markRead(n);

    if (!mounted) return;

    if (n.eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Event details are not available"),
          behavior: SnackBarBehavior.floating,
        ),
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
        const SnackBar(
          content: Text("Registration not available"),
          behavior: SnackBarBehavior.floating,
        ),
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
        const SnackBar(
          content: Text("Application approved successfully"),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reject(AppNotification n) async {
    if (n.eventId == null || n.registrationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration not available"),
          behavior: SnackBarBehavior.floating,
        ),
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
        const SnackBar(
          content: Text("Application rejected"),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _cleanMessage(String msg) {
    return msg.replaceAll(RegExp(r'\s*\(\+\d+\s*pts\)', caseSensitive: false), '').trim();
  }

  List<AppNotification> get _filteredNotifs {
    switch (_selectedFilter) {
      case 'unread':
        return _notifs.where((n) => !n.isRead).toList();
      case 'approved':
        return _notifs.where((n) => n.type == 'approved').toList();
      case 'event':
        return _notifs.where((n) => n.type == 'event').toList();
      case 'apply':
        return _notifs.where((n) => n.type == 'apply').toList();
      default:
        return _notifs;
    }
  }

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final bodyContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppTheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primary,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      children: [
                        // Control Header Bar
                        _buildControlBar(),
                        const SizedBox(height: 16),

                        if (_filteredNotifs.isEmpty)
                          _buildEmptyState()
                        else
                          ..._filteredNotifs.map((n) => _buildNotificationCard(n)),
                      ],
                    ),
                  ),
      ),
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _filterChip('all', 'All (${_notifs.length})'),
              _filterChip('unread', 'Unread ($_unreadCount)'),
              _filterChip('approved', 'Approvals'),
              _filterChip('event', 'Events'),
            ],
          ),
          if (_unreadCount > 0)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _markAllAsRead,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done_all_rounded, size: 16, color: AppTheme.primary),
                    SizedBox(width: 6),
                    Text(
                      'Mark all as read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Updates on your club applications, approved events, and announcements will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification n) {
    final iconColor = _typeColor(n.type);
    final iconBg = _typeBg(n.type);

    return EntranceAnimation(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: n.isRead ? AppTheme.surface : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead
                ? AppTheme.border
                : AppTheme.primary.withValues(alpha: 0.35),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: n.isRead ? AppTheme.softShadow : AppTheme.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (n.eventId != null) {
                _openEvent(n);
              } else {
                _markRead(n);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _typeIcon(n.type),
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _typeLabel(n.type),
                                    style: TextStyle(
                                      color: iconColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(n.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _cleanMessage(n.message),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                color: AppTheme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Action: Application approval by club head/admin
                  if (n.type == 'apply' && n.registrationId != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text(
                              'Approve Registration',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => _approve(n),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text(
                              'Decline',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => _reject(n),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Action: View approved or scheduled event
                  if ((n.type == 'event' || n.type == 'approved') && n.eventId != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openEvent(n),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text(
                          n.type == 'approved' ? 'View Event Registration' : 'View Event Details',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
        'approved' => AppTheme.success,
        'rejected' => AppTheme.error,
        'event' => const Color(0xFFD97706),
        'apply' => AppTheme.primary,
        _ => AppTheme.primary,
      };

  Color _typeBg(String type) => switch (type) {
        'approved' => AppTheme.successBg,
        'rejected' => AppTheme.errorBg,
        'event' => const Color(0xFFFEF3C7),
        'apply' => AppTheme.primaryTint,
        _ => AppTheme.primaryTint,
      };

  IconData _typeIcon(String type) => switch (type) {
        'approved' => Icons.verified_rounded,
        'rejected' => Icons.cancel_rounded,
        'event' => Icons.event_available_rounded,
        'apply' => Icons.assignment_ind_rounded,
        _ => Icons.notifications_rounded,
      };

  String _typeLabel(String type) => switch (type) {
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        'event' => 'Upcoming Event',
        'apply' => 'Application',
        _ => 'Notice',
      };

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year}';
  }
}