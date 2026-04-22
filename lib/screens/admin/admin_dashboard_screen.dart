import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<User> _users = [];
  List<User> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getAdminUsers();
      if (mounted) {
        setState(() {
          _users =
              raw.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
          _filtered = _users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users
              .where((u) =>
                  u.displayName.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _changeRole(User user, String newRole) async {
    try {
      await ApiService.updateUserRole(user.id, newRole);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} is now $newRole')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deactivate(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Deactivate ${user.displayName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.deactivateUser(user.id);
        _load();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showRoleDialog(User user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change role for ${user.displayName}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...['student', 'club_head', 'admin'].map((role) => ListTile(
                  leading: Icon(_roleIcon(role)),
                  title: Text(_roleLabel(role)),
                  trailing: user.role == role
                      ? const Icon(Icons.check, color: Color(0xFF0D47A1))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (user.role != role) _changeRole(user, role);
                  },
                )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Deactivate Account',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deactivate(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${_filtered.length} users',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final u = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _roleColor(u.role).withValues(
                                  alpha: 0.15), // FIX: withValues use kiya
                              child: Text(
                                u.displayName[0].toUpperCase(),
                                style: TextStyle(
                                    color: _roleColor(u.role),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(u.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.email,
                                    style: const TextStyle(fontSize: 12)),
                                Row(children: [
                                  _roleBadge(u.role),
                                  const SizedBox(width: 8),
                                  Text('${u.points} pts',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                ]),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showRoleDialog(u),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    final c = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12), // FIX: withValues use kiya
          borderRadius: BorderRadius.circular(20)),
      child: Text(_roleLabel(role), style: TextStyle(color: c, fontSize: 11)),
    );
  }

  Color _roleColor(String r) => switch (r) {
        'admin' => Colors.red,
        'club_head' => Colors.purple,
        _ => Colors.blue,
      };

  String _roleLabel(String r) => switch (r) {
        'admin' => 'Admin',
        'club_head' => 'Club Head',
        _ => 'Student',
      };

  IconData _roleIcon(String r) => switch (r) {
        'admin' => Icons.shield,
        'club_head' => Icons.manage_accounts,
        _ => Icons.person,
      };
}
