/// App-wide constants
class AppConstants {
  // Backend URL - adjust based on your environment
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // For iOS simulator: 'http://127.0.0.1:8000/api'
  // For real device: 'http://192.168.x.x:8000/api'
  // For web: 'http://localhost:8000/api'

  // Roles
  static const String roleStudent = 'student';
  static const String roleClubHead = 'club_head';
  static const String roleAdmin = 'admin';

  // API Endpoints
  static const String endpointRegister = '/register/';
  static const String endpointLogin = '/login/';
  static const String endpointProfile = '/me/';
  static const String endpointRefresh = '/refresh/';
  static const String endpointLeaderboard = '/leaderboard/';

  static const String endpointClubs = '/clubs/';
  static const String endpointJoinRequests = '/join-requests/';
  static const String endpointEvents = '/events/';

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
}

/// App colors matching design requirements
class AppColors {
  static const int primaryColor = 0xFF1565C0;
  static const int accentColor = 0xFF7B61FF;
  static const int backgroundColor = 0xFFEDF1FE;
  static const int textDark = 0xFF1F2937;
  static const int textLight = 0xFF6B7280;
  static const int borderColor = 0xFFE5E7EB;
  static const int successColor = 0xFF10B981;
  static const int errorColor = 0xFFEF4444;
  static const int warningColor = 0xFFF59E0B;
}
