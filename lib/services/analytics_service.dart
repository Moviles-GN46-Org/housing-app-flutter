import 'package:uuid/uuid.dart';
import 'api_client.dart';

class AnalyticsService {
  final ApiClient _apiClient;
  String? _sessionId;

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

  Future<void> _postEvent(String eventType) async {
    try {
      await _apiClient.post(
        '/analytics/events',
        data: {'sessionId': _sessionId, 'eventType': eventType, 'payload': {}},
      );
    } catch (e) {}
  }


}
