import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background: Brilliant White
      backgroundColor: const Color(0xFFEDF1FE), 
      appBar: AppBar(
        title: const Text("Leaderboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, // Background se match karne ke liye
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Top 3 Section (Taniya, Tanisha, Tamanna)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _topWinner("Tanisha", "3800", const Color(0xFF4A6CF7), false), // Rank 2
                _topWinner("Taniya", "3900", const Color(0xFF7B61FF), true),  // Rank 1
                _topWinner("Tamanna", "3500", const Color(0xFFF557FA), false), // Rank 3
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Remaining List Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Colors.white, // Bottom sheet effect
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Deepanshu aur Vineet
                  _listParticipant("Deepanshu", "3080", "4"),
                  _listParticipant("Vineet", "2950", "5"),
                  // Aap aur entries bhi add kar sakte hain
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topWinner(String name, String pts, Color color, bool isFirst) {
    return Column(
      children: [
        if (isFirst) 
          const Icon(Icons.emoji_events, color: Colors.amber, size: 45), // Gold Trophy
        const SizedBox(height: 5),
        CircleAvatar(
          radius: isFirst ? 50 : 40,
          backgroundColor: color.withOpacity(0.15),
          child: CircleAvatar(
            radius: isFirst ? 42 : 32,
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              name[0], 
              style: TextStyle(fontSize: isFirst ? 30 : 24, fontWeight: FontWeight.bold, color: color)
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text("$pts pts", style: const TextStyle(color: Color(0xFF7B61FF), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _listParticipant(String name, String pts, String rank) {
    return Card(
      // Glistening White card
      color: const Color(0xFFF4F4EC), 
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text("#$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          "$pts pts", 
          style: const TextStyle(color: Color(0xFF4A6CF7), fontWeight: FontWeight.bold, fontSize: 15)
        ),
      ),
    );
  }
}