/// User model matching backend User schema
class User {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? rollNumber;
  final String role; // 'student', 'club_head', 'admin'
  final int points;
  final bool isVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.rollNumber,
    required this.role,
    required this.points,
    required this.isVerified,
    required this.createdAt,
  });

  /// Parse JSON response from backend
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      rollNumber: json['roll_number'] as String?,
      role: json['role'] as String? ?? 'student',
      points: json['points'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for backend requests
  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'roll_number': rollNumber,
        'role': role,
        'points': points,
        'is_verified': isVerified,
        'created_at': createdAt.toIso8601String(),
      };
}
