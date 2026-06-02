import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/property_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/property_repository.dart';
import '../services/analytics_service.dart';
import '../services/filter_prefs_service.dart';
import '../services/offline_queue_service.dart';
import '../services/property_cache_service.dart';

class HomeViewModel extends ChangeNotifier {
  final PropertyRepository _repository;
  final NotificationRepository _notificationRepository;
  final PropertyCacheService _cache;
  final AnalyticsService? _analyticsService;
  final OfflineQueueService? _offlineQueue;
  final FilterPrefsService? _filterPrefs;

  HomeViewModel(
    this._repository,
    this._notificationRepository, {
    PropertyCacheService? cache,
    AnalyticsService? analyticsService,
    OfflineQueueService? offlineQueue,
    FilterPrefsService? filterPrefs,
  }) : _cache = cache ?? PropertyCacheService(),
       _analyticsService = analyticsService,
       _offlineQueue = offlineQueue,
       _filterPrefs = filterPrefs {
    if (filterPrefs != null) {
      _budgetFilter = filterPrefs.budget;
      _amenitiesFilter = filterPrefs.amenities;
      _locationFilter = filterPrefs.location;
      _utilitiesFilter = filterPrefs.utilities;
    }
  }

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
  Timer? _searchDebounce;
  List<Property> _topRatedNearby = const [];
  bool _isLoadingTopRated = false;
  List<Property>? _sortedPropertiesCache;
  List<Property>? _filteredPropertiesCache;
  List<String>? _sortedNeighborhoodsCache;
  bool _isSortCacheDirty = true;
  bool _isFilteredCacheDirty = true;
  bool _isNeighborhoodsCacheDirty = true;

  List<Property> get properties {
    if (_isSortCacheDirty || _sortedPropertiesCache == null) {
      final sorted = List<Property>.from(_properties);
      sorted.sort((a, b) {
        final aFav = _favoritePropertyIds.contains(a.id);
        final bFav = _favoritePropertyIds.contains(b.id);
        if (aFav != bFav) return aFav ? -1 : 1;
        if (a.hasImage != b.hasImage) return a.hasImage ? -1 : 1;
        return 0;
      });
      _sortedPropertiesCache = List<Property>.unmodifiable(sorted);
      _isSortCacheDirty = false;
    }
    return _sortedPropertiesCache!;
  }

  Set<String> get favoritePropertyIds => _favoritePropertyIds;
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((item) => !item.isRead).toList();
  int get unreadNotificationsCount =>
      _notifications.where((item) => !item.isRead).length;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isFromCache => _isFromCache;
  bool get hasMore => _hasMore;
  DateTime? get cachedAt => _cachedAt;
  String? get error => _error;
  bool get hasProperties => _properties.isNotEmpty;
  List<Property> get topRatedNearby => _topRatedNearby;
  bool get isLoadingTopRated => _isLoadingTopRated;
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
    if (_isFilteredCacheDirty || _filteredPropertiesCache == null) {
      var result = properties;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        result = result.where((p) {
          return p.title.toLowerCase().contains(query) ||
              p.address.toLowerCase().contains(query) ||
              p.neighborhood.toLowerCase().contains(query) ||
              (p.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      if (_budgetFilter.isNotEmpty) {
        result = result.where(_matchesBudget).toList();
      }
      if (_amenitiesFilter.isNotEmpty) {
        result = result.where(_matchesAmenity).toList();
      }
      if (_locationFilter.isNotEmpty) {
        final normalizedLocationFilter = _locationFilter.toLowerCase();
        result = result
            .where(
              (p) => p.neighborhood.toLowerCase() == normalizedLocationFilter,
            )
            .toList();
      }
      if (_utilitiesFilter.isNotEmpty) {
        result = result.where(_matchesUtilities).toList();
      }
      _filteredPropertiesCache = List<Property>.unmodifiable(result);
      _isFilteredCacheDirty = false;
    }

    return _filteredPropertiesCache!;
  }

  List<String> neighborhoodSuggestions(String query) {
    if (_isNeighborhoodsCacheDirty || _sortedNeighborhoodsCache == null) {
      final neighborhoods =
          _properties
              .map((p) => p.neighborhood)
              .where((n) => n.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      _sortedNeighborhoodsCache = List<String>.unmodifiable(neighborhoods);
      _isNeighborhoodsCacheDirty = false;
    }

    if (query.isEmpty) {
      return _sortedNeighborhoodsCache!;
    }

    final normalized = query.trim().toLowerCase();
    return _sortedNeighborhoodsCache!
        .where((n) => n.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  Future<Property?> fetchPropertyById(
    String id,
  ) => // S3: Future (no handler, no async await)
      _repository.getPropertyById(id);

  bool isFavorite(String propertyId) =>
      _favoritePropertyIds.contains(propertyId);
  bool isFavoriteActionInFlight(String propertyId) =>
      _favoriteActionInFlight.contains(propertyId);

  void setSearchQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (_searchQuery == normalized) return;
    _searchQuery = normalized;
    _markFilteredCacheDirty();
    notifyListeners();

    _searchDebounce?.cancel();
    if (normalized.isNotEmpty) {
      _searchDebounce = Timer(const Duration(milliseconds: 600), () {
        _analyticsService?.logSearchQuery(normalized);
      });
    }
  }

  void setBudgetFilter(String value) {
    if (_budgetFilter == value) return;
    _budgetFilter = value;
    _markFilteredCacheDirty();
    if (value.isNotEmpty) {
      _analyticsService?.logSearchFilterUsages([
        {'category': 'budget', 'value': value},
      ]);
    }
    _saveFilterPrefs();
    notifyListeners();
  }

  void setAmenitiesFilter(String value) {
    if (_amenitiesFilter == value) return;
    _amenitiesFilter = value;
    _markFilteredCacheDirty();
    if (value.isNotEmpty) {
      _analyticsService?.logSearchFilterUsages([
        {'category': 'amenities', 'value': value},
      ]);
    }
    _saveFilterPrefs();
    notifyListeners();
  }

  void setLocationFilter(String value) {
    if (_locationFilter == value) return;
    _locationFilter = value;
    _markFilteredCacheDirty();
    if (value.isNotEmpty) {
      _analyticsService?.logSearchFilterUsages([
        {'category': 'location', 'value': value},
      ]);
    }
    _saveFilterPrefs();
    notifyListeners();
  }

  void setUtilitiesFilter(String value) {
    if (_utilitiesFilter == value) return;
    _utilitiesFilter = value;
    _markFilteredCacheDirty();
    if (value.isNotEmpty) {
      _analyticsService?.logSearchFilterUsages([
        {'category': 'utilities', 'value': value},
      ]);
    }
    _saveFilterPrefs();
    notifyListeners();
  }

  void _saveFilterPrefs() {
    _filterPrefs?.save(
      budget: _budgetFilter,
      amenities: _amenitiesFilter,
      location: _locationFilter,
      utilities: _utilitiesFilter,
    );
  }

  Future<void> fetchProperties() async {
    _clearError();

    final cached = await _cache.readFirstPage();
    if (cached != null && cached.isNotEmpty) {
      _properties = cached;
      _markPropertyDerivedCachesDirty();
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
      _markPropertyDerivedCachesDirty();
      _currentPage = page.page;
      _hasMore = page.hasMore;
      _isFromCache = false;
      _cachedAt = null;
      await _cache.writeFirstPage(page.items);

      try {
        _favoritePropertyIds = await _repository.getFavoritePropertyIds();
        _isSortCacheDirty = true;
        _isFilteredCacheDirty = true;
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

  Future<void> fetchTopRatedNearby({
    required double lat,
    required double lng,
    double radiusKm = 25.0,
    int limit = 5,
  }) async {
    if (_isLoadingTopRated) return;
    _isLoadingTopRated = true;
    notifyListeners();

    try {
      _topRatedNearby = await _repository.getTopRatedNearby(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        limit: limit,
      );
    } finally {
      _isLoadingTopRated = false;
      notifyListeners();
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
        _markPropertyDerivedCachesDirty();
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
    _isSortCacheDirty = true;
    _isFilteredCacheDirty = true;
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
    _isSortCacheDirty = true;
    _isFilteredCacheDirty = true;
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
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _markPropertyDerivedCachesDirty() {
    _isSortCacheDirty = true;
    _isFilteredCacheDirty = true;
    _isNeighborhoodsCacheDirty = true;
  }

  void _markFilteredCacheDirty() {
    _isFilteredCacheDirty = true;
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    stopNotificationsPolling();
    super.dispose();
  }
}
