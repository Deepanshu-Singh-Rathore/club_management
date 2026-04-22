import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Light background theme
      body: Column(
        children: [
          // Blue Gradient Header (Signup theme match)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFADCFFF), Color(0xFF1565C0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Center(
              child: Text(
                "More Options",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionLabel("PREFERENCES"),
                _buildMoreItem(
                    Icons.notifications_none, "Notifications", () {}),
                _buildMoreItem(Icons.language, "App Language", () {},
                    trailing: "English"),
                const SizedBox(height: 25),
                _buildSectionLabel("SUPPORT & LEGAL"),
                _buildMoreItem(Icons.help_outline, "Help & Support", () {}),
                _buildMoreItem(
                    Icons.bug_report_outlined, "Report a Bug", () {}),
                _buildMoreItem(
                    Icons.privacy_tip_outlined, "Privacy Policy", () {}),
                _buildMoreItem(Icons.info_outline, "About ClubSphere", () {}),
                const SizedBox(height: 25),
                _buildMoreItem(Icons.logout, "Log Out", () {},
                    isDestructive: true),
                const SizedBox(height: 20),
                const Center(
                    child: Text("v1.0.2",
                        style: TextStyle(color: Colors.grey, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFF1565C0),
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMoreItem(IconData icon, String title, VoidCallback onTap,
      {String? trailing, bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            // ERROR FIXED HERE: withOpacity replaced with .withValues
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          )
        ],
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? Colors.red : const Color(0xFF1565C0)),
        title: Text(title,
            style: TextStyle(
                color: isDestructive ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w500)),
        trailing: trailing != null
            ? Text(trailing, style: const TextStyle(color: Colors.grey))
            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
