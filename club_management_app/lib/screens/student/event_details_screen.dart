import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../models/index.dart';

/// Event details screen with registration and participant viewing
class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Event _currentEvent;
  bool _isRegistered = false;
  List<EventRegistration>? _participants;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _checkRegistration();
  }

  /// Check if user is already registered
  void _checkRegistration() {
    // Implementation would check user's registrations
    _isRegistered = false;
  }

  /// Handle event registration
  Future<void> _handleRegister() async {
    final eventProvider = context.read<EventProvider>();

    try {
      await eventProvider.registerForEvent(_currentEvent.id);
      if (!mounted) return;

      setState(() => _isRegistered = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully registered for event!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  /// Load participants (club head only)
  Future<void> _loadParticipants() async {
    final eventProvider = context.read<EventProvider>();

    try {
      _participants =
          await eventProvider.getEventParticipants(_currentEvent.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load participants: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isClubHead = authProvider.isClubHead;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event title
            Text(
              _currentEvent.title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Club name
            Text(
              'Club: ${_currentEvent.clubName}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Event date and time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF1565C0)),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_currentEvent.eventDate),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.people, color: Color(0xFF1565C0)),
                        const SizedBox(width: 12),
                        Text(
                          '${_currentEvent.participantCount} registered',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentEvent.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            if (!isClubHead)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRegistered ? null : _handleRegister,
                  child:
                      Text(_isRegistered ? 'Already Registered' : 'Register'),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadParticipants,
                      icon: const Icon(Icons.group),
                      label: const Text('View Participants'),
                    ),
                  ),
                  if (_participants != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Participants (${_participants!.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ..._participants!.map((reg) => ListTile(
                          title: Text(reg.user?['full_name'] ?? 'Unknown User'),
                          subtitle: Text(reg.user?['email'] ?? 'No email'),
                          leading: CircleAvatar(
                            child: Text((reg.user?['full_name'] ?? 'U')[0]),
                          ),
                        )),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
