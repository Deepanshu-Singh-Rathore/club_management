import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/club.dart';
import '../models/club_post.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';
import '../widgets/event_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'admin/club_admin_dashboard.dart';
import 'club_chat_screen.dart';

class ClubDetailScreen extends StatefulWidget {
  final Club club;
  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  // Tab indexes: 0: Overview, 1: Events, 2: Community, 3: Members
  int _activeTab = 0;

  List<Event> _events = [];
  bool _loadingEvents = true;

  List<ClubPost> _posts = [];
  bool _loadingPosts = false;
  bool _postsLoaded = false;

  List<dynamic> _members = [];
  bool _loadingMembers = false;
  bool _membersLoaded = false;

  bool _isJoined = false;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  // Fast initial load: only membership check and events
  Future<void> _loadOverviewData() async {
    setState(() => _loadingEvents = true);
    try {
      final futures = await Future.wait([
        ApiService.getEvents(clubId: widget.club.id),
        ApiService.getUserClubs(),
      ]);

      if (mounted) {
        final rawEvents = futures[0];
        final myClubs = futures[1];

        setState(() {
          _events = rawEvents.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
          _isJoined = myClubs.any((c) => (c as Map)['id'] == widget.club.id);
          _loadingEvents = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  // Lazy loading of Community tab (Section 9 requirement)
  Future<void> _loadCommunityPosts() async {
    if (_postsLoaded) return;
    setState(() => _loadingPosts = true);
    try {
      final rawPosts = await ApiService.getClubPosts(widget.club.id);
      if (mounted) {
        setState(() {
          _posts = rawPosts.map((p) => ClubPost.fromJson(p as Map<String, dynamic>)).toList();
          _postsLoaded = true;
          _loadingPosts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  // Lazy loading of Members tab (Section 9 requirement)
  Future<void> _loadMembers() async {
    if (_membersLoaded) return;
    setState(() => _loadingMembers = true);
    try {
      final membersData = await ApiService.getClubMembers(widget.club.id);
      if (mounted) {
        setState(() {
          _members = membersData['members'] ?? [];
          _membersLoaded = true;
          _loadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  void _onTabSelected(int index) {
    setState(() => _activeTab = index);
    if (index == 2) {
      _loadCommunityPosts();
    } else if (index == 3) {
      _loadMembers();
    }
  }

  Future<void> _toggleJoin() async {
    if (_isJoined) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Leave Club', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Text('Are you sure you want to leave ${widget.club.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave Club'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _joining = true);
      try {
        await ApiService.leaveClub(widget.club.id);
        if (mounted) {
          setState(() {
            _isJoined = false;
            _joining = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Left ${widget.club.name}'), backgroundColor: AppTheme.warning),
          );
          _loadOverviewData();
        }
      } catch (_) {
        if (mounted) setState(() => _joining = false);
      }
    } else {
      setState(() => _joining = true);
      try {
        await ApiService.joinClub(widget.club.id);
        if (mounted) {
          setState(() {
            _isJoined = true;
            _joining = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Joined ${widget.club.name}!'), backgroundColor: AppTheme.success),
          );
          _loadOverviewData();
        }
      } catch (_) {
        if (mounted) setState(() => _joining = false);
      }
    }
  }

  void _shareClub() {
    Clipboard.setData(ClipboardData(
      text: 'Check out ${widget.club.name} on ClubSphere! A campus organization for ${widget.club.category}.',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Club info copied to clipboard!'), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;
    final isClubAdmin = auth.isAdmin || (auth.isClubHead && widget.club.createdByName == auth.user?.fullName);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(widget.club.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Club',
            onPressed: _shareClub,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Club Chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClubChatScreen(club: widget.club)),
            ),
          ),
          if (isClubAdmin) ...[
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Club Admin Console',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClubAdminDashboard(club: widget.club)),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 24,
            ),
            children: [
              // Hero Section (Section 9: Banner, Logo, Name, Category, Members, Buttons)
              EntranceAnimation(
                child: _buildHeroSection(isDesktop, isClubAdmin),
              ),
              const SizedBox(height: 24),

              // Clean Tab Selector (Section 9: Overview, Events, Community, Members)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _tabButton(0, 'Overview', Icons.info_outline_rounded)),
                    Expanded(child: _tabButton(1, 'Events (${_events.length})', Icons.event_rounded)),
                    Expanded(child: _tabButton(2, 'Community', Icons.forum_rounded)),
                    Expanded(child: _tabButton(3, 'Members', Icons.people_outline_rounded)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Views
              if (_activeTab == 0)
                _buildOverviewTab(isDesktop)
              else if (_activeTab == 1)
                _buildEventsTab(isDesktop)
              else if (_activeTab == 2)
                _buildCommunityTab()
              else
                _buildMembersTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int tab, String label, IconData icon) {
    final isSel = _activeTab == tab;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _onTabSelected(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSel ? AppTheme.softShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSel ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop, bool isClubAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top Strip
          Container(
            height: isDesktop ? 120 : 90,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club Monogram Logo
                    Container(
                      width: 60,
                      height: 60,
                      transform: Matrix4.translationValues(0, -38, 0),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Center(
                        child: Text(
                          widget.club.name.isNotEmpty ? widget.club.name[0].toUpperCase() : 'C',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.club.name,
                                  style: TextStyle(
                                    fontSize: isDesktop ? 22 : 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.club.category,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people_alt_outlined, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 5),
                              Text(
                                '${widget.club.memberCount} active members',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.border, shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              const Text('Verified Campus Club', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.borderSubtle),
                const SizedBox(height: 14),

                // Action Buttons: Join Club & Share
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _joining ? null : _toggleJoin,
                      icon: _joining
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_isJoined ? Icons.check_circle_rounded : Icons.person_add_rounded, size: 16),
                      label: Text(
                        _isJoined ? 'Joined Member ✓' : 'Join Club',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isJoined ? AppTheme.success : AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _shareClub,
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: const Text('Share', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (isClubAdmin) ...[
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ClubAdminDashboard(club: widget.club)),
                        ),
                        icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
                        label: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDesktop) {
    final upcomingEvents = _events.where((e) => !e.isCompleted && !e.isCancelled).take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About the Organization', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Text(
                widget.club.description.isNotEmpty
                    ? widget.club.description
                    : 'Official student organization registered on ClubSphere university network.',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.person_pin_rounded, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'President / Club Lead: ${widget.club.createdByName ?? 'Appointed Officer'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Upcoming Events Preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Club Events', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            if (_events.isNotEmpty)
              TextButton(
                onPressed: () => _onTabSelected(1),
                child: const Text('View All Events →', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_loadingEvents)
          const EventCardSkeleton()
        else if (upcomingEvents.isEmpty)
          const EmptyState(
            icon: Icons.event_available_rounded,
            title: 'No upcoming club events',
            subtitle: 'This club has not announced any upcoming events yet. Check back soon!',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 720 ? 2 : 1;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: upcomingEvents.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth >= 720 ? 1.7 : 1.35,
                ),
                itemBuilder: (ctx, i) {
                  final ev = upcomingEvents[i];
                  return EventCard(
                    event: ev,
                    onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: ev.id),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildEventsTab(bool isDesktop) {
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
      return const EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No events found',
        subtitle: 'This organization has not hosted any events yet.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = isDesktop ? 2 : 1;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _events.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
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

  Widget _buildCommunityTab() {
    if (_loadingPosts) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (_posts.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'No community posts yet',
        subtitle: 'Announcements and club discussions will appear here.',
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final p = _posts[i];
        final isAnnouncement = p.postType == 'announcement';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isAnnouncement ? AppTheme.primaryLight.withValues(alpha: 0.4) : AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: isAnnouncement ? AppTheme.primaryTint : AppTheme.surfaceVariant,
                    child: Text(
                      p.authorName.isNotEmpty ? p.authorName[0].toUpperCase() : 'A',
                      style: TextStyle(fontWeight: FontWeight.w700, color: isAnnouncement ? AppTheme.primary : AppTheme.textPrimary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Text(
                          DateFormat('MMM d, y • h:mm a').format(p.createdAt.toLocal()),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (isAnnouncement)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.primaryTint, borderRadius: BorderRadius.circular(8)),
                      child: const Text('NOTICE', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(p.content, style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.5)),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFEF4444)),
                  const SizedBox(width: 5),
                  Text('${p.likesCount} likes', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment_outlined, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 5),
                  Text('${p.commentsCount} comments', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    if (_loadingMembers) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (_members.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'No members directory',
        subtitle: 'Members will be listed here as students join this club.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _members.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final m = _members[i] as Map<String, dynamic>;
          final name = m['user_name'] ?? m['full_name'] ?? 'Student';
          final email = m['user_email'] ?? '';
          final role = (m['role'] ?? 'member').toString().toUpperCase();

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryTint,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: role.contains('HEAD') ? AppTheme.primaryTint : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: role.contains('HEAD') ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}