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

  AnalyticsService(this._apiClient);

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