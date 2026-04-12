import 'package:flutter/material.dart';

/// Leaderboard display with user rankings
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _leaderboard = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  /// Load leaderboard data
  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    // TODO: Create leaderboardProvider or fetch from API service
    // For now, placeholder data
    _leaderboard = [
      {'rank': 1, 'name': 'Aarav Singh', 'points': 2540, 'clubs': 5},
      {'rank': 2, 'name': 'Priya Sharma', 'points': 2310, 'clubs': 4},
      {'rank': 3, 'name': 'Rohit Kumar', 'points': 2100, 'clubs': 4},
      {'rank': 4, 'name': 'Aditi Gupta', 'points': 1920, 'clubs': 3},
      {'rank': 5, 'name': 'Vikram Patel', 'points': 1850, 'clubs': 3},
      {'rank': 6, 'name': 'Neha Nair', 'points': 1720, 'clubs': 3},
      {'rank': 7, 'name': 'Arjun Desai', 'points': 1660, 'clubs': 2},
      {'rank': 8, 'name': 'Deepa Verma', 'points': 1520, 'clubs': 2},
      {'rank': 9, 'name': 'Karan Mehta', 'points': 1450, 'clubs': 2},
      {'rank': 10, 'name': 'Sana Khan', 'points': 1380, 'clubs': 2},
    ];

    setState(() => _isLoading = false);
  }

  /// Get rank badge color
  Color _getRankBadgeColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400] ?? Colors.grey;
      case 3:
        return Colors.orange[600] ?? Colors.orange;
      default:
        return Colors.grey[300] ?? Colors.grey;
    }
  }

  /// Get rank medal icon
  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.star;
      case 3:
        return Icons.favorite;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with top 3
                if (_leaderboard.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Top Performers',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 24),

                        // Medal podium
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_leaderboard.length >= 2)
                              _buildMedalCard(context, _leaderboard[1], 2),
                            if (_leaderboard.isNotEmpty)
                              _buildMedalCard(context, _leaderboard[0], 1),
                            if (_leaderboard.length >= 3)
                              _buildMedalCard(context, _leaderboard[2], 3),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Remaining leaderboard
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
                    itemBuilder: (context, index) {
                      final item = _leaderboard[index + 3];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${item['rank']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(item['name']),
                            subtitle: Text(
                              '${item['clubs']} clubs',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Text(
                              '${item['points']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1565C0),
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Build medal card for top 3
  Widget _buildMedalCard(
      BuildContext context, Map<String, dynamic> item, int rank) {
    final height = rank == 1
        ? 180.0
        : rank == 2
            ? 140.0
            : 110.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          _getRankIcon(rank),
          size: 32,
          color: _getRankBadgeColor(rank),
        ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 24,
          backgroundColor: _getRankBadgeColor(rank),
          child: Text(
            item['name'][0],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: 80,
          decoration: BoxDecoration(
            color: _getRankBadgeColor(rank).withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${item['points']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
