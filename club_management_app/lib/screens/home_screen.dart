import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/club.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clubsphere_logo.dart';
import '../widgets/entrance_animation.dart';
import '../widgets/global_search_dialog.dart';
import '../widgets/event_card.dart';
import '../widgets/club_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/club_admin_dashboard.dart';
import 'club_detail_screen.dart';
import 'club_chat_screen.dart';
import 'clubs_screen.dart';
import 'community_feed_screen.dart';
import 'discover_screen.dart';
import 'events_screen.dart';
import 'my_clubs_screen.dart';
import 'achievements_screen.dart';
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
  bool _sidebarCollapsed = false;

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

  void _openChatDialog() async {
    try {
      final myClubsRaw = await ApiService.getUserClubs();
      if (!mounted) return;
      if (myClubsRaw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join a club first to participate in club chat!'),
            backgroundColor: AppTheme.primary,
          ),
        );
        _switchTab(3); // Go to clubs
        return;
      }

      final clubs = myClubsRaw.map((e) => Club.fromJson(e as Map<String, dynamic>)).toList();
      if (clubs.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClubChatScreen(club: clubs.first)),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Club Chat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: SizedBox(
            width: 360,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: clubs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (c, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTint,
                  child: Text(
                    clubs[i].name.isNotEmpty ? clubs[i].name[0].toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ),
                title: Text(clubs[i].name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(clubs[i].category, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClubChatScreen(club: clubs[i])),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    final pages = [
      _DashboardTab(
        onViewAllEvents: () => _switchTab(2),
        onExploreClubs: () => _switchTab(1),
        onOpenCommunity: () => _switchTab(4),
        onOpenMyEvents: () => _switchTab(6),
        onOpenAchievements: () => _switchTab(7),
      ),
      const DiscoverScreen(),
      const EventsScreen(),
      const ClubsScreen(),
      const CommunityFeedScreen(),
      const NotificationsScreen(isEmbedded: true),
      const ProfileScreen(),
      const AchievementsScreen(),
      const MyClubsScreen(),
      if (auth.isAdmin)
        const AdminDashboardScreen()
      else if (auth.isClubHead)
        const ClubAdminDashboard(),
    ];

    final scaffoldContent = isDesktop
        ? Scaffold(
            backgroundColor: AppTheme.background,
            body: Row(
              children: [
                // Left Collapsible Sidebar
                _WebSidebar(
                  selectedIndex: _tab,
                  isCollapsed: _sidebarCollapsed,
                  onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                  onSelect: _switchTab,
                  onOpenChat: _openChatDialog,
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
                        onOpenProfile: () => _switchTab(6),
                        onOpenNotifications: () => _switchTab(5),
                        onOpenSearch: () => GlobalSearchDialog.show(context),
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
          )
        : Scaffold(
            appBar: AppBar(
              titleSpacing: 16,
              title: const ClubSphereLogo(size: 28, showText: true),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, size: 22),
                  tooltip: 'Search',
                  onPressed: () => GlobalSearchDialog.show(context),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 22),
                      tooltip: 'Notifications',
                      onPressed: () => _switchTab(5),
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
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                InkWell(
                  onTap: () => _switchTab(6),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primaryTint,
                      child: Text(
                        auth.user?.displayName.isNotEmpty == true ? auth.user!.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: IndexedStack(
              index: _tab.clamp(0, pages.length - 1),
              children: pages,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab < 5 ? _tab : 0,
              onDestinationSelected: (idx) => _switchTab(idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_outlined),
                  selectedIcon: Icon(Icons.event_rounded),
                  label: 'Events',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'Clubs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum_rounded),
                  label: 'Community',
                ),
              ],
            ),
          );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => GlobalSearchDialog.show(context),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () => GlobalSearchDialog.show(context),
      },
      child: Focus(
        autofocus: true,
        child: scaffoldContent,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Web Desktop Sidebar
// ---------------------------------------------------------------------------

class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenChat;
  final bool isAdmin;
  final bool isClubHead;
  final dynamic user;
  final VoidCallback onNewEvent;
  final int unreadNotifications;

  const _WebSidebar({
    required this.selectedIndex,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onSelect,
    required this.onOpenChat,
    required this.isAdmin,
    required this.isClubHead,
    required this.user,
    required this.onNewEvent,
    this.unreadNotifications = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 76.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Logo & Collapse Action
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 18,
              vertical: 20,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  const ClubSphereLogo(
                    size: 32,
                    showText: true,
                    subtitle: 'University Hub',
                  ),
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: onToggleCollapse,
                  splashRadius: 18,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Nav Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: [
                if (!isCollapsed) _sectionLabel('NAVIGATION'),
                _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.explore_outlined, Icons.explore_rounded, 'Discover'),
                _navItem(2, Icons.event_outlined, Icons.event_rounded, 'Events'),
                _navItem(3, Icons.groups_outlined, Icons.groups_rounded, 'Clubs'),
                _navItem(4, Icons.forum_outlined, Icons.forum_rounded, 'Community'),
                _navItem(
                  -1,
                  Icons.chat_bubble_outline_rounded,
                  Icons.chat_bubble_rounded,
                  'Chat',
                  customTap: onOpenChat,
                ),

                const SizedBox(height: 16),
                if (!isCollapsed) _sectionLabel('MY ACTIVITY'),
                _navItem(6, Icons.confirmation_number_outlined, Icons.confirmation_number_rounded, 'My Events'),
                _navItem(8, Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'My Clubs'),
                _navItem(7, Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'Achievements'),

                if (isAdmin || isClubHead) ...[
                  const SizedBox(height: 16),
                  if (!isCollapsed) _sectionLabel('CLUB MANAGEMENT'),
                  _navItem(
                    9,
                    Icons.dashboard_customize_outlined,
                    Icons.dashboard_customize_rounded,
                    isAdmin ? 'Admin Console' : 'My Club Admin',
                  ),
                  if (!isCollapsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: ElevatedButton.icon(
                        onPressed: onNewEvent,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Bottom: Profile / User Card
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppTheme.primaryTint,
                      child: Text(
                        user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13),
                      ),
                    ),
                    if (!isCollapsed) ...[
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
                              user?.role.toUpperCase() ?? 'STUDENT',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    VoidCallback? customTap,
    int badgeCount = 0,
  }) {
    final isSelected = index >= 0 && selectedIndex == index;

    final itemWidget = Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: isSelected ? AppTheme.primaryTint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: customTap ?? () => onSelect(index),
          hoverColor: AppTheme.primaryTint.withValues(alpha: 0.5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? const Border(left: BorderSide(color: AppTheme.primary, width: 3.5))
                  : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 19,
                ),
                if (!isCollapsed) ...[
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.primaryTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        child: itemWidget,
      );
    }

    return itemWidget;
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
  final VoidCallback onOpenSearch;
  final int unreadNotifications;

  const _WebHeader({
    required this.currentTab,
    required this.user,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.onOpenSearch,
    this.unreadNotifications = 0,
  });

  String get _title {
    switch (currentTab) {
      case 0:
        return 'Campus Dashboard';
      case 1:
        return 'Discover Clubs & Events';
      case 2:
        return 'Events Directory';
      case 3:
        return 'Clubs Directory';
      case 4:
        return 'Campus Community Feed';
      case 5:
        return 'Notifications & Alerts';
      case 6:
        return 'My Campus Profile';
      case 7:
        return 'My Achievements';
      case 8:
        return 'My Joined Clubs';
      case 9:
        return 'Administrator Console';
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
          // Breadcrumb Title
          Text(
            _title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),

          // Quick Search Trigger Input (Desktop SaaS style)
          Material(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpenSearch,
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Search clubs, events...',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'Ctrl+K',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Notifications Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 20),
                tooltip: 'Notifications',
                onPressed: onOpenNotifications,
              ),
              if (unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    child: Center(
                      child: Text(
                        unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, height: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),

          // User Profile Pill
          InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
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
// Student Home Dashboard Tab
// ---------------------------------------------------------------------------

class _DashboardTab extends StatefulWidget {
  final VoidCallback onViewAllEvents;
  final VoidCallback onExploreClubs;
  final VoidCallback onOpenCommunity;
  final VoidCallback onOpenMyEvents;
  final VoidCallback onOpenAchievements;

  const _DashboardTab({
    required this.onViewAllEvents,
    required this.onExploreClubs,
    required this.onOpenCommunity,
    required this.onOpenMyEvents,
    required this.onOpenAchievements,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<Event> _upcomingEvents = [];
  List<Club> _recommendedClubs = [];
  List<dynamic> _announcements = [];
  int _registeredCount = 0;
  int _joinedClubsCount = 0;
  int _attendedCount = 0;
  int _achievementsCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final futures = await Future.wait([
        ApiService.getEvents(period: 'upcoming'),
        ApiService.getRecommendations(),
        ApiService.getAnnouncements(),
        ApiService.getMyEvents(),
        ApiService.getUserClubs(),
        ApiService.getAchievements(),
      ]);

      if (mounted) {
        final rawEvents = futures[0] as List;
        final recs = futures[1] as Map<String, dynamic>;
        final rawAnnouncements = futures[2] as List;
        final myEvents = futures[3] as List;
        final myClubs = futures[4] as List;
        final achievements = futures[5] as Map<String, dynamic>;

        final parsedUpcoming = rawEvents.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
        final recClubsRaw = (recs['recommended_clubs'] as List?) ?? [];

        setState(() {
          _upcomingEvents = parsedUpcoming.take(4).toList();
          _recommendedClubs = recClubsRaw.map((c) => Club.fromJson(c as Map<String, dynamic>)).take(4).toList();
          _announcements = rawAnnouncements.take(3).toList();
          _registeredCount = myEvents.length;
          _joinedClubsCount = myClubs.length;
          _attendedCount = myEvents.where((e) => (e as Map)['attendance_status'] == 'checked_in').length;
          _achievementsCount = achievements['unlocked_count'] ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    if (_loading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: const [
              SkeletonBox(height: 120, borderRadius: 16),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: StatCardSkeleton()),
                  SizedBox(width: 12),
                  Expanded(child: StatCardSkeleton()),
                  SizedBox(width: 12),
                  Expanded(child: StatCardSkeleton()),
                  SizedBox(width: 12),
                  Expanded(child: StatCardSkeleton()),
                ],
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: EventCardSkeleton()),
                  SizedBox(width: 16),
                  Expanded(child: EventCardSkeleton()),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppTheme.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 24),
            children: [
              // 1. TOP GREETING & SEARCH BAR
              EntranceAnimation(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isDesktop ? 28 : 20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greetingText()}, ${user?.displayName ?? 'Student'} 👋',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 25 : 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Discover what's happening across campus.",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              user?.role.toUpperCase() ?? 'STUDENT',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Search bar trigger
                      InkWell(
                        onTap: () => GlobalSearchDialog.show(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Search clubs, events, activities...',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. UPCOMING EVENTS (Section 5 requirement)
              EntranceAnimation(
                delayMs: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upcoming Events',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onViewAllEvents,
                          child: const Text('View all →', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_upcomingEvents.isEmpty)
                      const EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'No upcoming events',
                        subtitle: 'Nothing planned yet. Check back soon for new campus events.',
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final count = constraints.maxWidth >= 760 ? 2 : 1;
                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _upcomingEvents.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: constraints.maxWidth >= 760 ? 1.75 : 1.35,
                            ),
                            itemBuilder: (ctx, i) {
                              final ev = _upcomingEvents[i];
                              return EventCard(
                                event: ev,
                                onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: ev.id),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. RECOMMENDED FOR YOU (Section 5 requirement)
              if (_recommendedClubs.isNotEmpty) ...[
                EntranceAnimation(
                  delayMs: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recommended For You',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onExploreClubs,
                            child: const Text('Explore all →', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final count = constraints.maxWidth >= 900
                              ? 4
                              : (constraints.maxWidth >= 550 ? 2 : 1);
                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _recommendedClubs.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.25,
                            ),
                            itemBuilder: (ctx, i) {
                              final club = _recommendedClubs[i];
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 4. CAMPUS ANNOUNCEMENTS (Section 5 requirement)
              if (_announcements.isNotEmpty) ...[
                EntranceAnimation(
                  delayMs: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.campaign_rounded, color: AppTheme.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Campus Announcements',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: widget.onOpenCommunity,
                            child: const Text('View Feed →', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._announcements.map((a) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a['title'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${a['club_name']} • ${DateFormat('MMM d').format(DateTime.parse(a['created_at']))}',
                                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 5. YOUR ACTIVITY (Section 5 requirement: Compact statistics)
              EntranceAnimation(
                delayMs: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final count = constraints.maxWidth >= 860
                            ? 4
                            : (constraints.maxWidth >= 500 ? 2 : 1);
                        return GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: count,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                          children: [
                            StatCard(
                              label: 'Registered Events',
                              value: '$_registeredCount',
                              icon: Icons.how_to_reg_rounded,
                              color: AppTheme.primary,
                              onTap: widget.onOpenMyEvents,
                            ),
                            StatCard(
                              label: 'Joined Clubs',
                              value: '$_joinedClubsCount',
                              icon: Icons.groups_rounded,
                              color: AppTheme.secondary,
                              onTap: widget.onExploreClubs,
                            ),
                            StatCard(
                              label: 'Events Attended',
                              value: '$_attendedCount',
                              icon: Icons.done_all_rounded,
                              color: const Color(0xFF10B981),
                              onTap: widget.onOpenMyEvents,
                            ),
                            StatCard(
                              label: 'Achievements',
                              value: '$_achievementsCount',
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFFFBBF24),
                              onTap: widget.onOpenAchievements,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}