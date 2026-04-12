import 'package:flutter/material.dart';
import '../../core/index.dart';

/// Admin screen to manage all users in the system
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;
  late List<Map<String, dynamic>> _users;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeUsers();
  }

  /// Initialize sample users data
  void _initializeUsers() {
    _users = [
      {
        'id': '1',
        'name': 'Aarav Singh',
        'email': 'aarav@example.com',
        'role': 'student',
        'status': 'active'
      },
      {
        'id': '2',
        'name': 'Priya Sharma',
        'email': 'priya@example.com',
        'role': 'club_head',
        'status': 'active'
      },
      {
        'id': '3',
        'name': 'Admin',
        'email': 'admin@example.com',
        'role': 'admin',
        'status': 'active'
      },
      {
        'id': '4',
        'name': 'Rohit Kumar',
        'email': 'rohit@example.com',
        'role': 'student',
        'status': 'inactive'
      },
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Filter users based on search and role
  List<Map<String, dynamic>> _filterUsers(String roleFilter) {
    var filtered = _users.where((user) => user['role'] == roleFilter).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((user) =>
              user['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user['email'].toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Students'),
            Tab(text: 'Club Heads'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('student'),
                _buildUserList('club_head'),
                _buildUserList('admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build user list for a specific role
  Widget _buildUserList(String role) {
    final filteredUsers = _filterUsers(role);

    if (filteredUsers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.person_outline,
        title: 'No users',
        subtitle: 'No ${role.replaceAll('_', ' ')}s found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user['name'][0]),
            ),
            title: Text(user['name']),
            subtitle: Text(user['email']),
            trailing: Chip(
              label: Text(user['status']),
              backgroundColor: user['status'] == 'active'
                  ? Colors.green[100]
                  : Colors.grey[300],
            ),
            onTap: () {
              // Show user details dialog
              _showUserDetails(context, user);
            },
          ),
        );
      },
    );
  }

  /// Show user details dialog
  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user['email']}'),
            const SizedBox(height: 8),
            Text('Role: ${user['role']}'),
            const SizedBox(height: 8),
            Text('Status: ${user['status']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
