class AppNotification {
  final String id;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? eventId;
  final String? clubId;
  final String? registrationId;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.eventId,
    this.clubId,
    this.registrationId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at'].toString()),
      eventId: json['event_id']?.toString(),
      clubId: json['club_id']?.toString(),
      registrationId: json['registration_id']?.toString(),
    );
  }
}