import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text = user?.fullName ?? '';
    _phoneCtrl.text = user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    try {
      await ApiService.updateMe({
        'full_name': _nameCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
      });
      await auth.refreshProfile();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout')),
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
    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Edit', style: TextStyle(color: Colors.white)),
            )
          else
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save',
                      style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF0D47A1).withOpacity(0.12),
              child: Text(
                user.displayName[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: _roleBadge(user.role),
          ),
          const SizedBox(height: 24),

          // Points card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Text('${user.points} Points',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Fields
          _sectionLabel('Full Name'),
          const SizedBox(height: 6),
          _editing
              ? TextField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(prefixIcon: Icon(Icons.person)),
                )
              : _infoTile(Icons.person, user.displayName),

          const SizedBox(height: 14),
          _sectionLabel('Email'),
          const SizedBox(height: 6),
          _infoTile(Icons.email, user.email),

          if (user.rollNumber != null && user.rollNumber!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionLabel('Roll Number'),
            const SizedBox(height: 6),
            _infoTile(Icons.badge, user.rollNumber!),
          ],

          const SizedBox(height: 14),
          _sectionLabel('Phone'),
          const SizedBox(height: 6),
          _editing
              ? TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+91 XXXXXXXXXX'),
                )
              : _infoTile(
                  Icons.phone,
                  user.phoneNumber?.isNotEmpty == true
                      ? user.phoneNumber!
                      : 'Not set'),

          if (_editing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel'),
            ),
          ],

          const SizedBox(height: 32),

          // Logout
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) =>
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold));

  Widget _infoTile(IconData icon, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontSize: 15)),
        ]),
      );

  Widget _roleBadge(String role) {
    final colors = {
      'admin': Colors.red,
      'club_head': Colors.purple,
      'student': Colors.blue,
    };
    final labels = {
      'admin': 'Admin',
      'club_head': 'Club Head',
      'student': 'Student',
    };
    final c = colors[role] ?? Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(labels[role] ?? role,
          style: TextStyle(color: c, fontWeight: FontWeight.w600)),
    );
  }
}
