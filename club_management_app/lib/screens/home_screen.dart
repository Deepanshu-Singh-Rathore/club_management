import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/club.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Club>> clubs;

  @override
  void initState() {
    super.initState();
    clubs = ApiService.fetchClubs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('College Clubs')),
      body: FutureBuilder<List<Club>>(
        future: clubs,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading clubs'));
          }

          // No Data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No clubs available'));
          }

          // Data Loaded
          final clubList = snapshot.data!;

          return ListView.builder(
            itemCount: clubList.length,
            itemBuilder: (context, index) {
              final club = clubList[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(club.name),
                  subtitle: Text(club.description),
                  leading: const Icon(Icons.groups),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
