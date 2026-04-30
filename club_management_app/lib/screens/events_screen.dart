import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'clubhead/pending_approvals_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> _events = [];
  bool _loading = true;
  String _filter = 'upcoming'; // upcoming | completed | all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getEvents();
      if (mounted) {
        setState(() {
          _events = raw
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Event> get _visible {
  final sorted = [..._events];
  sorted.sort((a, b) => a.eventDate.compareTo(b.eventDate));

  if (_filter == 'all') return sorted;
  return sorted.where((e) => e.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['upcoming', 'completed', 'all'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f[0].toUpperCase() + f.substring(1)),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor:
                        const Color(0xFF0D47A1).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF0D47A1),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _visible.isEmpty
                        ? const Center(
                            child: Text('No events found',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _visible.length,
                            itemBuilder: (_, i) {
                              final ev = _visible[i];

                              return _EventCard(
                                event: ev,

                                // ✅ FIXED NAVIGATION
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/event-detail',
                                    arguments: ev.id,
                                  );
                                },

                                onManage: (auth.isAdmin ||
                                        auth.isClubHead)
                                    ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PendingApprovalsScreen(
                                                    event: ev),
                                          ),
                                        )
                                    : null,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onManage;

  const _EventCard({
    required this.event,
    required this.onTap,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
              Image.network(
                e.imageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox.shrink(),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        e.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                    _statusChip(e.status),
                  ]),

                  const SizedBox(height: 6),

                  Row(children: [
                    const Icon(Icons.group,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      e.clubName,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${e.eventDate.day}/${e.eventDate.month}/${e.eventDate.year}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ]),

                  if (e.capacity > 0) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: e.capacity > 0
                          ? e.registeredCount / e.capacity
                          : 0,
                      backgroundColor: Colors.grey.shade200,
                      color: e.isFull
                          ? Colors.red
                          : const Color(0xFF0D47A1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${e.registeredCount}/${e.capacity} seats',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                  ],

                  if (onManage != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: onManage,
                      icon: const Icon(Icons.pending_actions,
                          size: 16),
                      label:
                          const Text('Manage Registrations'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle:
                            const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final colors = {
      'upcoming': Colors.blue,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };

    final c = colors[status] ?? Colors.grey;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 11),
      ),
    );
  }
}