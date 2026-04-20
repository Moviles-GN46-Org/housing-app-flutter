import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

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
  String? _sessionId;
  String? currentScreen;

  AnalyticsService(this._apiClient);

  Future<void> startSession() async {
    _sessionId = const Uuid().v4();
    await _postEvent('SESSION_START');
  }

  Future<void> endSession() async {
    if (_sessionId == null) return;
    await _postEvent('SESSION_END');
    _sessionId = null;
  }

  Future<void> logCrash({
    required String screenName,
    required Object error,
    StackTrace? stackTrace,
  }) async {
    if (_sessionId == null) return;
    try {
      await _apiClient.post(
        '/analytics/events',
        data: {
          'sessionId': _sessionId,
          'eventType': 'CRASH',
          'screenName': screenName,
          'payload': {
            'screen': screenName,
            'errorMessage': error.toString(),
            'stackTrace': stackTrace?.toString() ?? '',
          },
        },
      );
    } catch (e) {
      debugPrint('Failed to report crash: $e');
    }
  }

  Future<void> _postEvent(String eventType) async {
    try {
      await _apiClient.post(
        '/analytics/events',
        data: {'sessionId': _sessionId, 'eventType': eventType, 'payload': {}},
      );
    } catch (e) {
      debugPrint('Failed to post session event $eventType: $e');
    }
  }
}
