import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'api_client.dart';
import '../models/local_event.dart'; 
import 'local_db_service.dart';     

class ScreenName {
  static const String home = 'Home';
  static const String mapSearch = 'Map Search';
  static const String chatScreen = 'Chat Screen';
  static const String feed = 'Feed';
  static const String roomies = 'Roomies';
  static const String profileEdit = 'Profile Edit';
}

class AnalyticsService {
  final ApiClient _apiClient;
  final LocalDbService _localDb = LocalDbService();
  String? _sessionId;
  String? currentScreen;

  Stopwatch? _loadStopwatch;
  String? _pendingLoadScreen;

  AnalyticsService(this._apiClient);

  // A feature "load" is: user taps a tab -> screen's data is ready on screen.
  // Start is called from the tab-switch path; end is called when the screen
  // considers itself loaded (first frame for placeholders, post-fetch for
  // data-backed screens).
  void markFeatureLoadStart(String screenName) {
    _pendingLoadScreen = screenName;
    _loadStopwatch = Stopwatch()..start();
  }

  // Drops any in-flight load timing without posting. Called from the app
  // lifecycle observer when the app is backgrounded — a paused user isn't
  // "still loading," so the elapsed time would be noise.
  void discardPendingLoad() {
    _loadStopwatch = null;
    _pendingLoadScreen = null;
  }

  Future<void> markFeatureLoadEnd(String screenName) async {
    final sw = _loadStopwatch;
    // The screenName gate prevents stale stopwatches from attributing to the
    // wrong screen if the user tab-switched mid-load.
    if (sw == null || _pendingLoadScreen != screenName || _sessionId == null) {
      return;
    }
    sw.stop();
    final elapsedMs = sw.elapsedMilliseconds;
    _loadStopwatch = null;
    _pendingLoadScreen = null;

    try {
      await _apiClient.post(
        '/analytics/events',
        data: {
          'sessionId': _sessionId,
          'eventType': 'FEATURE_LOAD_TIME',
          'screenName': screenName,
          'payload': {'screen': screenName, 'durationMs': elapsedMs},
        },
      );
    } catch (e) {
      debugPrint('Failed to report feature load time: $e');
    }
  }

  Future<void> startSession() async {
    _sessionId = const Uuid().v4();
    await logGenericEvent('SESSION_START', {});
  }

  Future<void> endSession() async {
    if (_sessionId == null) return;
    await logGenericEvent('SESSION_END', {});
    _sessionId = null;
  }

  Future<void> logLocationBQ(double lat, double lng) async {
    if (_sessionId == null) await startSession();

    await logGenericEvent('LOCATION_STATS_UPDATE', {
      'lat': lat,
      'lng': lng,
    });
  }

  Future<void> logCrash({
    required String screenName,
    required Object error,
    StackTrace? stackTrace,
  }) async {
    await logGenericEvent('CRASH', {
      'screen': screenName,
      'errorMessage': error.toString(),
      'stackTrace': stackTrace?.toString() ?? '',
    }, forcedScreen: screenName);
  }


  Future<void> logGenericEvent(String eventType, Map<String, dynamic> payload, {String? forcedScreen}) async {
    if (_sessionId == null) return;

    final event = LocalEvent(
      id: const Uuid().v4(),
      lat: payload['lat']?.toDouble() ?? 0.0,
      lng: payload['lng']?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );

    await _localDb.saveLocationEvent(event);

    await syncAllPendingEvents();
  }

  Future<void> syncAllPendingEvents() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        debugPrint(' Sin conexión a internet. Los eventos permanecerán en local.');
        return;
      }

      final pendingEvents = _localDb.getUnsyncedEvents();
      if (pendingEvents.isEmpty) return;

      debugPrint('Sincronizando ${pendingEvents.length} eventos pendientes...');

      final eventsData = pendingEvents.map((e) => {
        'sessionId': _sessionId ?? 'unknown_session',
        'eventType': e.lat != 0.0 ? 'LOCATION_STATS_UPDATE' : 'SESSION_EVENT', 
        'screenName': currentScreen ?? 'Unknown',
        'payload': {
          'lat': e.lat,
          'lng': e.lng,
          'timestamp': e.timestamp.toIso8601String(),
        },
      }).toList();

      final response = await _apiClient.post(
        '/analytics/batch',
        data: {'events': eventsData},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        for (var e in pendingEvents) {
          await _localDb.markAsSynced(e.id);
        }
        debugPrint('Sincronización masiva completada con éxito.');
        
        await _localDb.clearSyncedEvents();
      }
    } catch (e) {
      debugPrint('Falló la sincronización masiva: $e. Los datos siguen seguros en local.');
    }
  }
}