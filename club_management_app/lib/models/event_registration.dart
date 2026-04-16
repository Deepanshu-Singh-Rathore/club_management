import 'event.dart';
import 'user.dart';

class EventRegistration {
  final String id;
  final User user;
  final Event event;
  final String status; // pending | approved | rejected
  final DateTime createdAt;

  const EventRegistration({
    required this.id,
    required this.user,
    required this.event,
    required this.status,
    required this.createdAt,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> j) =>
      EventRegistration(
        id: j['id'] as String,
        user: User.fromJson(j['user'] as Map<String, dynamic>),
        event: Event.fromJson(j['event'] as Map<String, dynamic>),
        status: (j['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
