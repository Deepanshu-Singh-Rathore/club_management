import 'package:flutter/material.dart';

// Blue shades and font styles from your design
const Color primaryBlue = Color(0xFF1565C0);
const Color backgroundLight = Color(0xFFE3F2FD);
const Color iconBackground = Color(0xFFD6E9FC);
const TextStyle labelStyle = TextStyle(
  color: primaryBlue,
  fontWeight: FontWeight.bold,
  fontSize: 13,
);
const TextStyle headerStyle = TextStyle(
  color: primaryBlue,
  fontWeight: FontWeight.w900,
  fontSize: 32,
);
const TextStyle subheaderStyle = TextStyle(
  color: primaryBlue,
  fontWeight: FontWeight.bold,
  fontSize: 22,
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundLight,
        fontFamily: 'Segoe UI', // Adjust based on your availability
      ),
      home: const MainLayout(),
    );
  }
}

// MAIN LAYOUT with Bottom Navigation
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Placeholder screens for other tabs
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text("Events Screen")),
    const Center(child: Text("Members Screen")),
    const Center(child: Text("More Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Events",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Members",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
        ],
      ),
    );
  }
}

// HOME SCREEN with Scroll and Flex fixes
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SingleChildScrollView(
          // --- FIX: Scroll added to entire content ---
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Header
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // Ensure this path is correct
                      height: 100,
                    ),
                    const SizedBox(height: 10),
                    const Text("ClubSphere", style: headerStyle),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Menu Cards (Grid of 4)
              // --- FIX: Row and Column with Flex widgets to handle sizes ---
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuCard(Icons.event_note, "Events"),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildMenuCard(
                          Icons.menu_book_rounded,
                          "Resources",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuCard(
                          Icons.chat_bubble_outline_rounded,
                          "Discussion",
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildMenuCard(
                          Icons.verified_user_outlined,
                          "Notifications",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Quick Actions Subheader
              const Text("Quick Actions", style: subheaderStyle),
              const SizedBox(height: 15),

              // Quick Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(Icons.add_box, "New Event", true),
                  _buildQuickAction(Icons.campaign, "Announce...", false),
                  _buildQuickAction(
                    Icons.person_add_alt_1,
                    "Add Member",
                    false,
                  ),
                  _buildQuickAction(Icons.handshake, "Collaboration", false),
                ],
              ),
              const SizedBox(height: 30), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  // --- FIX: Menu Cards now take full space using Expanded ---
  Widget _buildMenuCard(IconData icon, String title) {
    return AspectRatio(
      // Ensures cards stay square
      aspectRatio: 1.1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackground,
              ),
              child: Icon(icon, color: primaryBlue, size: 30),
            ),
            const SizedBox(height: 10),
            Text(title, style: labelStyle),
          ],
        ),
      ),
    );
  }

  // --- FIX: Quick Action labels handled with TextOverflow.ellipsis ---
  Widget _buildQuickAction(IconData icon, String label, bool isPrimary) {
    return Flexible(
      // Allows width adjustment
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPrimary ? primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Icon(icon, color: isPrimary ? Colors.white : primaryBlue),
          ),
          const SizedBox(height: 5),
          SizedBox(
            // Constraints for text
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // ... handling for long text
              style: TextStyle(
                fontSize: 11,
                color: isPrimary ? primaryBlue : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(String imageUrl, String title) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCF6),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
        image:
            DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25)),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.5), Colors.transparent],
          ),
        ),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }

  Widget _staticEventCard(String imageUrl, String title) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [_eventCard(imageUrl, title)],
    );
  }
}
