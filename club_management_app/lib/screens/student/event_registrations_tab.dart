import 'package:flutter/material.dart';

/// Event registrations tab for viewing user's event participations
class EventRegistrationsTab extends StatelessWidget {
  const EventRegistrationsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch user's registrations from EventProvider
    final registrations = []; // Placeholder

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: registrations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No event registrations yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore events and register to get started',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: registrations.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: const Text('Event Title'),
                    subtitle: const Text('Club Name • Status'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Navigate to event details
                    },
                  ),
                );
              },
            ),
    );
  }
}
