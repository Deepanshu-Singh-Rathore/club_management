import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';
import '../widgets/event_ticket_dialog.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  bool _loadingData = true;

  List<dynamic> _myClubs = [];
  List<dynamic> _myEvents = [];
  List<Achievement> _badges = [];
  int _unlockedCount = 0;
  // Tabs: 0: Overview, 1: My Clubs, 2: My Events, 3: Achievements (Section 11 requirement)
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _populateFields(user);
    _loadProfileData();
  }

  void _populateFields(User? user) {
    if (user != null) {
      _nameCtrl.text = user.fullName;
      _phoneCtrl.text = user.phoneNumber ?? '';
      _deptCtrl.text = user.department;
      _yearCtrl.text = user.yearOfStudy;
      _bioCtrl.text = user.bio;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    _yearCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final futures = await Future.wait([
        ApiService.getUserClubs(),
        ApiService.getMyEvents(),
        ApiService.getAchievements(),
      ]);

      if (mounted) {
        final rawBadges = (futures[2] as Map<String, dynamic>)['badges'] as List? ?? [];
        setState(() {
          _myClubs = futures[0] as List;
          _myEvents = futures[1] as List;
          _badges = rawBadges.map((b) => Achievement.fromJson(b as Map<String, dynamic>)).toList();
          _unlockedCount = (futures[2] as Map<String, dynamic>)['unlocked_count'] ?? 0;
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  String _sanitizePhone(String input) {
    var cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '').trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    } else if (!cleaned.startsWith('+') && cleaned.length == 10) {
      cleaned = '+91$cleaned';
    } else if (!cleaned.startsWith('+') && cleaned.isNotEmpty) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    try {
      await ApiService.updateMe({
        'full_name': _nameCtrl.text.trim(),
        'phone_number': _sanitizePhone(_phoneCtrl.text),
        'department': _deptCtrl.text.trim(),
        'year_of_study': _yearCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      });
      await auth.refreshProfile();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out of your ClubSphere account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final nav = Navigator.of(context);
      await auth.logout();
      nav.pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(backgroundColor: AppTheme.background);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;
    final attendedCount = _myEvents.where((e) => (e as Map)['attendance_status'] == 'checked_in').length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Campus Profile'),
        actions: [
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
            )
          else
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 16),
              label: const Text('Save Changes'),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 24),
            children: [
              // Header: Avatar, Name, Course, Year, Bio (Section 11)
              EntranceAnimation(
                child: _buildProfileHeader(user, isDesktop),
              ),
              const SizedBox(height: 20),

              // Stats: Events attended, Clubs, Achievements (Section 11)
              EntranceAnimation(
                delayMs: 80,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Events Attended',
                        value: '$attendedCount',
                        icon: Icons.event_available_rounded,
                        color: AppTheme.primary,
                        onTap: () => setState(() => _activeTab = 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Clubs Joined',
                        value: '${_myClubs.length}',
                        icon: Icons.groups_rounded,
                        color: AppTheme.secondary,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Achievements',
                        value: '$_unlockedCount',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFFBBF24),
                        onTap: () => setState(() => _activeTab = 3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Edit Form or Tabs
              if (_editing)
                EntranceAnimation(child: _buildEditForm())
              else ...[
                // Tabs: Overview, My Clubs, My Events, Achievements (Section 11 requirement)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _tabBtn(0, 'Overview', Icons.badge_outlined)),
                      Expanded(child: _tabBtn(1, 'My Clubs (${_myClubs.length})', Icons.groups_rounded)),
                      Expanded(child: _tabBtn(2, 'My Events (${_myEvents.length})', Icons.event_available_rounded)),
                      Expanded(child: _tabBtn(3, 'Achievements ($_unlockedCount)', Icons.emoji_events_rounded)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_loadingData)
                  const Row(
                    children: [
                      Expanded(child: StatCardSkeleton()),
                      SizedBox(width: 12),
                      Expanded(child: StatCardSkeleton()),
                    ],
                  )
                else if (_activeTab == 0)
                  _buildOverviewTab(user)
                else if (_activeTab == 1)
                  _buildMyClubsList()
                else if (_activeTab == 2)
                  _buildMyEventsList(user)
                else
                  _buildAchievementsList(isDesktop),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(int tab, String label, IconData icon) {
    final isSel = _activeTab == tab;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _activeTab = tab),
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
                fontSize: 12.5,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 26 : 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isDesktop ? 36 : 28,
            backgroundColor: AppTheme.primaryTint,
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: isDesktop ? 30 : 22,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: isDesktop ? 22 : 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isAdmin ? AppTheme.warningBg : AppTheme.primaryTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: user.isAdmin ? AppTheme.warning : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    if (user.department.isNotEmpty)
                      _metaChip(Icons.school_rounded, user.department),
                    if (user.yearOfStudy.isNotEmpty)
                      _metaChip(Icons.calendar_month_rounded, user.yearOfStudy),
                  ],
                ),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(user.bio, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.45)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(User user) {
    final upcomingEvents = _myEvents.where((e) {
      final ev = e['event'];
      if (ev == null) return false;
      return ev['status'] != 'completed' && ev['status'] != 'cancelled';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Digital Tickets Preview for upcoming registered events (Section 11)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Event Passes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            if (upcomingEvents.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _activeTab = 2),
                child: const Text('View All Passes →', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (upcomingEvents.isEmpty)
          const EmptyState(
            icon: Icons.confirmation_number_outlined,
            title: 'No upcoming passes',
            subtitle: 'Register for campus events to automatically generate digital ticket passes.',
          )
        else
          ...upcomingEvents.take(2).map((reg) {
            final evJson = reg['event'];
            final ev = Event.fromJson(evJson as Map<String, dynamic>);
            final ticketId = reg['ticket_id'] ?? '';
            final attendance = reg['attendance_status'] ?? 'registered';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${ev.clubName} • ${DateFormat('MMM d, h:mm a').format(ev.eventDate.toLocal())}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      EventTicketDialog.show(
                        context,
                        event: ev,
                        user: user,
                        ticketId: ticketId,
                        attendanceStatus: attendance,
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                    label: const Text('View Pass'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Profile Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          const SizedBox(height: 12),
          TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Course / Department (e.g. Computer Science)')),
          const SizedBox(height: 12),
          TextField(controller: _yearCtrl, decoration: const InputDecoration(labelText: 'Year of Study (e.g. 3rd Year)')),
          const SizedBox(height: 12),
          TextField(controller: _bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio / About You')),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyClubsList() {
    if (_myClubs.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'You haven\'t joined any clubs',
        subtitle: 'Explore the clubs directory to join organizations and participate in discussions.',
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _myClubs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final c = _myClubs[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    (c['name'] as String).isNotEmpty ? (c['name'] as String)[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('${c['category'] ?? 'Club'} • ${c['member_count'] ?? 0} members', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.successBg, borderRadius: BorderRadius.circular(8)),
                child: const Text('Member', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyEventsList(User user) {
    if (_myEvents.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No registered events',
        subtitle: 'You have not registered for any campus events yet.',
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _myEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final reg = _myEvents[i];
        final eventJson = reg['event'];
        if (eventJson == null) return const SizedBox.shrink();
        final event = Event.fromJson(eventJson as Map<String, dynamic>);
        final ticketId = reg['ticket_id'] ?? '';
        final attendance = reg['attendance_status'] ?? 'registered';
        final isCheckedIn = attendance == 'checked_in';
        final formattedDate = DateFormat('MMM d, y • h:mm a').format(event.eventDate.toLocal());

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCheckedIn ? AppTheme.successBg : AppTheme.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCheckedIn ? Icons.check_circle_rounded : Icons.confirmation_number_rounded,
                  color: isCheckedIn ? AppTheme.success : AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${event.clubName} • $formattedDate', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  EventTicketDialog.show(
                    context,
                    event: event,
                    user: user,
                    ticketId: ticketId,
                    attendanceStatus: attendance,
                  );
                },
                icon: const Icon(Icons.qr_code_rounded, size: 16),
                label: const Text('Ticket Pass', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsList(bool isDesktop) {
    if (_badges.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No achievements available',
        subtitle: 'Participate in club events and community discussions to unlock milestone achievements.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = isDesktop ? 3 : (constraints.maxWidth > 550 ? 2 : 1);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _badges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (ctx, i) {
            final b = _badges[i];
            final unlocked = b.isUnlocked;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: unlocked ? AppTheme.surface : AppTheme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: unlocked ? const Color(0xFFFBBF24).withValues(alpha: 0.4) : AppTheme.border,
                ),
                boxShadow: unlocked ? AppTheme.softShadow : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: unlocked ? const Color(0xFFFEF3C7) : AppTheme.borderSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                          color: unlocked ? const Color(0xFFD97706) : AppTheme.textMuted,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: unlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                              ),
                            ),
                            if (unlocked && b.unlockedAt != null)
                              Text(
                                'Unlocked ${DateFormat('MMM d').format(b.unlockedAt!.toLocal())}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              )
                            else
                              const Text('Locked', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    b.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: unlocked ? AppTheme.textSecondary : AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
