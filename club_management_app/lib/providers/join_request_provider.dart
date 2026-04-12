import 'package:flutter/material.dart';
import '../core/index.dart';
import '../models/index.dart';

/// Join Request provider - manages join request data and operations
class JoinRequestProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<JoinRequest> _joinRequests = [];
  bool _isLoading = false;
  String? _error;

  JoinRequestProvider(this._apiService);

  // ─── Getters ────────────────────────────────────────────────────────

  List<JoinRequest> get joinRequests => _joinRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get pending requests (club head view)
  List<JoinRequest> get pendingRequests {
    return _joinRequests.where((r) => r.status == 'pending').toList();
  }

  /// Get user's request status for a club
  String? getUserRequestStatus(String clubId) {
    try {
      final request = _joinRequests.firstWhere((r) => r.club?['id'] == clubId);
      return request.status;
    } catch (e) {
      return null;
    }
  }

  // ─── Join Request Operations ────────────────────────────────────────

  /// Fetch all join requests
  Future<void> fetchJoinRequests() async {
    try {
      _setLoading(true);
      _clearError();
      _joinRequests = await _apiService.getJoinRequests();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Send join request for a club
  Future<JoinRequest> sendJoinRequest(String clubId) async {
    try {
      _setLoading(true);
      _clearError();
      final request = await _apiService.sendJoinRequest(clubId);
      _joinRequests.add(request);
      _setLoading(false);
      return request;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Approve join request (club head only)
  Future<void> approveJoinRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      final updated = await _apiService.approveJoinRequest(requestId);
      final index = _joinRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _joinRequests[index] = updated;
      }
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Reject join request (club head only)
  Future<void> rejectJoinRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      final updated = await _apiService.rejectJoinRequest(requestId);
      final index = _joinRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _joinRequests[index] = updated;
      }
      _setLoading(false);
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
