import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEventCard(
            title: 'Tech Talk',
            date: 'April 15, 2026',
            location: 'Auditorium',
          ),
          _buildEventCard(
            title: 'Sports Day',
            date: 'April 20, 2026',
            location: 'Sports Ground',
          ),
          _buildEventCard(
            title: 'Cultural Fest',
            date: 'April 25, 2026',
            location: 'Main Hall',
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String date,
    required String location,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(date),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Text(location),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
