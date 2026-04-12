import 'package:flutter/material.dart';
import '../core/index.dart';
import '../models/index.dart';

/// Event provider - manages event data and operations
class EventProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoading = false;
  String? _error;

  EventProvider(this._apiService);

  // ─── Getters ────────────────────────────────────────────────────────

  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Event Operations ───────────────────────────────────────────────

  /// Fetch all events
  Future<void> fetchEvents({String? clubId}) async {
    try {
      _setLoading(true);
      _clearError();
      _events = await _apiService.getEvents(clubId: clubId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Get event by ID
  Future<void> selectEvent(String eventId) async {
    try {
      _setLoading(true);
      _clearError();
      _selectedEvent = await _apiService.getEvent(eventId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Create new event (club head only)
  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required String clubId,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      final event = await _apiService.createEvent(
        title: title,
        description: description,
        eventDate: eventDate,
        clubId: clubId,
      );
      _events.add(event);
      _setLoading(false);
      return event;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Register for event (student only)
  Future<EventRegistration> registerForEvent(String eventId) async {
    try {
      _setLoading(true);
      _clearError();
      final registration = await _apiService.registerForEvent(eventId);
      _setLoading(false);
      return registration;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Get event participants (club head only)
  Future<List<EventRegistration>> getEventParticipants(String eventId) async {
    try {
      _setLoading(true);
      _clearError();
      final participants = await _apiService.getEventParticipants(eventId);
      _setLoading(false);
      return participants;
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
