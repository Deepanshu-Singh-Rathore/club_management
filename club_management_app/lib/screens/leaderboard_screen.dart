import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getLeaderboard();
      if (mounted) setState(() { _entries = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Split into top-3 and rest
    final top3 = _entries.take(3).toList();
    final rest = _entries.skip(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEDF1FE),
      appBar: AppBar(
        title: const Text("Leaderboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF)))
          : _entries.isEmpty
              ? const Center(child: Text("No data yet", style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    // Top 3 podium
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _buildPodium(top3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: rest.length,
                          itemBuilder: (context, i) {
                            final entry = rest[i];
                            return _listParticipant(
                              entry['full_name'] as String,
                              entry['points'].toString(),
                              entry['rank'].toString(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildPodium(List<dynamic> top3) {
    if (top3.isEmpty) return [];

    // Order: rank2 (left), rank1 (center), rank3 (right)
    const colors = [Color(0xFF4A6CF7), Color(0xFF7B61FF), Color(0xFFF557FA)];
    final order = top3.length == 1
        ? [top3[0]]
        : top3.length == 2
            ? [top3[1], top3[0]]
            : [top3[1], top3[0], top3[2]];
    final isFirstFlags = top3.length == 1
        ? [true]
        : top3.length == 2
            ? [false, true]
            : [false, true, false];

    return List.generate(order.length, (i) {
      final e = order[i];
      final isFirst = isFirstFlags[i];
      return _topWinner(
        e['full_name'] as String,
        e['points'].toString(),
        colors[i % colors.length],
        isFirst,
      );
    });
  }

  Widget _topWinner(String name, String pts, Color color, bool isFirst) {
    return Column(
      children: [
        if (isFirst) const Icon(Icons.emoji_events, color: Colors.amber, size: 45),
        const SizedBox(height: 5),
        CircleAvatar(
          radius: isFirst ? 50 : 40,
          backgroundColor: color.withOpacity(0.15),
          child: CircleAvatar(
            radius: isFirst ? 42 : 32,
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: isFirst ? 30 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
          style: const TextStyle(color: Color(0xFF4A6CF7), fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
