import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../models/index.dart';

/// Club details screen with browse and join functionality
class ClubDetailsScreen extends StatefulWidget {
  final Club club;

  const ClubDetailsScreen({Key? key, required this.club}) : super(key: key);

  @override
  State<ClubDetailsScreen> createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  late Club _currentClub;
  String? _userRequestStatus; // pending, approved, rejected, null
  List<Event> _clubEvents = [];
  bool _isLoadingEvents = false;

  @override
  void initState() {
    super.initState();
    _currentClub = widget.club;
    _checkJoinStatus();
    _loadClubEvents();
  }

  /// Check if user has already sent a join request
  void _checkJoinStatus() {
    final joinRequestProvider = context.read<JoinRequestProvider>();
    _userRequestStatus =
        joinRequestProvider.getUserRequestStatus(_currentClub.id);
  }

  /// Load events for this club
  Future<void> _loadClubEvents() async {
    setState(() => _isLoadingEvents = true);
    final eventProvider = context.read<EventProvider>();

    try {
      // Fetch all events (API already filters by clubId if needed)
      await eventProvider.fetchEvents(clubId: _currentClub.id);
      // Get events for this club
      setState(() {
        _clubEvents = eventProvider.events;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e')),
      );
    } finally {
      setState(() => _isLoadingEvents = false);
    }
  }

  /// Handle join request
  Future<void> _handleJoinRequest() async {
    final joinRequestProvider = context.read<JoinRequestProvider>();

    try {
      await joinRequestProvider.sendJoinRequest(_currentClub.id);
      if (!mounted) return;

      setState(() => _userRequestStatus = 'pending');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club name
            Text(
              _currentClub.name,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Pending requests badge
            if (_currentClub.pendingRequests > 0)
              Chip(
                label: Text('${_currentClub.pendingRequests} pending'),
                backgroundColor: Colors.orange[100],
              ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
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
                _currentClub.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),

            // Join button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _userRequestStatus == null ? _handleJoinRequest : null,
                child: Text(
                  _userRequestStatus == null
                      ? 'Send Join Request'
                      : 'Request ${_userRequestStatus!.toUpperCase()}',
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Upcoming events
            Text(
              'Upcoming Events',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingEvents)
              const Center(child: CircularProgressIndicator())
            else if (_clubEvents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No events scheduled',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _clubEvents.length,
                itemBuilder: (context, index) {
                  final event = _clubEvents[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(event.title),
                      subtitle: Text(_formatDate(event.eventDate)),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // Navigate to event details
                      },
                    ),
                  );
                },
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
