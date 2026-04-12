/// EventRegistration model for event participation
class EventRegistration {
  final String id;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? event;
  final String status; // 'registered', 'attended'
  final DateTime createdAt;

  EventRegistration({
    required this.id,
    this.user,
    this.event,
    required this.status,
    required this.createdAt,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['id'] as String,
      user: json['user'] as Map<String, dynamic>?,
      event: json['event'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'registered',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'event': event,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
