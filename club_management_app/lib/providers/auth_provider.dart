import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = true;

  User? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isClubHead => _user?.isClubHead ?? false;
  bool get isStudent => _user?.isStudent ?? false;

  /// Called once at app startup — tries to restore the session from stored tokens.
  Future<void> tryRestoreSession() async {
    final token = await ApiService.getAccessToken();
    if (token == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      final data = await ApiService.getMe();
      _user = User.fromJson(data);
    } catch (_) {
      await ApiService.clearTokens();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.login(email: email, password: password);
    await ApiService.saveTokens(
      data['access'] as String,
      data['refresh'] as String,
    );
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String rollNumber = '',
  }) async {
    final data = await ApiService.register(
      fullName: fullName,
      email: email,
      password: password,
      rollNumber: rollNumber,
    );
    await ApiService.saveTokens(
      data['access'] as String,
      data['refresh'] as String,
    );
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final data = await ApiService.getMe();
      _user = User.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await ApiService.clearTokens();
    _user = null;
    notifyListeners();
  }
}
