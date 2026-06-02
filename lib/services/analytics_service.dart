import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client.dart';
import '../models/local_event.dart';
import '../models/searches_by_month_model.dart';
import 'local_db_service.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

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

  void markFeatureLoadStart(String screenName) {
    _pendingLoadScreen = screenName;
    _loadStopwatch = Stopwatch()..start();
  }

  // Drops the in-flight timer without posting. Call this when the app is
  // backgrounded — a paused user isn't "still loading."
  void discardPendingLoad() {
    _loadStopwatch = null;
    _pendingLoadScreen = null;
  }

  Future<void> markFeatureLoadEnd(String screenName) async {
    final sw = _loadStopwatch;
    // Screen-name gate prevents a stale stopwatch from attributing to the
    // wrong screen if the user switched tabs mid-load.
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

    await logGenericEvent('LOCATION_STATS_UPDATE', {'lat': lat, 'lng': lng});
  }

  Future<void> logSearchFilterUsages(List<Map<String, String>> filters) async {
    if (filters.isEmpty) return;
    if (_sessionId == null) await startSession();
    try {
      await _apiClient.post(
        '/analytics/search-filter-usages',
        data: {'sessionId': _sessionId, 'filters': filters},
      );
    } catch (e) {
      debugPrint('Failed to log filter usage: $e');
    }
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

  Future<void> logGenericEvent(
    String eventType,
    Map<String, dynamic> payload, {
    String? forcedScreen,
  }) async {
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

  Future<void> logSearchQuery(String query) async {
    if (_sessionId == null) return;
    try {
      await _apiClient.post(
        '/analytics/events',
        data: {
          'sessionId': _sessionId,
          'eventType': 'SEARCH',
          'screenName': currentScreen ?? ScreenName.home,
          'payload': {'query': query},
        },
      );
    } catch (e) {
      debugPrint('Failed to log search query: $e');
    }
  }

  Future<List<MonthlySearchCount>> fetchSearchesByMonth({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();

      final response = await _apiClient.get(
        '/analytics/searches-by-month',
        queryParams: queryParams.isEmpty ? null : queryParams,
      );

      final data = (response.data['data'] as List).cast<Map<String, dynamic>>();
      return data.map(MonthlySearchCount.fromJson).toList();
    } catch (e) {
      debugPrint('Failed to fetch searches by month: $e');
      rethrow;
    }
  }

  Future<void> syncAllPendingEvents() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        debugPrint(
          ' Sin conexión a internet. Los eventos permanecerán en local.',
        );
        return;
      }

      final pendingEvents = _localDb.getUnsyncedEvents();
      if (pendingEvents.isEmpty) return;

      debugPrint('Sincronizando ${pendingEvents.length} eventos pendientes...');

      final eventsData = pendingEvents
          .map(
            (e) => {
              'sessionId': _sessionId ?? 'unknown_session',
              'eventType': e.lat != 0.0
                  ? 'LOCATION_STATS_UPDATE'
                  : 'SESSION_EVENT',
              'screenName': currentScreen ?? 'Unknown',
              'payload': {
                'lat': e.lat,
                'lng': e.lng,
                'timestamp': e.timestamp.toIso8601String(),
              },
            },
          )
          .toList();

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
      debugPrint(
        'Falló la sincronización masiva: $e. Los datos siguen seguros en local.',
      );
    }
  }

  Future<void> logDeviceBrandOnMapOpen() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String brand = "Desconocido";

      // Interrogamos el hardware
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        brand = androidInfo
            .manufacturer; // Retorna 'samsung', 'xiaomi', 'motorola', etc.
      } else if (Platform.isIOS) {
        brand = "Apple";
      }

      // Lo enviamos directo al backend
      await _apiClient.post(
        '/analytics/device-brands',
        data: {'brand': brand.toUpperCase()},
      );
      debugPrint("Analítica de marca enviada: $brand");
    } catch (e) {
      debugPrint('Error enviando marca del dispositivo: $e');
    }
  }
}
