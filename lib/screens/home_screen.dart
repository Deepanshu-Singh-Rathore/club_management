import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. NEW TOP HEADER (Removed Name, Added Circle Logo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)], // Theme Blue
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                // User name hat gaya, ab sirf ye branding circle hai
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    // Aapka ClubSphere logo yahan aayega
                    backgroundImage: const AssetImage("assets/images/logo.png"),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. CATEGORY ICONS (Clubs, Events, etc.)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavIcon(Icons.groups_outlined, "Clubs"),
                  _buildNavIcon(Icons.calendar_month_outlined, "Events"),
                  _buildNavIcon(Icons.bar_chart_outlined, "Stats"),
                  _buildNavIcon(Icons.store_outlined, "Store"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. MY CLUBS SECTION
            _buildSectionHeader("My Clubs"),
            _buildClubItem("Robotics Club", "42 Members", Colors.blue.shade300),
            _buildClubItem(
                "Drama Society", "27 Members", Colors.purple.shade300),

            const SizedBox(height: 25),

            // 4. RECENT ACTIVITY SECTION
            _buildSectionHeader("Recent Activity"),
            _buildActivityItem(Icons.check_circle, "Application Approved",
                "2 hrs ago", Colors.green),
            _buildActivityItem(
                Icons.stars, "+50 Points Earned", "Yesterday", Colors.amber),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Reusable Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0) // Matches Signup Blue
              ),
        ),
      ),
    );
  }

  // Category Icon Builder
  Widget _buildNavIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1565C0), size: 28),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  // Club Item Builder
  Widget _buildClubItem(String name, String members, Color iconColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: CircleAvatar(backgroundColor: iconColor, radius: 20),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(members, style: const TextStyle(fontSize: 12)),
      trailing: const Text("Member",
          style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
    );
  }

  // Activity Item Builder
  Widget _buildActivityItem(
      IconData icon, String title, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(time,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
