import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _applying = false;
  String? _appliedStatus;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final regs = await ApiService.getMyEvents();
      // Yahan Iterable par null safety check add kiya gaya hai
      final match = regs.cast<Map?>().firstWhere(
            (r) => r?['event']['id'] == widget.event.id,
            orElse: () => null,
          );
      if (mounted && match != null) {
        setState(() => _appliedStatus = match['status'] as String);
      }
    } catch (_) {}
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await ApiService.applyForEvent(widget.event.id);
      if (mounted) {
        setState(() => _appliedStatus = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final e = widget.event;

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
                // Status chip
                Row(children: [
                  _statusChip(e.status),
                  const Spacer(),
                  if (e.capacity > 0)
                    Text(
                      '${e.registeredCount}/${e.capacity} seats',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ]),
                const SizedBox(height: 14),

                Text(e.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),

                Row(children: [
                  const Icon(Icons.group, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(e.clubName, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${e.eventDate.day}/${e.eventDate.month}/${e.eventDate.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ]),
                const SizedBox(height: 20),

                const Text('About',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  e.description.isEmpty
                      ? 'No description provided.'
                      : e.description,
                  style: const TextStyle(color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 30),

                // Action button
                if (auth.isStudent) ...[
                  if (_appliedStatus != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        // FIX: withValues use kiya gaya hai
                        color: _statusColor(_appliedStatus!)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _statusColor(_appliedStatus!)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_statusIcon(_appliedStatus!),
                              color: _statusColor(_appliedStatus!)),
                          const SizedBox(width: 8),
                          Text(
                            'Application ${_appliedStatus!}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _statusColor(_appliedStatus!)),
                          ),
                        ],
                      ),
                    )
                  else if (e.isFull)
                    const Center(
                      child: Text('Event is full',
                          style: TextStyle(color: Colors.red)),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _applying ? null : _apply,
                        icon: _applying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.how_to_reg),
                        label:
                            Text(_applying ? 'Applying…' : 'Apply for Event'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          // FIX: withValues use kiya gaya hai
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child:
          Text(status, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'approved' => Colors.green,
        'rejected' => Colors.red,
        'completed' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.blue,
      };

  IconData _statusIcon(String s) => switch (s) {
        'approved' => Icons.check_circle,
        'rejected' => Icons.cancel,
        _ => Icons.hourglass_top,
      };
}
