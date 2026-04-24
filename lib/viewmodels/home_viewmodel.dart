import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/property_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/property_repository.dart';
import '../services/property_cache_service.dart';

class HomeViewModel extends ChangeNotifier {
  final PropertyRepository _repository;
  final NotificationRepository _notificationRepository;
  final PropertyCacheService _cache;

  HomeViewModel(
    this._repository,
    this._notificationRepository, {
    PropertyCacheService? cache,
  }) : _cache = cache ?? PropertyCacheService();

  static const int _pageSize = 10;

  List<Property> _properties = [];
  Set<String> _favoritePropertyIds = <String>{};
  final Set<String> _favoriteActionInFlight = <String>{};
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isFromCache = false;
  bool _hasMore = true;
  int _currentPage = 0;
  DateTime? _cachedAt;
  String? _error;
  Timer? _notificationsPollingTimer;

  List<Property> get properties => _properties;
  Set<String> get favoritePropertyIds => _favoritePropertyIds;
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((item) => !item.isRead).toList();
  int get unreadNotificationsCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isFromCache => _isFromCache;
  bool get hasMore => _hasMore;
  DateTime? get cachedAt => _cachedAt;
  String? get error => _error;
  bool get hasProperties => _properties.isNotEmpty;

  Future<Property?> fetchPropertyById(String id) =>
      _repository.getPropertyById(id);

  bool isFavorite(String propertyId) =>
      _favoritePropertyIds.contains(propertyId);
  bool isFavoriteActionInFlight(String propertyId) =>
      _favoriteActionInFlight.contains(propertyId);

  // Cache-then-network: paint cached properties instantly, then replace them
  // with fresh data if the network call succeeds. If we're offline, whatever
  // is on screen stays on screen.
  Future<void> fetchProperties() async {
    _clearError();

    final cached = await _cache.readFirstPage();
    if (cached != null && cached.isNotEmpty) {
      _properties = cached;
      _isFromCache = true;
      _cachedAt = await _cache.readCachedAt();
      _hasMore = cached.length >= _pageSize;
      _currentPage = 1;
      notifyListeners();
    }

    _setLoading(true);
    try {
      final page = await _repository.getPropertiesPage(
        page: 1,
        limit: _pageSize,
      );
      _properties = page.items;
      _currentPage = page.page;
      _hasMore = page.hasMore;
      _isFromCache = false;
      _cachedAt = null;
      await _cache.writeFirstPage(page.items);

      // Favorites live on a different endpoint. their success is independent
      // of the property fetch. If offline, leave whatever we already have.
      try {
        _favoritePropertyIds = await _repository.getFavoritePropertyIds();
      } on DioException {
        // keep previous favorites in memory
      }
      notifyListeners();
    } on DioException catch (e) {
      if (_properties.isEmpty) {
        _error = _isOffline(e)
            ? 'No connection and no cached listings yet'
            : 'Error loading listings';
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final next = await _repository.getPropertiesPage(
        page: _currentPage + 1,
        limit: _pageSize,
      );
      if (next.items.isNotEmpty) {
        _properties = [..._properties, ...next.items];
        _currentPage = next.page;
      }
      _hasMore = next.hasMore;
    } on DioException {
      // Offline or server error while paginating: stop trying to load more for
      // this session; the user can retry by pulling-to-refresh (retryProperties).
      _hasMore = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
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
    await fetchProperties();
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

  bool _isOffline(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    stopNotificationsPolling();
    super.dispose();
  }
}
