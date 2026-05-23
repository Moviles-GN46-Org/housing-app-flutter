import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/property_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/property_repository.dart';
import '../services/analytics_service.dart';
import '../services/offline_queue_service.dart';
import '../services/property_cache_service.dart';

class HomeViewModel extends ChangeNotifier {
  final PropertyRepository _repository;
  final NotificationRepository _notificationRepository;
  final PropertyCacheService _cache;
  final AnalyticsService? _analyticsService;
  final OfflineQueueService? _offlineQueue;

  HomeViewModel(
    this._repository,
    this._notificationRepository, {
    PropertyCacheService? cache,
    AnalyticsService? analyticsService,
    OfflineQueueService? offlineQueue,
  }) : _cache = cache ?? PropertyCacheService(),
       _analyticsService = analyticsService,
       _offlineQueue = offlineQueue;

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
  String _searchQuery = '';
  String _budgetFilter = '';
  String _amenitiesFilter = '';
  String _locationFilter = '';
  String _utilitiesFilter = '';
  Timer? _notificationsPollingTimer;

  List<Property> get properties {
    final sorted = List<Property>.from(_properties);
    sorted.sort((a, b) {
      final aFav = _favoritePropertyIds.contains(a.id);
      final bFav = _favoritePropertyIds.contains(b.id);
      if (aFav != bFav) return aFav ? -1 : 1;
      if (a.hasImage != b.hasImage) return a.hasImage ? -1 : 1;
      return 0;
    });
    return sorted;
  }

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
  String get searchQuery => _searchQuery;
  String get budgetFilter => _budgetFilter;
  String get amenitiesFilter => _amenitiesFilter;
  String get locationFilter => _locationFilter;
  String get utilitiesFilter => _utilitiesFilter;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _budgetFilter.isNotEmpty ||
      _amenitiesFilter.isNotEmpty ||
      _locationFilter.isNotEmpty ||
      _utilitiesFilter.isNotEmpty;

  List<Property> get filteredProperties {
    var result = properties;
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) {
        return p.title.toLowerCase().contains(_searchQuery) ||
            p.address.toLowerCase().contains(_searchQuery) ||
            p.neighborhood.toLowerCase().contains(_searchQuery) ||
            (p.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    if (_budgetFilter.isNotEmpty) {
      result = result.where(_matchesBudget).toList();
    }
    if (_amenitiesFilter.isNotEmpty) {
      result = result.where(_matchesAmenity).toList();
    }
    if (_locationFilter.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.neighborhood.toLowerCase() == _locationFilter.toLowerCase(),
          )
          .toList();
    }
    if (_utilitiesFilter.isNotEmpty) {
      result = result.where(_matchesUtilities).toList();
    }
    return result;
  }

  Future<Property?> fetchPropertyById(String id) =>
      _repository.getPropertyById(id);

  bool isFavorite(String propertyId) =>
      _favoritePropertyIds.contains(propertyId);
  bool isFavoriteActionInFlight(String propertyId) =>
      _favoriteActionInFlight.contains(propertyId);

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setBudgetFilter(String value) {
    _budgetFilter = value;
    if (value.isNotEmpty) {
      _analyticsService?.logSearchFilterUsages([
        {'category': 'budget', 'value': value},
      ]);
    }
    notifyListeners();
  }

  void setAmenitiesFilter(String value) {
    _amenitiesFilter = value;
    if (value.isNotEmpty) {
      _analyticsService?.logSearchFilterUsages([
        {'category': 'amenities', 'value': value},
      ]);
    }
    notifyListeners();
  }

  void setLocationFilter(String value) {
    _locationFilter = value;
    if (value.isNotEmpty) {
      _analyticsService?.logSearchFilterUsages([
        {'category': 'location', 'value': value},
      ]);
    }
    notifyListeners();
  }

  void setUtilitiesFilter(String value) {
    _utilitiesFilter = value;
    if (value.isNotEmpty) {
      _analyticsService?.logSearchFilterUsages([
        {'category': 'utilities', 'value': value},
      ]);
    }
    notifyListeners();
  }

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

      try {
        _favoritePropertyIds = await _repository.getFavoritePropertyIds();
      } on DioException catch (_) {}
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
        _revertFavorite(propertyId, wasFavorite);
        return false;
      }
      return true;
    } on DioException catch (e) {
      if (_isOfflineError(e)) {
        await _offlineQueue?.enqueueFavoriteToggle(propertyId: propertyId);
        return true;
      }
      _revertFavorite(propertyId, wasFavorite);
      return false;
    } catch (_) {
      _revertFavorite(propertyId, wasFavorite);
      return false;
    } finally {
      _favoriteActionInFlight.remove(propertyId);
      notifyListeners();
    }
  }

  void _revertFavorite(String propertyId, bool wasFavorite) {
    if (wasFavorite) {
      _favoritePropertyIds.add(propertyId);
    } else {
      _favoritePropertyIds.remove(propertyId);
    }
    notifyListeners();
  }

  bool _isOfflineError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.error is SocketException;

  bool _matchesBudget(Property p) {
    switch (_budgetFilter) {
      case 'Under \$600k':
        return p.monthlyRent < 600000;
      case '\$600k - \$900k':
        return p.monthlyRent >= 600000 && p.monthlyRent <= 900000;
      case '\$900k - \$1.2M':
        return p.monthlyRent > 900000 && p.monthlyRent <= 1200000;
      case 'Above \$1.2M':
        return p.monthlyRent > 1200000;
      default:
        return true;
    }
  }

  bool _matchesAmenity(Property p) {
    switch (_amenitiesFilter) {
      case 'Wi-Fi':
        return p.hasWifi;
      case 'Parking':
        return p.hasParking;
      case 'Laundry':
        return p.hasLaundry;
      case 'Furnished':
        return p.furnished;
      default:
        return true;
    }
  }

  bool _matchesUtilities(Property p) {
    switch (_utilitiesFilter) {
      case 'Included':
        return p.includesUtilities;
      case 'Separate':
        return !p.includesUtilities;
      default:
        return true;
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
