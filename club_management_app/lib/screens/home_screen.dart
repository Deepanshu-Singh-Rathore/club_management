import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'events_screen.dart';
import 'clubs_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final List<Widget> _pages = [
    const _DashboardTab(),
    const ClubsScreen(),
    const EventsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClubSphere',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Clubs'),
          NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'Events'),
        ],
      ),
      floatingActionButton: (auth.isAdmin || auth.isClubHead)
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, '/clubhead/create-event'),
              icon: const Icon(Icons.add),
              label: const Text('New Event'),
            )
          : null,
    );
  }
}

// ─── Dashboard tab ───────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<Event> _events = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final futures = <Future>[ApiService.getEvents()];
    if (auth.isAdmin) futures.add(ApiService.getAdminStats());

    final results =
        await Future.wait(futures.map((f) => f.catchError((_) => null)));

    if (!mounted) return;
    setState(() {
      final raw = results[0] as List?;
      _events = (raw ?? [])
          .take(4)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
      if (auth.isAdmin && results.length > 1 && results[1] != null) {
        _stats = results[1] as Map<String, dynamic>;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  user?.displayName ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (auth.isStudent)
                  _Chip('${user?.points ?? 0} pts', Icons.star),
                if (auth.isAdmin) _Chip('Admin', Icons.shield),
                if (auth.isClubHead) _Chip('Club Head', Icons.manage_accounts),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Admin stats row
          if (auth.isAdmin && _stats.isNotEmpty) ...[
            const _SectionHeader('Overview'),
            const SizedBox(height: 10),
            Row(children: [
              _StatCard('Users', '${_stats['total_users'] ?? 0}', Icons.people,
                  Colors.blue),
              const SizedBox(width: 12),
              _StatCard('Clubs', '${_stats['total_clubs'] ?? 0}', Icons.group,
                  Colors.purple),
              const SizedBox(width: 12),
              _StatCard('Events', '${_stats['total_events'] ?? 0}', Icons.event,
                  Colors.green),
            ]),
            const SizedBox(height: 16),
            _StatCard(
                'Pending approvals',
                '${_stats['pending_registrations'] ?? 0}',
                Icons.pending_actions,
                Colors.orange,
                wide: true),
            const SizedBox(height: 20),

            // Admin quick actions
            const _SectionHeader('Admin Panel'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.people,
                  label: 'Manage Users',
                  onTap: () => Navigator.pushNamed(context, '/admin'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.group,
                  label: 'Manage Clubs',
                  onTap: () => Navigator.pushNamed(context, '/clubs'),
                ),
              ),
            ]),
            const SizedBox(height: 20),
          ],

          // Upcoming events
          const _SectionHeader('Upcoming Events'),
          const SizedBox(height: 10),
          if (_events.isEmpty)
            const Center(
                child: Text('No upcoming events',
                    style: TextStyle(color: Colors.grey)))
          else
            ..._events.map((e) => _EventTile(event: e)),
        ],
      ),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip(this.label, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;
  const _StatCard(this.label, this.value, this.icon, this.color,
      {this.wide = false});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
    return wide
        ? SizedBox(width: double.infinity, child: card)
        : Expanded(child: card);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.2)),
          ),
          child: Column(children: [
            Icon(icon, color: const Color(0xFF0D47A1)),
            const SizedBox(height: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _EventTile extends StatelessWidget {
  final Event event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
          child: const Icon(Icons.event, color: Color(0xFF0D47A1)),
        ),
        title: Text(event.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(event.clubName,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Text(
          '${event.eventDate.day} ${_month(event.eventDate.month)}',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D47A1)),
        ),
        onTap: () => Navigator.pushNamed(context, '/events'),
      ),
    );
  }

  String _month(int m) => [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}
