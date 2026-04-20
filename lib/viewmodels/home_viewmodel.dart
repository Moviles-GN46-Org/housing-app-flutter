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
  Set<String> _favoritePropertyIds = <String>{};
  Set<String> _favoriteActionInFlight = <String>{};
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _notificationsPollingTimer;

  List<Property> get properties => _properties;
  Set<String> get favoritePropertyIds => _favoritePropertyIds;
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((item) => !item.isRead).toList();
  int get unreadNotificationsCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProperties => _properties.isNotEmpty;

  bool isFavorite(String propertyId) =>
      _favoritePropertyIds.contains(propertyId);
  bool isFavoriteActionInFlight(String propertyId) =>
      _favoriteActionInFlight.contains(propertyId);

  Future<void> fetchProperties() async {
    _setLoading(true);
    _clearError();

    try {
      _properties = await _repository.getProperties();
      _favoritePropertyIds = await _repository.getFavoritePropertyIds();
      notifyListeners();
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
      _favoritePropertyIds = await _repository.getFavoritePropertyIds();
      notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _repository.refreshAccessToken();
        if (refreshed) {
          try {
            _properties = await _repository.getProperties();
            _favoritePropertyIds = await _repository.getFavoritePropertyIds();
            notifyListeners();
          } catch (retryError) {}
        }
      }
    } catch (e) {
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleFavorite(String propertyId) async {
    if (_favoriteActionInFlight.contains(propertyId)) return false;

    _favoriteActionInFlight.add(propertyId);
    final wasFavorite = _favoritePropertyIds.contains(propertyId);

    if (wasFavorite) {
      _favoritePropertyIds.remove(propertyId);
    } else {
      _favoritePropertyIds.add(propertyId);
    }
    notifyListeners();

    try {
      final success = await _repository.toggleFavorite(propertyId);
      if (!success) {
        if (wasFavorite) {
          _favoritePropertyIds.add(propertyId);
        } else {
          _favoritePropertyIds.remove(propertyId);
        }
        notifyListeners();
        return false;
      }
      return true;
    } catch (_) {
      if (wasFavorite) {
        _favoritePropertyIds.add(propertyId);
      } else {
        _favoritePropertyIds.remove(propertyId);
      }
      notifyListeners();
      return false;
    } finally {
      _favoriteActionInFlight.remove(propertyId);
      notifyListeners();
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
