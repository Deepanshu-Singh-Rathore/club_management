import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String selectedFilter = 'All';

  final List<Map<String, dynamic>> allEvents = [
    {
      'title': 'Tech Fest 2026',
      'club': 'Robotics Club',
      'date': '18 May, 2026',
      'location': 'Main Auditorium',
      'attendees': '42',
      'status': 'Apply',
      'color': Colors.orange,
    },
    {
      'title': 'Annual Sports Meet',
      'club': 'Sports Club',
      'date': '22 April, 2026',
      'location': 'College Ground',
      'attendees': '85',
      'status': 'Applied',
      'color': Color(0xFF1565C0), // Theme blue
    },
    {
      'title': 'Coding Marathon',
      'club': 'Coding Club',
      'date': '28 April, 2026',
      'location': 'IT Block',
      'attendees': '120',
      'status': 'Applied',
      'color': Color(0xFF1565C0),
    },
    {
      'title': 'Code Combat',
      'club': 'Coding Club',
      'date': '10 January, 2026',
      'location': 'Lab Block',
      'attendees': '150',
      'status': 'Past',
      'color': Colors.grey,
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedEvents = allEvents.where((event) {
      if (selectedFilter == 'All') return true;
      return event['status'] == selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Light background theme match
      body: Column(
        children: [
          // 1. TOP HEADER (Blue Gradient)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFADCFFF), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Events',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Filter Tabs (Inside Header)
                Row(
                  children: ['All', 'Applied', 'Past'].map((tab) {
                    bool isSelected = selectedFilter == tab;
                    return GestureDetector(
                      onTap: () => setState(() => selectedFilter = tab),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 2. EVENTS LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayedEvents.length,
              itemBuilder: (context, index) {
                return _buildEventCard(displayedEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    Text(
                      event['club'],
                      style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (event['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  event['status'],
                  style: TextStyle(
                      color: event['color'],
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconDetail(Icons.calendar_today, event['date']),
              _iconDetail(Icons.location_on_outlined, event['location']),
              _iconDetail(Icons.people_outline, event['attendees']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
