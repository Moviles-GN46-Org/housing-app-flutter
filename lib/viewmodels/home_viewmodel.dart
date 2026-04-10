import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../models/app_notification.dart';
import '../models/property_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/property_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final PropertyRepository _repository;
  final NotificationRepository _notificationRepository;

  HomeViewModel(this._repository, this._notificationRepository);

  List<Property> _properties = [];
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _notificationsPollingTimer;

  List<Property> get properties => _properties;
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((item) => !item.isRead).toList();
  int get unreadNotificationsCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProperties => _properties.isNotEmpty;

  Future<void> fetchProperties() async {
    _setLoading(true);
    _clearError();

    try {
      _properties = await _repository.getProperties();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProperties() async {
    await fetchProperties();
  }

  Future<void> fetchNotifications() async {
    try {
      _notifications = await _notificationRepository.getNotifications();
      notifyListeners();
    } catch (_) {}
  }

  void startNotificationsPolling({
    Duration interval = const Duration(seconds: 30),
  }) {
    _notificationsPollingTimer?.cancel();
    _notificationsPollingTimer = Timer.periodic(interval, (_) {
      fetchNotifications();
    });
  }

  void stopNotificationsPolling() {
    _notificationsPollingTimer?.cancel();
    _notificationsPollingTimer = null;
  }

  Future<void> retryProperties() async {
    _setLoading(true);
    _clearError();

    try {
      _properties = await _repository.getProperties();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _repository.refreshAccessToken();
        if (refreshed) {
          try {
            _properties = await _repository.getProperties();
          } catch (retryError) {}
        }
      }
    } catch (e) {
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopNotificationsPolling();
    super.dispose();
  }
}
