/// JoinRequest model for club membership requests
class JoinRequest {
  final String id;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? club;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  JoinRequest({
    required this.id,
    this.user,
    this.club,
    required this.status,
    required this.createdAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'] as String,
      user: json['user'] as Map<String, dynamic>?,
      club: json['club'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'club': club,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
