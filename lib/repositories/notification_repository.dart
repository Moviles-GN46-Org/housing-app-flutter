import '../models/app_notification.dart';
import '../services/api_client.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _api.get('/notifications');

    if (response.statusCode != 200) {
      return [];
    }

    final responseData = response.data;
    List<dynamic> notifList = [];

    if (responseData is List) {
      notifList = responseData;
    } else if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is List) {
        notifList = data;
      }
    }

    return notifList
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }
}
