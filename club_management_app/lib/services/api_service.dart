import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Base URL ──────────────────────────────────────────────────────────────
// • Android emulator  → 10.0.2.2
// • iOS simulator     → 127.0.0.1
// • Real device       → your machine's LAN IP, e.g. 192.168.1.10
const String _base = 'http://127.0.0.1:8000/api';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  // ─── Token storage ────────────────────────────────────────────────────────

  static Future<String?> getAccessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('access_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('access_token', access);
    await p.setString('refresh_token', refresh);
  }

  static Future<void> clearTokens() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('access_token');
    await p.remove('refresh_token');
  }

  // ─── Headers ──────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getAccessToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ─── HTTP helpers ─────────────────────────────────────────────────────────

  static dynamic _decode(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    final json = jsonDecode(body);
    if (res.statusCode >= 400) {
      String msg = 'Request failed';
      if (json is Map) {
        final raw = json['error'] ?? json['detail'] ?? json['message'];
        if (raw is String) {
          msg = raw;
        } else if (raw != null) {
          msg = raw.toString();
        }
      }
      throw ApiException(res.statusCode, msg);
    }
    return json;
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(
      Uri.parse('$_base$path'),
      headers: await _headers(auth: auth),
    );
    return _decode(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.patch(
      Uri.parse('$_base$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await http.delete(
      Uri.parse('$_base$path'),
      headers: await _headers(auth: auth),
    );
    if (res.statusCode == 204) return null;
    return _decode(res);
  }

  // =========================================================================
  // AUTH
  // =========================================================================

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String rollNumber = '',
    String phoneNumber = '',
  }) async {
    return await post('/auth/register/', {
      'full_name': fullName,
      'email': email,
      'password': password,
      'roll_number': rollNumber,
      'phone_number': phoneNumber,
      'role': 'student',
    }, auth: false) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await post('/auth/login/', {
      'email': email,
      'password': password,
    }, auth: false) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMe() async {
    return await get('/auth/me/') as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    return await patch('/auth/me/', data) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getLeaderboard() async {
    return await get('/auth/leaderboard/', auth: false) as List<dynamic>;
  }

  // =========================================================================
  // ADMIN
  // =========================================================================

  static Future<Map<String, dynamic>> getAdminStats() async {
    return await get('/auth/admin/stats/') as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getAdminUsers() async {
    return await get('/auth/admin/users/') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> updateUserRole(
      String userId, String role) async {
    return await patch('/auth/admin/users/$userId/', {'role': role})
        as Map<String, dynamic>;
  }

  static Future<void> deactivateUser(String userId) async {
    await delete('/auth/admin/users/$userId/');
  }

  // =========================================================================
  // CLUBS
  // =========================================================================

  static Future<List<dynamic>> getClubs() async {
    return await get('/clubs/') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getClub(String id) async {
    return await get('/clubs/$id/') as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createClub({
    required String name,
    required String description,
  }) async {
    return await post('/clubs/', {
      'name': name,
      'description': description,
    }) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateClub(
      String id, Map<String, dynamic> data) async {
    return await patch('/clubs/$id/', data) as Map<String, dynamic>;
  }

  static Future<void> deleteClub(String id) async {
    await delete('/clubs/$id/');
  }

  static Future<Map<String, dynamic>> joinClub(String clubId) async {
    return await post('/clubs/$clubId/join/', {}) as Map<String, dynamic>;
  }

  // =========================================================================
  // EVENTS
  // =========================================================================

  static Future<List<dynamic>> getEvents({String? clubId}) async {
    final query = clubId != null ? '?club=$clubId' : '';
    return await get('/clubs/events/$query') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getEvent(String id) async {
    return await get('/clubs/events/$id/') as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createEvent({
  required String title,
  required String description,
  required String eventDate,
  required String clubId,
  int capacity = 0,
  String? imageUrl,
  }) async {
    return await post('/clubs/events/', {
      'title': title,
      'description': description,
      'event_date': eventDate,
      'club': clubId,
      'capacity': capacity,
      if (imageUrl != null) 'image_url': imageUrl,
    }) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMyEvents() async {
    return await get('/clubs/events/my/') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> applyForEvent(String eventId) async {
    return await post('/clubs/events/$eventId/apply/', {}) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPendingRegistrations(String eventId) async {
    return await get('/clubs/events/$eventId/pending/') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> approveRegistration(
      String eventId, String registrationId) async {
    return await post('/clubs/events/$eventId/approve/', {
      'registration_id': registrationId,
    }) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> rejectRegistration(
      String eventId, String registrationId) async {
    return await post('/clubs/events/$eventId/reject/', {
      'registration_id': registrationId,
    }) as Map<String, dynamic>;
  }

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

  static Future<List<dynamic>> getNotifications() async {
    return await get('/clubs/notifications/') as List<dynamic>;
  }

  static Future<void> markNotificationRead(int id) async {
    await post('/clubs/notifications/$id/read/', {});
  }

  // =========================================================================
  // CLUB CHAT
  // =========================================================================

  static Future<List<dynamic>> getClubMessages(String clubId) async {
    return await get('/clubs/$clubId/chat/') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> sendClubMessage(
      String clubId, String content) async {
    return await post('/clubs/$clubId/chat/', {'content': content})
        as Map<String, dynamic>;
  }
}
