import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Change this to 10.0.2.2 when running on an Android emulator,
// or your machine's LAN IP when running on a real device.
const String _baseUrl = 'http://10.0.2.2:8000/api';

class ApiService {
  // ─── Token helpers ────────────────────────────────────────────────────────

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // ─── Auth headers ──────────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// POST /api/auth/register/
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String rollNumber = '',
    String role = 'student',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'roll_number': rollNumber,
        'role': role,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// POST /api/auth/login/
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Events ───────────────────────────────────────────────────────────────

  /// GET /api/events/
  static Future<List<dynamic>> getEvents() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_baseUrl/events/'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return [];
  }

  // ─── Clubs ────────────────────────────────────────────────────────────────

  /// GET /api/clubs/
  static Future<List<dynamic>> getClubs() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_baseUrl/clubs/'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return [];
  }

  /// POST /api/clubs/{id}/join/
  static Future<Map<String, dynamic>> joinClub(String clubId) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_baseUrl/clubs/$clubId/join/'),
      headers: headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Leaderboard ──────────────────────────────────────────────────────────

  /// GET /api/auth/leaderboard/
  static Future<List<dynamic>> getLeaderboard() async {
    final res = await http.get(Uri.parse('$_baseUrl/auth/leaderboard/'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return [];
  }
}
