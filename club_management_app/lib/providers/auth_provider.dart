import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/index.dart';
import '../models/index.dart';

/// Exception class for auth-related errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Authentication provider - manages login/logout/token refresh
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  late SharedPreferences _prefs;

  // State variables
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  String? _userRole;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider(this._apiService);

  // ─── Getters ────────────────────────────────────────────────────────

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole;
  String? get accessToken => _accessToken;

  bool get isStudent => _userRole == AppConstants.roleStudent;
  bool get isClubHead => _userRole == AppConstants.roleClubHead;
  bool get isAdmin => _userRole == AppConstants.roleAdmin;

  // ─── Initialization ─────────────────────────────────────────────────

  /// Initialize provider - check for saved session
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedSession();
  }

  /// Load saved authentication session
  Future<void> _loadSavedSession() async {
    try {
      final token = _prefs.getString(AppConstants.keyAccessToken);
      if (token != null) {
        _accessToken = token;
        _refreshToken = _prefs.getString(AppConstants.keyRefreshToken);
        _userRole = _prefs.getString(AppConstants.keyUserRole);
        _isAuthenticated = true;

        // Verify token is still valid by fetching profile
        await _fetchUserProfile();
      }
    } catch (e) {
      // Session is invalid, clear it
      await clearSession();
    }
    notifyListeners();
  }

  /// Fetch current user profile from API
  Future<void> _fetchUserProfile() async {
    try {
      _currentUser = await _apiService.getProfile();
    } catch (e) {
      throw AuthException('Failed to fetch user profile: $e');
    }
  }

  // ─── Authentication Methods ─────────────────────────────────────────

  /// Register new user
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String rollNumber = '',
    String role = AppConstants.roleStudent,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate inputs
      if (fullName.isEmpty) throw AuthException('Full name cannot be empty');
      if (email.isEmpty) throw AuthException('Email cannot be empty');
      if (password.isEmpty) throw AuthException('Password cannot be empty');
      if (password != confirmPassword)
        throw AuthException('Passwords do not match');
      if (password.length < 6)
        throw AuthException('Password must be at least 6 characters');

      // Call API
      final response = await _apiService.register(
        fullName: fullName,
        email: email,
        password: password,
        rollNumber: rollNumber,
        role: role,
      );

      // Save session
      await _saveSession(response);
      _currentUser = response.user;
      _isAuthenticated = true;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate inputs
      if (email.isEmpty) throw AuthException('Email cannot be empty');
      if (password.isEmpty) throw AuthException('Password cannot be empty');

      // Call API
      final response =
          await _apiService.login(email: email, password: password);

      // Save session
      await _saveSession(response);
      _currentUser = response.user;
      _isAuthenticated = true;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      await clearSession();
      _isAuthenticated = false;
      _currentUser = null;
      _userRole = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Refresh access token
  Future<void> refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        throw AuthException('No refresh token available');
      }
      await _apiService.refreshToken(_refreshToken!);
      _accessToken = _apiService.getAccessToken();
      notifyListeners();
    } catch (e) {
      // If refresh fails, clear session
      await clearSession();
      _isAuthenticated = false;
      throw AuthException('Token refresh failed: $e');
    }
  }

  // ─── Session Management ─────────────────────────────────────────────

  /// Save authentication session
  Future<void> _saveSession(AuthResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _userRole = response.role;

    await _apiService.saveTokens(response);

    // Save user info
    await _prefs.setString(AppConstants.keyUserId, response.user.id);
    await _prefs.setString(AppConstants.keyUserEmail, response.user.email);
  }

  /// Clear session (logout)
  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _userRole = null;
    _currentUser = null;

    await _apiService.clearTokens();
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserEmail);

    notifyListeners();
  }

  // ─── State Management Helpers ────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
