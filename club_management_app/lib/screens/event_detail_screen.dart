import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() =>
      _EventDetailScreenState();
}

class _EventDetailScreenState
    extends State<EventDetailScreen> {

  Event? event;
  bool loading = true;
  bool applying = false;
  String? appliedStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final eventId =
        ModalRoute.of(context)!.settings.arguments;

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
    } catch (e) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(event?.title ?? "Event Detail"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? const Center(child: Text("Event not found"))
              : ListView(
                  children: [
                    if (event!.imageUrl != null &&
                        event!.imageUrl!.isNotEmpty)
                      Image.network(
                        event!.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(event!.title,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),

                          const SizedBox(height: 10),

                          Text(event!.description),

                          const SizedBox(height: 10),

                          Text(
                              "Date: ${event!.eventDate.day}/${event!.eventDate.month}/${event!.eventDate.year}"),

                          const SizedBox(height: 20),

                          if (auth.isStudent) ...[
                            if (appliedStatus != null)
                              Text(
                                "Status: $appliedStatus",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )
                            else if (event!.isFull)
                              const Text("Event Full",
                                  style:
                                      TextStyle(color: Colors.red))
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      applying ? null : _apply,
                                  child: Text(applying
                                      ? "Applying..."
                                      : "Apply"),
                                ),
                              )
                          ]
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}