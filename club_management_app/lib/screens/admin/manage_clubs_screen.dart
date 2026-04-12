import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../core/index.dart';

/// Admin screen to manage all clubs in the system
class ManageClubsScreen extends StatefulWidget {
  const ManageClubsScreen({Key? key}) : super(key: key);

  @override
  State<ManageClubsScreen> createState() => _ManageClubsScreenState();
}

class _ManageClubsScreenState extends State<ManageClubsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter clubs based on search
  List<dynamic> _filterClubs(List<dynamic> clubs) {
    if (_searchQuery.isEmpty) return clubs;

    return clubs
        .where((club) =>
            club.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            club.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Clubs'),
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

          // Clubs list
          Expanded(
            child: Consumer<ClubProvider>(
              builder: (context, clubProvider, _) {
                if (clubProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredClubs = _filterClubs(clubProvider.clubs);

                if (filteredClubs.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.groups,
                    title: _searchQuery.isEmpty
                        ? 'No clubs yet'
                        : 'No clubs found',
                    subtitle: _searchQuery.isEmpty
                        ? 'Create your first club'
                        : 'Try different search terms',
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
                        leading: CircleAvatar(
                          child: Text(club.name[0]),
                        ),
                        title: Text(club.name),
                        subtitle: Text(club.description),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/create-club');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
