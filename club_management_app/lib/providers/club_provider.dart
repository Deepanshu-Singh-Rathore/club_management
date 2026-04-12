import 'package:flutter/material.dart';
import '../core/index.dart';
import '../models/index.dart';

/// Club provider - manages club data and operations
class ClubProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Club> _clubs = [];
  Club? _selectedClub;
  bool _isLoading = false;
  String? _error;

  ClubProvider(this._apiService);

  // ─── Getters ────────────────────────────────────────────────────────

  List<Club> get clubs => _clubs;
  Club? get selectedClub => _selectedClub;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Club Operations ────────────────────────────────────────────────

  /// Fetch all clubs
  Future<void> fetchClubs() async {
    try {
      _setLoading(true);
      _clearError();
      _clubs = await _apiService.getClubs();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Get club by ID
  Future<void> selectClub(String clubId) async {
    try {
      _setLoading(true);
      _clearError();
      _selectedClub = await _apiService.getClub(clubId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Create new club (admin only)
  Future<Club> createClub({
    required String name,
    required String description,
    String? clubHeadId,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      final club = await _apiService.createClub(
        name: name,
        description: description,
        createdByClubHeadId: clubHeadId,
      );
      _clubs.add(club);
      _setLoading(false);
      return club;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
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
