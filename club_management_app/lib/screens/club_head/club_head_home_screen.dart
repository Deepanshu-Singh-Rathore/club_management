import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../core/index.dart';
import '../auth/login_screen.dart';

class ClubHeadHomeScreen extends StatefulWidget {
  const ClubHeadHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClubHeadHomeScreen> createState() => _ClubHeadHomeScreenState();
}

class _ClubHeadHomeScreenState extends State<ClubHeadHomeScreen> {
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
        title: const Text('Club Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Text(
                    '${authProvider.currentUser?.fullName ?? "Club Head"}',
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
            label: 'My Clubs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Participants',
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
                    (authProvider.currentUser?.fullName ?? 'C')[0],
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
            title: const Text('Create Event'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to create event screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Manage Clubs'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to manage clubs screen
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
        return _buildRequestsTab();
      case 2:
        return _buildEventsTab();
      case 3:
        return _buildParticipantsTab();
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
              'No clubs assigned',
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

  /// Build requests tab
  Widget _buildRequestsTab() {
    return Consumer<JoinRequestProvider>(
      builder: (context, joinRequestProvider, _) {
        if (joinRequestProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingRequests = joinRequestProvider.pendingRequests;

        if (pendingRequests.isEmpty) {
          return Center(
            child: Text(
              'No pending requests',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingRequests.length,
          itemBuilder: (context, index) {
            final request = pendingRequests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(request.club?['name'] ?? 'Unknown Club'),
                subtitle:
                    Text(request.user?['roll_number'] ?? 'No roll number'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () async {
                        try {
                          await joinRequestProvider
                              .approveJoinRequest(request.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request approved')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () async {
                        try {
                          await joinRequestProvider
                              .rejectJoinRequest(request.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request rejected')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                    ),
                  ],
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
              'No events created',
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
                subtitle: Text('${event.participantCount} participants'),
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

  /// Build participants tab
  Widget _buildParticipantsTab() {
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
            'Select an event to view participants',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
