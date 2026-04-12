import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../core/index.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load initial data
  Future<void> _loadData() async {
    final clubProvider = context.read<ClubProvider>();
    final eventProvider = context.read<EventProvider>();

    try {
      await Future.wait([
        clubProvider.fetchClubs(),
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
        title: const Text('Admin Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Text(
                    '${authProvider.currentUser?.fullName ?? "Admin"}',
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
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Leaderboard',
          ),
        ],
      ),
    );
  }

  /// Build drawer
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
                    (authProvider.currentUser?.fullName ?? 'A')[0],
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
            leading: const Icon(Icons.add_circle),
            title: const Text('Create Club'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to create club screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add User'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to add user screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
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

  /// Build body
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildClubsTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildEventsTab();
      case 3:
        return _buildLeaderboardTab();
      default:
        return _buildClubsTab();
    }
  }

  /// Build clubs tab
  Widget _buildClubsTab() {
    return Consumer<ClubProvider>(
      builder: (context, clubProvider, _) {
        if (clubProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (clubProvider.clubs.isEmpty) {
          return Center(
            child: Text(
              'No clubs',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clubProvider.clubs.length,
          itemBuilder: (context, index) {
            final club = clubProvider.clubs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(club.name),
                subtitle: Text(club.description),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  // Navigate to club details
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Build users tab
  Widget _buildUsersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'User management features coming soon',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
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
              'No events',
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
                subtitle: Text('Club: ${event.clubName}'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  // Navigate to event details
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Build leaderboard tab
  Widget _buildLeaderboardTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Leaderboard feature coming soon',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
