import 'dart:async';
import 'package:flutter/material.dart';
import '../models/club.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';
import '../widgets/club_card.dart';
import '../widgets/event_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import 'club_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _selectedCategory = 'All';
  String _selectedSort = 'popular';
  int _activeTab = 0; // 0: Clubs, 1: Events

  List<Club> _clubs = [];
  List<Event> _events = [];
  bool _loadingClubs = true;
  bool _loadingEvents = true;

  final List<String> _categories = [
    'All',
    'Technology',
    'Cultural',
    'Sports',
    'Photography',
    'Music',
    'Literature',
    'Entrepreneurship',
    'Social',
    'Academic',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingClubs = true;
      _loadingEvents = true;
    });

    final query = _searchCtrl.text.trim();

    try {
      final rawClubs = await ApiService.getClubs(
        category: _selectedCategory != 'All' ? _selectedCategory : null,
        search: query.isNotEmpty ? query : null,
        sort: _selectedSort,
      );
      if (mounted) {
        setState(() {
          _clubs = rawClubs.map((c) => Club.fromJson(c as Map<String, dynamic>)).toList();
          _loadingClubs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClubs = false);
    }

    try {
      final rawEvents = await ApiService.getEvents(
        category: _selectedCategory != 'All' ? _selectedCategory : null,
        search: query.isNotEmpty ? query : null,
        period: 'upcoming',
      );
      if (mounted) {
        setState(() {
          _events = rawEvents.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
          _loadingEvents = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primary,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: 24,
              ),
              children: [
                // Top Header (Section 8: Discover Clubs & Events)
                EntranceAnimation(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover Clubs & Events',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Explore verified student organizations, interest clubs, and upcoming campus events.',
                        style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Search & Sort bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search by keyword, club name or category...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          _loadData();
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sort Selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSort,
                                icon: const Icon(Icons.sort_rounded, size: 18, color: AppTheme.textSecondary),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                items: const [
                                  DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
                                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                                  DropdownMenuItem(value: 'name', child: Text('Alphabetical')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedSort = val);
                                    _loadData();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Filter chips (Section 8 requirement)
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final cat = _categories[i];
                            final isSel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSel,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCategory = cat);
                                  _loadData();
                                }
                              },
                              selectedColor: AppTheme.primaryTint,
                              backgroundColor: AppTheme.surface,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                              side: BorderSide(
                                color: isSel ? AppTheme.primary : AppTheme.border,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tabs: Clubs vs Events
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _tabButton(0, 'Clubs (${_clubs.length})', Icons.groups_rounded),
                            _tabButton(1, 'Events (${_events.length})', Icons.event_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Content View
                if (_activeTab == 0) _buildClubsGrid(isDesktop) else _buildEventsGrid(isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int tab, String label, IconData icon) {
    final isSel = _activeTab == tab;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSel ? AppTheme.softShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSel ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubsGrid(bool isDesktop) {
    if (_loadingClubs) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final count = isDesktop ? 3 : (constraints.maxWidth > 550 ? 2 : 1);
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (_, __) => const ClubCardSkeleton(),
          );
        },
      );
    }

    if (_clubs.isEmpty) {
      return EmptyState(
        icon: Icons.groups_outlined,
        title: 'No clubs found',
        subtitle: 'No campus clubs match your filter or search query. Try choosing another category.',
        actionLabel: 'Reset Filters',
        onAction: () {
          _searchCtrl.clear();
          setState(() {
            _selectedCategory = 'All';
            _selectedSort = 'popular';
          });
          _loadData();
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 3 : (constraints.maxWidth > 550 ? 2 : 1);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _clubs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (ctx, i) {
            final club = _clubs[i];
            return ClubCard(
              club: club,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventsGrid(bool isDesktop) {
    if (_loadingEvents) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final count = isDesktop ? 2 : 1;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (_, __) => const EventCardSkeleton(),
          );
        },
      );
    }

    if (_events.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No events found',
        subtitle: 'Nothing planned for this category yet. Check back soon for new campus events.',
        actionLabel: 'Show All Events',
        onAction: () {
          _searchCtrl.clear();
          setState(() => _selectedCategory = 'All');
          _loadData();
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 2 : 1;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _events.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.7 : 1.35,
          ),
          itemBuilder: (ctx, i) {
            final ev = _events[i];
            return EventCard(
              event: ev,
              onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: ev.id),
            );
          },
        );
      },
    );
  }
}
