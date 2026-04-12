import '../models/index.dart';

/// Local cache service for offline support
class CacheService {
  static const String _clubsKey = 'cached_clubs';
  static const String _eventsKey = 'cached_events';
  static const String _joinRequestsKey = 'cached_join_requests';

  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  // In-memory cache
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  static const Duration _cacheDuration = Duration(minutes: 30);

  /// Check if cache is valid
  bool _isCacheValid(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  /// Save clubs to cache
  void cacheClubs(List<Club> clubs) {
    _cache[_clubsKey] = clubs;
    _cacheTimestamps[_clubsKey] = DateTime.now();
  }

  /// Get cached clubs
  List<Club>? getCachedClubs() {
    if (_isCacheValid(_clubsKey)) {
      return _cache[_clubsKey] as List<Club>?;
    }
    return null;
  }

  /// Save events to cache
  void cacheEvents(List<Event> events) {
    _cache[_eventsKey] = events;
    _cacheTimestamps[_eventsKey] = DateTime.now();
  }

  /// Get cached events
  List<Event>? getCachedEvents() {
    if (_isCacheValid(_eventsKey)) {
      return _cache[_eventsKey] as List<Event>?;
    }
    return null;
  }

  /// Save join requests to cache
  void cacheJoinRequests(List<JoinRequest> requests) {
    _cache[_joinRequestsKey] = requests;
    _cacheTimestamps[_joinRequestsKey] = DateTime.now();
  }

  /// Get cached join requests
  List<JoinRequest>? getCachedJoinRequests() {
    if (_isCacheValid(_joinRequestsKey)) {
      return _cache[_joinRequestsKey] as List<JoinRequest>?;
    }
    return null;
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear specific cache
  void clearSpecificCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'clubs_cached': _isCacheValid(_clubsKey),
      'events_cached': _isCacheValid(_eventsKey),
      'join_requests_cached': _isCacheValid(_joinRequestsKey),
      'cache_size': _cache.length,
    };
  }
}

/// Network connectivity observer
class ConnectivityObserver {
  static bool _isOnline = true;

  static bool get isOnline => _isOnline;

  static Future<void> checkConnectivity() async {
    try {
      // TODO: Use connectivity_plus package to detect network
      // For now, assume online
      _isOnline = true;
    } catch (e) {
      _isOnline = false;
    }
  }

  static void setOnlineStatus(bool online) {
    _isOnline = online;
  }
}
