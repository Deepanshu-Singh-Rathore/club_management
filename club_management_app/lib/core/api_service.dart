import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import 'constants.dart';

/// Enhanced API service with JWT token support
class ApiService {
  late Dio _dio;
  late SharedPreferences _prefs;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    // Add interceptor to attach JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return _addTokenToRequest(options, handler);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  /// Initialize with SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Add Bearer token to request headers
  void _addTokenToRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = _prefs.getString(AppConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ─── Authentication Endpoints ────────────────────────────────────────

  /// Register new user
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    String rollNumber = '',
    String role = 'student',
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointRegister,
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'roll_number': rollNumber,
          'role': role,
        },
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointLogin,
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile
  Future<User> getProfile() async {
    try {
      final response = await _dio.get(AppConstants.endpointProfile);
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh access token
  Future<void> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointRefresh,
        data: {'refresh': refreshToken},
      );
      final newToken = response.data['access'];
      await _prefs.setString(AppConstants.keyAccessToken, newToken);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Club Endpoints ──────────────────────────────────────────────────

  /// Get all clubs
  Future<List<Club>> getClubs() async {
    try {
      final response = await _dio.get(AppConstants.endpointClubs);
      final clubsData = response.data as List;
      return clubsData
          .map((c) => Club.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get single club
  Future<Club> getClub(String clubId) async {
    try {
      final response = await _dio.get('${AppConstants.endpointClubs}$clubId/');
      return Club.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create new club (admin only)
  Future<Club> createClub({
    required String name,
    required String description,
    String? createdByClubHeadId,
  }) async {
    try {
      final data = {
        'name': name,
        'description': description,
      };
      if (createdByClubHeadId != null) {
        data['created_by_id'] = createdByClubHeadId;
      }
      final response = await _dio.post(AppConstants.endpointClubs, data: data);
      return Club.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Join Request Endpoints ──────────────────────────────────────────

  /// Get join requests (role-based filtering)
  Future<List<JoinRequest>> getJoinRequests() async {
    try {
      final response = await _dio.get(AppConstants.endpointJoinRequests);
      final requestsData = response.data as List;
      return requestsData
          .map((r) => JoinRequest.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Send join request
  Future<JoinRequest> sendJoinRequest(String clubId) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointJoinRequests,
        data: {'club_id': clubId},
      );
      return JoinRequest.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Approve join request
  Future<JoinRequest> approveJoinRequest(String requestId) async {
    try {
      final response = await _dio.post(
        '${AppConstants.endpointJoinRequests}$requestId/approve/',
      );
      return JoinRequest.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Reject join request
  Future<JoinRequest> rejectJoinRequest(String requestId) async {
    try {
      final response = await _dio.post(
        '${AppConstants.endpointJoinRequests}$requestId/reject/',
      );
      return JoinRequest.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Event Endpoints ────────────────────────────────────────────────

  /// Get all events
  Future<List<Event>> getEvents({String? clubId}) async {
    try {
      final queryParams = clubId != null ? '?club=$clubId' : '';
      final response =
          await _dio.get('${AppConstants.endpointEvents}$queryParams');
      final eventsData = response.data as List;
      return eventsData
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get single event
  Future<Event> getEvent(String eventId) async {
    try {
      final response =
          await _dio.get('${AppConstants.endpointEvents}$eventId/');
      return Event.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create event
  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required String clubId,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointEvents,
        data: {
          'title': title,
          'description': description,
          'event_date': eventDate.toIso8601String(),
          'club': clubId,
        },
      );
      return Event.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Register for event
  Future<EventRegistration> registerForEvent(String eventId) async {
    try {
      final response = await _dio.post(
        '${AppConstants.endpointEvents}$eventId/register/',
      );
      return EventRegistration.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get event participants (club head only)
  Future<List<EventRegistration>> getEventParticipants(String eventId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.endpointEvents}$eventId/participants/',
      );
      final regData = response.data as List;
      return regData
          .map((r) => EventRegistration.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Token Management ────────────────────────────────────────────────

  /// Save tokens to preferences
  Future<void> saveTokens(AuthResponse response) async {
    await _prefs.setString(AppConstants.keyAccessToken, response.accessToken);
    await _prefs.setString(AppConstants.keyRefreshToken, response.refreshToken);
    await _prefs.setString(AppConstants.keyUserRole, response.role);
  }

  /// Get access token
  String? getAccessToken() {
    return _prefs.getString(AppConstants.keyAccessToken);
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _prefs.getString(AppConstants.keyRefreshToken);
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await _prefs.remove(AppConstants.keyAccessToken);
    await _prefs.remove(AppConstants.keyRefreshToken);
    await _prefs.remove(AppConstants.keyUserRole);
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserEmail);
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return getAccessToken() != null;
  }
}
