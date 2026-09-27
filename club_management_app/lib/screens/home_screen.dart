import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/club.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_hover_card.dart';
import '../widgets/clubsphere_logo.dart';
import '../widgets/entrance_animation.dart';
import 'admin/admin_dashboard_screen.dart';
import 'clubs_screen.dart';
import 'events_screen.dart';
import 'my_clubs_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final raw = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotifCount = raw.where((e) => e['is_read'] == false).length;
        });
      }
    } catch (_) {}
  }

  void _switchTab(int index) {
    setState(() => _tab = index);
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 860;

    final pages = [
      _DashboardTab(onViewAllEvents: () => _switchTab(2), onExploreClubs: () => _switchTab(1)),
      const ClubsScreen(),
      const EventsScreen(),
      const MyClubsScreen(),
      const NotificationsScreen(isEmbedded: true),
      const ProfileScreen(),
      if (auth.isAdmin) const AdminDashboardScreen(),
    ];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            // Web Desktop Sidebar
            _WebSidebar(
              selectedIndex: _tab,
              onSelect: _switchTab,
              isAdmin: auth.isAdmin,
              isClubHead: auth.isClubHead,
              user: auth.user,
              unreadNotifications: _unreadNotifCount,
              onNewEvent: () async {
                await Navigator.pushNamed(context, '/clubhead/create-event');
                if (mounted) setState(() {});
              },
            ),

            // Main Web Canvas
            Expanded(
              child: Column(
                children: [
                  _WebHeader(
                    currentTab: _tab,
                    user: auth.user,
                    unreadNotifications: _unreadNotifCount,
                    onOpenProfile: () => _switchTab(5),
                    onOpenNotifications: () => _switchTab(4),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tab.clamp(0, pages.length - 1),
                      children: pages,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout (< 860px)
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const ClubSphereLogo(
          size: 32,
          showText: true,
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                tooltip: 'Notifications',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  _loadUnreadCount();
                },
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryTint,
                child: Text(
                  auth.user?.displayName.isNotEmpty == true
                      ? auth.user!.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab.clamp(0, 2),
        children: [
          _DashboardTab(onViewAllEvents: () => _switchTab(2), onExploreClubs: () => _switchTab(1)),
          const ClubsScreen(),
          const EventsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.clamp(0, 2),
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Clubs',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded),
            label: 'Events',
          ),
        ],
      ),
      floatingActionButton: (_tab == 0 && (auth.isAdmin || auth.isClubHead))
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, '/clubhead/create-event');
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Event',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Web Desktop Sidebar
// ---------------------------------------------------------------------------

class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isAdmin;
  final bool isClubHead;
  final dynamic user;
  final VoidCallback onNewEvent;
  final int unreadNotifications;

  const _WebSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.isAdmin,
    required this.isClubHead,
    required this.user,
    required this.onNewEvent,
    this.unreadNotifications = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Logo & Branding
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: ClubSphereLogo(
              size: 40,
              showText: true,
              subtitle: 'Campus Portal',
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 12),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                _sidebarItem(1, Icons.groups_outlined, Icons.groups_rounded, 'All Clubs'),
                _sidebarItem(2, Icons.event_outlined, Icons.event_rounded, 'Events'),
                _sidebarItem(3, Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'My Clubs'),
                _sidebarItem(
                  4,
                  Icons.notifications_outlined,
                  Icons.notifications_rounded,
                  'Notifications',
                  badgeCount: unreadNotifications,
                ),
                _sidebarItem(5, Icons.person_outline_rounded, Icons.person_rounded, 'My Profile'),
                if (isAdmin)
                  _sidebarItem(6, Icons.shield_outlined, Icons.shield_rounded, 'Admin Panel'),

                if (isAdmin || isClubHead) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton.icon(
                      onPressed: onNewEvent,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // User Footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryTint,
                  child: Text(
                    user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Student',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                      Text(
                        user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, IconData activeIcon, String label, {int badgeCount = 0}) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppTheme.primaryTint : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(index),
          hoverColor: AppTheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryDark : AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  )
                else if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Web Desktop Top Header
// ---------------------------------------------------------------------------

class _WebHeader extends StatelessWidget {
  final int currentTab;
  final dynamic user;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;
  final int unreadNotifications;

  const _WebHeader({
    required this.currentTab,
    required this.user,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    this.unreadNotifications = 0,
  });

  String get _title {
    switch (currentTab) {
      case 0:
        return 'Campus Dashboard';
      case 1:
        return 'Explore Clubs';
      case 2:
        return 'Campus Events';
      case 3:
        return 'My Joined Clubs';
      case 4:
        return 'Notifications & Alerts';
      case 5:
        return 'Account & Profile';
      case 6:
        return 'Administrator Dashboard';
      default:
        return 'ClubSphere';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Text(
            _title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                tooltip: 'Notifications',
                onPressed: onOpenNotifications,
              ),
              if (unreadNotifications > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryTint,
                    child: Text(
                      user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.displayName ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Tab
// ---------------------------------------------------------------------------

class _DashboardTab extends StatefulWidget {
  final VoidCallback onViewAllEvents;
  final VoidCallback onExploreClubs;

  const _DashboardTab({
    required this.onViewAllEvents,
    required this.onExploreClubs,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<Event> _events = [];
  List<Club> _myClubs = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final futures = <Future>[
      ApiService.getEvents(),
      ApiService.getUserClubs(),
    ];

    if (auth.isAdmin) {
      futures.add(ApiService.getAdminStats());
    }

    final results = await Future.wait(
      futures.map((f) => f.catchError((_) => null)),
    );

    if (!mounted) return;

    final raw = results[0] as List?;
    final rawClubs = results[1] as List?;

    final allEvents = (raw ?? [])
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .where((e) => e.status == 'upcoming')
        .toList();

    allEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    final parsedClubs = (rawClubs ?? [])
        .map((c) => Club.fromJson(c as Map<String, dynamic>))
        .toList();

    setState(() {
      _events = allEvents.take(6).toList();
      _myClubs = parsedClubs.take(4).toList();

      if (auth.isAdmin && results.length > 2 && results[2] != null) {
        _stats = results[2] as Map<String, dynamic>;
      }

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 860;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // Hero Welcome Banner
              EntranceAnimation(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isDesktop ? 28 : 20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _greetingText(),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.displayName ?? 'Student',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isDesktop ? 26 : 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (auth.isStudent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF6EE7B7)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Verified Student',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (auth.isAdmin)
                                _heroBadge('Campus Administrator', Icons.shield_rounded),
                              if (auth.isClubHead)
                                _heroBadge('Club Head', Icons.manage_accounts_rounded),
                              if (user?.rollNumber != null && user!.rollNumber!.isNotEmpty)
                                _heroBadge(user.rollNumber!, Icons.badge_outlined),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Admin Overview Row (if admin)
              if (auth.isAdmin && _stats.isNotEmpty) ...[
                EntranceAnimation(
                  delayMs: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Campus Statistics'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard('Total Users', '${_stats['total_users'] ?? 0}', Icons.people_alt_rounded, const Color(0xFF2563EB)),
                          const SizedBox(width: 14),
                          _StatCard('Active Clubs', '${_stats['total_clubs'] ?? 0}', Icons.groups_rounded, const Color(0xFF7C3AED)),
                          const SizedBox(width: 14),
                          _StatCard('Published Events', '${_stats['total_events'] ?? 0}', Icons.event_available_rounded, const Color(0xFF059669)),
                          const SizedBox(width: 14),
                          _StatCard('Pending Approvals', '${_stats['pending_registrations'] ?? 0}', Icons.pending_actions_rounded, const Color(0xFFD97706)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Split Desktop Layout: Left 65% Upcoming Events, Right 35% Quick Actions & Joined Clubs
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 65,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionTitle('Upcoming Campus Events'),
                              TextButton(
                                onPressed: widget.onViewAllEvents,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('View Calendar'),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_events.isEmpty)
                            _emptyEventsBox()
                          else
                            ..._events.map((e) => _EventTile(event: e)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Column
                    Expanded(
                      flex: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle('Quick Actions'),
                          const SizedBox(height: 12),
                          _QuickActionCard(
                            icon: Icons.groups_rounded,
                            title: 'Discover Clubs',
                            subtitle: 'Explore 30+ official student organizations',
                            color: const Color(0xFF2563EB),
                            onTap: widget.onExploreClubs,
                          ),
                          const SizedBox(height: 10),
                          _QuickActionCard(
                            icon: Icons.bookmark_added_rounded,
                            title: 'My Clubs & Chat',
                            subtitle: 'Access announcements & club rooms',
                            color: const Color(0xFF7C3AED),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyClubsScreen())),
                          ),
                          const SizedBox(height: 10),
                          _QuickActionCard(
                            icon: Icons.notifications_active_rounded,
                            title: 'Registration Alerts',
                            subtitle: 'Check approval status and invitations',
                            color: const Color(0xFF059669),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                          ),
                          const SizedBox(height: 24),

                          // My Clubs preview
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionTitle('My Clubs'),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyClubsScreen())),
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_myClubs.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: const Text(
                                'You haven\'t joined any clubs yet. Click Discover Clubs to join one!',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                              ),
                            )
                          else
                            ..._myClubs.map(
                              (c) => AnimatedHoverCard(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                onTap: () => Navigator.pushNamed(context, '/clubs'),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                          Text('${c.memberCount} members', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                // Mobile stacked layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle('Upcoming Events'),
                    TextButton(onPressed: widget.onViewAllEvents, child: const Text('See All')),
                  ],
                ),
                const SizedBox(height: 8),
                if (_events.isEmpty) _emptyEventsBox() else ..._events.map((e) => _EventTile(event: e)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyEventsBox() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: const [
          Icon(Icons.event_busy_rounded, size: 48, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text('No upcoming events right now', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 15)),
          SizedBox(height: 4),
          Text('New activities will be listed here as soon as they are announced.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _heroBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedHoverCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Event event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event;

    return AnimatedHoverCard(
      onTap: () {
        Navigator.pushNamed(context, '/event-detail', arguments: e.id);
      },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _month(e.eventDate.month).toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
                Text(
                  '${e.eventDate.day}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.groups_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        e.clubName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (e.capacity > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (e.registeredCount / e.capacity).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: AppTheme.surfaceVariant,
                            color: e.isFull ? AppTheme.error : AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.registeredCount}/${e.capacity}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _month(int m) => (m >= 1 && m <= 12) ? _months[m] : '';
}