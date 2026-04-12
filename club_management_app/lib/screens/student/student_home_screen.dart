import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../core/index.dart';
import '../auth/login_screen.dart';
import 'browse_clubs_screen.dart';
import 'event_details_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'event_registrations_tab.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load initial data
  Future<void> _loadData() async {
    final clubProvider = context.read<ClubProvider>();
    final joinRequestProvider = context.read<JoinRequestProvider>();
    final eventProvider = context.read<EventProvider>();

    try {
      await Future.wait([
        clubProvider.fetchClubs(),
        joinRequestProvider.fetchJoinRequests(),
        eventProvider.fetchEvents(),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/login',
      arguments: const LoginScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Text(
                    '${authProvider.currentUser?.fullName ?? "Student"}',
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Clubs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'My Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Registrations',
          ),
        ],
      ),
    );
  }

  /// Build drawer with user info and menu
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(AppColors.primaryColor),
                ),
                accountName: Text(authProvider.currentUser?.fullName ?? ''),
                accountEmail: Text(authProvider.currentUser?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    (authProvider.currentUser?.fullName ?? 'S')[0],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Leaderboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  /// Build body based on selected tab
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildClubsTab();
      case 1:
        return _buildRequestsTab();
      case 2:
        return _buildEventsTab();
      case 3:
        return _buildRegistrationsTab();
      default:
        return const BrowseClubsScreen();
    }
  }

  /// Build clubs tab
  Widget _buildClubsTab() {
    return const BrowseClubsScreen();
  }

  /// Build requests tab
  Widget _buildRequestsTab() {
    return Consumer<JoinRequestProvider>(
      builder: (context, joinRequestProvider, _) {
        if (joinRequestProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (joinRequestProvider.joinRequests.isEmpty) {
          return Center(
            child: Text(
              'No join requests',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: joinRequestProvider.joinRequests.length,
          itemBuilder: (context, index) {
            final request = joinRequestProvider.joinRequests[index];
            final statusColor = request.status == 'approved'
                ? Colors.green
                : request.status == 'rejected'
                    ? Colors.red
                    : Colors.orange;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(request.club?['name'] ?? 'Unknown Club'),
                subtitle: Text(request.status),
                trailing: Chip(
                  label: Text(
                    request.status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: statusColor,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build events tab
  Widget _buildEventsTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        if (eventProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (eventProvider.events.isEmpty) {
          return Center(
            child: Text(
              'No events available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: eventProvider.events.length,
          itemBuilder: (context, index) {
            final event = eventProvider.events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(event.title),
                subtitle: Text(
                    '${event.clubName} • ${event.participantCount} registered'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsScreen(event: event),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Build registrations tab
  Widget _buildRegistrationsTab() {
    return const EventRegistrationsTab();
  }
}
