import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? event;
  bool loading = true;
  bool applying = false;
  String? appliedStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final eventId = ModalRoute.of(context)!.settings.arguments;

    if (event == null && eventId != null) {
      _loadEvent(eventId.toString());
    }
  }

  Future<void> _loadEvent(String id) async {
    try {
      final data = await ApiService.getEvent(id);
      final e = Event.fromJson(data);

      if (mounted) {
        setState(() {
          event = e;
          loading = false;
        });

        _checkStatus();
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _checkStatus() async {
    if (event == null) return;

    try {
      final regs = await ApiService.getMyEvents();

      final match = regs.firstWhere(
        (r) => (r as Map)['event']['id'] == event!.id,
        orElse: () => null,
      );

      if (mounted && match != null) {
        setState(() {
          appliedStatus = (match as Map)['status'];
        });
      }
    } catch (_) {}
  }

  Future<void> _apply() async {
    if (event == null) return;

    setState(() => applying = true);

    try {
      await ApiService.applyForEvent(event!.id);

      if (mounted) {
        setState(() => appliedStatus = 'pending');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applied successfully')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error applying')),
      );
    } finally {
      if (mounted) setState(() => applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (event == null) {
      return const Scaffold(
        body: Center(child: Text("Event not found")),
      );
    }

    final e = event!;

    return Scaffold(
      appBar: AppBar(title: Text(e.title)),
      body: ListView(
        children: [
          if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
            Image.network(
              e.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusChip(e.status),
                    const Spacer(),
                    if (e.capacity > 0)
                      Text(
                        '${e.registeredCount}/${e.capacity} seats',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  e.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.group,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(e.clubName,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${e.eventDate.day}/${e.eventDate.month}/${e.eventDate.year}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'About',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  e.description.isEmpty
                      ? 'No description provided.'
                      : e.description,
                  style:
                      const TextStyle(color: Colors.black87, height: 1.5),
                ),

                const SizedBox(height: 30),

                // STATUS SECTION
                if (auth.isStudent) ...[
                  if (appliedStatus != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _statusColor(appliedStatus!)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _statusColor(appliedStatus!)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        appliedStatus == 'approved'
                            ? 'Applied'
                            : appliedStatus == 'pending'
                                ? 'Application pending'
                                : 'Application $appliedStatus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _statusColor(appliedStatus!),
                        ),
                      ),
                    )
                  else if (e.isFull)
                    const Center(
                      child: Text(
                        'Event is full',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: applying ? null : _apply,
                        icon: applying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.how_to_reg),
                        label: Text(
                            applying ? 'Applying…' : 'Apply for Event'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final c = _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'approved' => Colors.green,
        'rejected' => Colors.red,
        'completed' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.blue,
      };
}