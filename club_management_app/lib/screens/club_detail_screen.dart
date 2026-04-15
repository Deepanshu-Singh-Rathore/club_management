import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/club.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'event_detail_screen.dart';

class ClubDetailScreen extends StatefulWidget {
  final Club club;
  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  List<Event> _events = [];
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final raw = await ApiService.getEvents(clubId: widget.club.id);
      if (mounted) {
        setState(() {
          _events = raw.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await ApiService.joinClub(widget.club.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined ${widget.club.name}!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.club.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Club header card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF0D47A1).withOpacity(0.12),
                      child: Text(
                        widget.club.name[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.club.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${widget.club.memberCount} members',
                            style: const TextStyle(color: Colors.grey)),
                      ]),
                    ),
                  ]),
                  if (widget.club.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(widget.club.description,
                        style: const TextStyle(color: Colors.black87)),
                  ],
                  const SizedBox(height: 16),
                  if (auth.isStudent)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _joining ? null : _join,
                        icon: _joining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.group_add),
                        label: Text(_joining ? 'Joining…' : 'Join Club'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Events in this club
          const Text('Events',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_events.isEmpty)
            const Text('No events for this club yet.',
                style: TextStyle(color: Colors.grey))
          else
            ..._events.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Color(0xFF0D47A1)),
                    title: Text(e.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${e.eventDate.day}/${e.eventDate.month}/${e.eventDate.year}'),
                    trailing: _statusChip(e.status),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EventDetailScreen(event: e)),
                    ),
                  ),
                )),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: c, fontSize: 12)),
    );
  }
}
