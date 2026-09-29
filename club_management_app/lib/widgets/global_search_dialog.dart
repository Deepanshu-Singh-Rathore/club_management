import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/club.dart';
import '../screens/club_detail_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => const GlobalSearchDialog(),
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  Map<String, dynamic>? _results;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _loading = false;
        _results = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _loading = true);
      try {
        final data = await ApiService.globalSearch(query.trim());
        if (mounted) {
          setState(() {
            _results = data;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? (screenWidth - 650) / 2 : 16,
        vertical: 40,
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search clubs, events, announcements...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    )
                  else if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                      onPressed: () {
                        _controller.clear();
                        _onSearchChanged('');
                      },
                    ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ESC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Results Container
            Flexible(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_results == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search_rounded, size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text(
              'Quick Search',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Type club names, event titles, or campus announcements',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final clubs = (_results!['clubs'] as List?) ?? [];
    final events = (_results!['events'] as List?) ?? [];
    final announcements = (_results!['announcements'] as List?) ?? [];

    if (clubs.isEmpty && events.isEmpty && announcements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied_rounded, size: 40, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'No results found for "${_controller.text}"',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (clubs.isNotEmpty) ...[
          _sectionHeader('Clubs (${clubs.length})', Icons.groups_rounded),
          ...clubs.map((c) => _clubResultTile(c)),
          const SizedBox(height: 12),
        ],
        if (events.isNotEmpty) ...[
          _sectionHeader('Events (${events.length})', Icons.event_rounded),
          ...events.map((e) => _eventResultTile(e)),
          const SizedBox(height: 12),
        ],
        if (announcements.isNotEmpty) ...[
          _sectionHeader('Announcements (${announcements.length})', Icons.campaign_rounded),
          ...announcements.map((a) => _announcementResultTile(a)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clubResultTile(dynamic c) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.primaryTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        c['name'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        '${c['category'] ?? 'Club'} • ${c['member_count'] ?? 0} members',
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClubDetailScreen(
              club: Club(
                id: c['id'],
                name: c['name'],
                description: c['description'] ?? '',
                category: c['category'] ?? 'Technology',
                memberCount: c['member_count'] ?? 0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _eventResultTile(dynamic e) {
    DateTime? eventDate;
    if (e['event_date'] != null) {
      eventDate = DateTime.tryParse(e['event_date']);
    }
    final formattedDate = eventDate != null
        ? DateFormat('MMM d, h:mm a').format(eventDate.toLocal())
        : 'Upcoming';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.secondaryTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.event_available_rounded, color: AppTheme.secondary, size: 20),
      ),
      title: Text(
        e['title'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        '${e['club_name'] ?? 'Club'} • $formattedDate • ${e['venue'] ?? 'Campus'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/event-detail', arguments: e['id']);
      },
    );
  }

  Widget _announcementResultTile(dynamic a) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.warningBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.campaign_rounded, color: AppTheme.warning, size: 20),
      ),
      title: Text(
        a['title'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        a['club_name'] ?? 'Campus Club',
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}
