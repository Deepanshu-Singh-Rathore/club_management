import 'event.dart';
import 'user.dart';

class EventRegistration {
  final String id;
  final User user;
  final Event? event;
  final String status; // pending | approved | rejected
  final String ticketId;
  final String attendanceStatus; // registered | checked_in | cancelled
  final DateTime? attendedAt;
  final DateTime createdAt;

  const EventRegistration({
    required this.id,
    required this.user,
    this.event,
    required this.status,
    this.ticketId = '',
    this.attendanceStatus = 'registered',
    this.attendedAt,
    required this.createdAt,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> j) =>
      EventRegistration(
        id: j['id'] as String,
        user: j['user'] != null
            ? User.fromJson(j['user'] as Map<String, dynamic>)
            : const User(id: '', fullName: 'Member', email: '', role: 'student', points: 0, isVerified: true),
        event: j['event'] != null ? Event.fromJson(j['event'] as Map<String, dynamic>) : null,
        status: (j['status'] as String?) ?? 'pending',
        ticketId: (j['ticket_id'] as String?) ?? '',
        attendanceStatus: (j['attendance_status'] as String?) ?? 'registered',
        attendedAt: j['attended_at'] != null ? DateTime.tryParse(j['attended_at'] as String) : null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isCheckedIn => attendanceStatus.toLowerCase() == 'checked_in';
}
