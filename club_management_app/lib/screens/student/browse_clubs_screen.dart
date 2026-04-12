import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../models/index.dart';
import 'club_details_screen.dart';

/// Browse and search clubs screen with filtering
class BrowseClubsScreen extends StatefulWidget {
  const BrowseClubsScreen({Key? key}) : super(key: key);

  @override
  State<BrowseClubsScreen> createState() => _BrowseClubsScreenState();
}

class _BrowseClubsScreenState extends State<BrowseClubsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyJoined = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter clubs based on search and filters
  List<Club> _filterClubs(List<Club> clubs) {
    var filtered = clubs;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((club) =>
              club.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              club.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by pending requests (recently active first)
    filtered.sort((a, b) => b.pendingRequests.compareTo(a.pendingRequests));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Clubs'),
        elevation: 0,
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
                hintText: 'Search clubs...',
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

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All Clubs'),
                  selected: !_showOnlyJoined,
                  onSelected: (selected) {
                    setState(() => _showOnlyJoined = false);
                  },
                ),
                FilterChip(
                  label: const Text('Popular'),
                  selected: false,
                  onSelected: (selected) {
                    // Sort by pending requests
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Clubs list
          Expanded(
            child: Consumer<ClubProvider>(
              builder: (context, clubProvider, _) {
                if (clubProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredClubs = _filterClubs(clubProvider.clubs);

                if (filteredClubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No clubs available'
                              : 'No clubs matching "$_searchQuery"',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredClubs.length,
                  itemBuilder: (context, index) {
                    final club = filteredClubs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(club.name),
                        subtitle: Text(club.description),
                        trailing: club.pendingRequests > 0
                            ? Chip(
                                label: Text('${club.pendingRequests}'),
                                backgroundColor: Colors.orange[100],
                              )
                            : const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ClubDetailsScreen(club: club),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
