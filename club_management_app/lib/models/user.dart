class User {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? rollNumber;
  final String role; // student | club_head | admin
  final int points;
  final bool isVerified;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.rollNumber,
    required this.role,
    required this.points,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        fullName: (j['full_name'] as String?) ?? '',
        email: j['email'] as String,
        phoneNumber: j['phone_number'] as String?,
        rollNumber: j['roll_number'] as String?,
        role: (j['role'] as String?) ?? 'student',
        points: (j['points'] as int?) ?? 0,
        isVerified: (j['is_verified'] as bool?) ?? false,
      );

  String get displayName => fullName.isNotEmpty ? fullName : email.split('@').first;

  bool get isAdmin => role == 'admin';
  bool get isClubHead => role == 'club_head';
  bool get isStudent => role == 'student';
}