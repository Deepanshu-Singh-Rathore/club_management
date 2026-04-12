import 'user.dart';

/// Auth response model with tokens and user data
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String role;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access'] as String? ?? '',
      refreshToken: json['refresh'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}
