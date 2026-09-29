import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';
import '../widgets/event_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'clubhead/pending_approvals_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> _events = [];
  bool _loading = true;
  String _filter = 'upcoming'; // upcoming | completed | all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getEvents();
      if (mounted) {
        setState(() {
          _events = raw
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Event> get _visible {
    final sorted = [..._events];
    sorted.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    if (_filter == 'all') return sorted;
    return sorted.where((e) => e.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            children: [
              // Filter Chips Row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    _filterChip('upcoming', 'Upcoming Events'),
                    const SizedBox(width: 8),
                    _filterChip('completed', 'Past Events'),
                    const SizedBox(width: 8),
                    _filterChip('all', 'All Activities'),
                    const Spacer(),
                    Text(
                      '${_visible.length} ${_visible.length == 1 ? 'Event' : 'Events'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Events Grid
              Expanded(
                child: _loading
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final count = isDesktop ? 2 : 1;
                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isDesktop ? 1.7 : 1.35,
                            ),
                            itemCount: 4,
                            itemBuilder: (_, __) => const EventCardSkeleton(),
                          );
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppTheme.primary,
                        child: _visible.isEmpty
                            ? EmptyState(
                                icon: Icons.event_busy_rounded,
                                title: 'No $_filter events found',
                                subtitle: _filter == 'upcoming'
                                    ? 'Nothing planned yet. Check back soon for new campus events.'
                                    : 'No events have been recorded in this category yet.',
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final count = isDesktop ? 2 : 1;

                                  return GridView.builder(
                                    padding: const EdgeInsets.all(24),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: count,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: isDesktop ? 1.7 : 1.35,
                                    ),
                                    itemCount: _visible.length,
                                    itemBuilder: (_, i) {
                                      final ev = _visible[i];
                                      return EntranceAnimation(
                                        delayMs: (i * 30).clamp(0, 300),
                                        child: EventCard(
                                          event: ev,
                                          onTap: () => _openEvent(ev),
                                          onManage: (auth.isAdmin || auth.isClubHead)
                                              ? () => _openManage(ev)
                                              : null,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String filter, String label) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = filter),
      selectedColor: AppTheme.primaryTint,
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _openEvent(Event event) {
    Navigator.pushNamed(context, '/event-detail', arguments: event.id);
  }

  void _openManage(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PendingApprovalsScreen(event: event),
      ),
    );
  }
}