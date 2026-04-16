class AppNotification {
  final int id;
  final String message;
  final String type; // apply | approved | rejected
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int,
        message: j['message'] as String,
        type: (j['type'] as String?) ?? 'apply',
        isRead: (j['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
