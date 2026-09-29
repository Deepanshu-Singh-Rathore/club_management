import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Base URL ──────────────────────────────────────────────────────────────
// Configurable at build time via --dart-define=API_URL=https://your-backend.onrender.com
// Automatically ensures the URL has the correct '/api' path.
// Defaults to http://127.0.0.1:8000/api for local development.
String _resolveBaseUrl() {
  const envUrl = String.fromEnvironment('API_URL');
  if (envUrl.isNotEmpty) {
    var url = envUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }
  return 'http://127.0.0.1:8000/api';
}

final String _base = _resolveBaseUrl();

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
    final token = p.getString('access_token');
    print("DEBUG: Fetched Token: ${token != null ? 'EXISTS' : 'NULL'}");
    return token;
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('access_token', access);
    await p.setString('refresh_token', refresh);
    print("DEBUG: Tokens saved successfully.");
  }

  static Future<void> clearTokens() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('access_token');
    await p.remove('refresh_token');
    print("DEBUG: Tokens cleared.");
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
    dynamic json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      // Non-JSON response (e.g. Django ALLOWED_HOSTS error page)
      throw ApiException(res.statusCode,
          'Server error (${res.statusCode}): ${body.substring(0, body.length.clamp(0, 120))}');
    }
    if (res.statusCode >= 400) {
      print("DEBUG API [${res.statusCode}] Response: $body");
      String msg = 'Request failed (${res.statusCode})';
      if (json is Map) {
        final raw = json['error'] ?? json['detail'] ?? json['message'];
        if (raw is String) {
          msg = raw;
        } else if (raw != null) {
          msg = raw.toString();
        } else {
          final fieldErrors = json.entries
              .where((e) => e.value is List)
              .map((e) => (e.value as List).first?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
          if (fieldErrors.isNotEmpty) msg = fieldErrors.join(' ');
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
    print("DEBUG POST $path: ${res.statusCode}");
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
    return await post(
        '/auth/register/',
        {
          'full_name': fullName,
          'email': email,
          'password': password,
          'roll_number': rollNumber,
          'phone_number': phoneNumber,
          'role': 'student',
        },
        auth: false) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await post(
        '/auth/login/',
        {
          'email': email,
          'password': password,
        },
        auth: false) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMe() async {
    return await get('/auth/me/') as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateMe(
      Map<String, dynamic> data) async {
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
  // =========================================================================
  // CLUBS
  // =========================================================================

  static Future<List<dynamic>> getClubs({
    String? category,
    String? search,
    String? sort,
  }) async {
    final params = <String>[];
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }
    if (sort != null && sort.isNotEmpty) {
      params.add('sort=${Uri.encodeComponent(sort)}');
    }
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    return await get('/clubs/$qs', auth: false) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getClub(String id) async {
    return await get('/clubs/$id/', auth: false) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createClub({
    required String name,
    required String description,
    String category = 'Technology',
    String? bannerUrl,
    String? logoUrl,
  }) async {
    return await post('/clubs/', {
      'name': name,
      'description': description,
      'category': category,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
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

  static Future<Map<String, dynamic>> leaveClub(String clubId) async {
    return await post('/clubs/$clubId/leave/', {}) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getUserClubs() async {
    return await get('/clubs/user/my/') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getClubMembers(String clubId,
      {String? search}) async {
    final qs = (search != null && search.isNotEmpty)
        ? '?search=${Uri.encodeComponent(search)}'
        : '';
    return await get('/clubs/$clubId/members/$qs') as Map<String, dynamic>;
  }

  static Future<void> removeClubMember(String clubId, String userId) async {
    await delete('/clubs/$clubId/members/?user_id=$userId');
  }

  static Future<Map<String, dynamic>> getClubAnalytics(String clubId) async {
    return await get('/clubs/$clubId/analytics/') as Map<String, dynamic>;
  }

  // =========================================================================
  // EVENTS
  // =========================================================================

  static Future<List<dynamic>> getEvents({
    String? clubId,
    String? category,
    String? period,
    String? search,
    String? status,
  }) async {
    final params = <String>[];
    if (clubId != null) params.add('club=$clubId');
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    if (period != null && period.isNotEmpty) params.add('period=$period');
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }
    if (status != null && status.isNotEmpty) params.add('status=$status');

    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    return await get('/clubs/events/$qs', auth: false) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getEvent(String id) async {
    return await get('/clubs/events/$id/', auth: false) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required String eventDate,
    required String clubId,
    int capacity = 0,
    String venue = 'Campus Auditorium',
    String category = 'General',
    String? registrationDeadline,
    String? schedule,
    String? imageUrl,
  }) async {
    return await post('/clubs/events/', {
      'title': title,
      'description': description,
      'event_date': eventDate,
      'club': clubId,
      'capacity': capacity,
      'venue': venue,
      'category': category,
      if (registrationDeadline != null)
        'registration_deadline': registrationDeadline,
      if (schedule != null) 'schedule': schedule,
      if (imageUrl != null) 'image_url': imageUrl,
    }) as Map<String, dynamic>;
  }

  static Future<void> cancelEvent(String eventId) async {
    await delete('/clubs/events/$eventId/');
  }

  static Future<List<dynamic>> getMyEvents() async {
    return await get('/clubs/events/my/') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> applyForEvent(String eventId) async {
    return await post('/clubs/events/$eventId/apply/', {})
        as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> cancelEventRegistration(
      String eventId) async {
    return await post('/clubs/events/$eventId/cancel/', {})
        as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> checkInAttendee(String eventId,
      {String? ticketId, String? registrationId}) async {
    return await post('/clubs/events/$eventId/check-in/', {
      if (ticketId != null) 'ticket_id': ticketId,
      if (registrationId != null) 'registration_id': registrationId,
    }) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getEventRegistrations(String eventId,
      {String? status, String? attendance}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (attendance != null) params.add('attendance=$attendance');
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    return await get('/clubs/events/$eventId/registrations/$qs')
        as Map<String, dynamic>;
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
  // COMMUNITY FEED & POSTS
  // =========================================================================

  static Future<List<dynamic>> getClubFeed(
      {String? type, String? clubId}) async {
    final params = <String>[];
    if (type != null) params.add('type=$type');
    if (clubId != null) params.add('club=$clubId');
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    return await get('/clubs/feed/$qs', auth: false) as List<dynamic>;
  }

  static Future<List<dynamic>> getClubPosts(String clubId) async {
    return await get('/clubs/$clubId/posts/', auth: false) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createClubPost(
    String clubId, {
    required String title,
    required String content,
    String postType = 'general',
    String? imageUrl,
  }) async {
    return await post('/clubs/$clubId/posts/', {
      'title': title,
      'content': content,
      'post_type': postType,
      if (imageUrl != null) 'image_url': imageUrl,
    }) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> togglePostLike(String postId) async {
    return await post('/clubs/posts/$postId/like/', {}) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPostComments(String postId) async {
    return await get('/clubs/posts/$postId/comments/', auth: false)
        as List<dynamic>;
  }

  static Future<Map<String, dynamic>> addPostComment(
      String postId, String content) async {
    return await post('/clubs/posts/$postId/comments/', {'content': content})
        as Map<String, dynamic>;
  }

  // =========================================================================
  // ANNOUNCEMENTS
  // =========================================================================

  static Future<List<dynamic>> getAnnouncements() async {
    return await get('/clubs/announcements/', auth: false) as List<dynamic>;
  }

  // =========================================================================
  // GLOBAL SEARCH & RECOMMENDATIONS & ACHIEVEMENTS
  // =========================================================================

  static Future<Map<String, dynamic>> globalSearch(String query) async {
    final qs = Uri.encodeComponent(query);
    return await get('/clubs/search/?q=$qs', auth: false)
        as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRecommendations() async {
    return await get('/clubs/recommendations/') as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAchievements() async {
    return await get('/clubs/achievements/') as Map<String, dynamic>;
  }

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

  static Future<List<dynamic>> getNotifications() async {
    return await get('/clubs/notifications/') as List<dynamic>;
  }

  static Future<void> markNotificationRead(dynamic id) async {
    await post('/clubs/notifications/$id/read/', {});
  }

  static Future<void> markAllNotificationsRead() async {
    await post('/clubs/notifications/read-all/', {});
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
