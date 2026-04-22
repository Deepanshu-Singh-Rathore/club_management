import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB), // Light background for readability
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP HEADER (Gradient Theme Match)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFADCFFF), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white24,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: Text(
                        "AM",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Aryan Mehta",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "Student • Rank #4",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 25),

                  // Stats Inside Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _Stat(val: '3', label: 'Clubs'),
                      _Stat(val: '820', label: 'Points'),
                      _Stat(val: '11', label: 'Events'),
                    ],
                  ),
                ],
              ),
            ),

            // 2. MENU SECTIONS
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _SectionTitle("ACCOUNT"),
                  _MenuCard(
                    children: [
                      _MenuItem(Icons.person_outline, "Edit Profile"),
                      _MenuItem(Icons.lock_outline, "Change Password"),
                      _MenuItem(
                        Icons.phone_android,
                        "WhatsApp Linked",
                        trailing: "+91 987•••210",
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _SectionTitle("MY ACTIVITY"),
                  _MenuCard(
                    children: [
                      _MenuItem(Icons.account_balance_outlined, "My Clubs",
                          trailing: "3 clubs"),
                      _MenuItem(Icons.assignment_outlined, "Applications",
                          trailing: "4 total"),
                      _MenuItem(Icons.star_outline, "Points History",
                          trailing: "820 pts"),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _SectionTitle("MORE"),
                  _MenuCard(
                    children: [
                      _MenuItem(Icons.notifications_none, "Notifications"),
                      _MenuItem(Icons.help_outline, "Help & Support"),
                      _MenuItem(
                        Icons.logout,
                        "Log Out",
                        isDestructive: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Support Widgets (Themed)
class _Stat extends StatelessWidget {
  final String val, label;
  const _Stat({required this.val, required this.label});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1565C0),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      );
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(children: children),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool isDestructive;
  const _MenuItem(this.icon, this.title,
      {this.trailing, this.isDestructive = false});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : const Color(0xFFADCFFF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive ? Colors.red : const Color(0xFF1565C0),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing != null
            ? Text(trailing!,
                style: const TextStyle(color: Colors.grey, fontSize: 13))
            : const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: () {},
      );
}
