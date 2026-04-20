import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/property_model.dart';
import 'home_viewmodel.dart';
import 'strategies/favorite_proximity_strategy.dart';
import 'strategies/movement_detection_strategy.dart';

class MapSuggestion {
  final Property property;
  final double distanceMeters;

  const MapSuggestion({required this.property, required this.distanceMeters});
}

class MainPageViewModel extends ChangeNotifier {
  MainPageViewModel({
    required HomeViewModel homeViewModel,
    required MovementDetectionStrategy movementStrategy,
    required FavoriteProximityStrategy proximityStrategy,
  }) : _homeViewModel = homeViewModel,
       _movementStrategy = movementStrategy,
       _proximityStrategy = proximityStrategy;

  HomeViewModel _homeViewModel;
  final MovementDetectionStrategy _movementStrategy;
  final FavoriteProximityStrategy _proximityStrategy;

  StreamSubscription<Position>? _positionSubscription;
  Position? _previousPosition;
  DateTime? _lastCheckAt;
  DateTime? _lastPromptAt;
  String? _lastPromptPropertyId;
  MapSuggestion? _pendingSuggestion;
  int _currentPage = 0;

  static const Duration _checkThrottle = Duration(seconds: 5);
  static const Duration _promptCooldown = Duration(minutes: 10);
  static const Duration _initialStartupDelay = Duration(seconds: 2);

  void updateHomeViewModel(HomeViewModel homeViewModel) {
    _homeViewModel = homeViewModel;
  }

  void setCurrentPage(int pageIndex) {
    _currentPage = pageIndex;
  }

  Future<void> startMonitoring() async {
    if (_positionSubscription != null) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 0,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPositionUpdate);
  }

  void stopMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  MapSuggestion? consumePendingSuggestion() {
    final suggestion = _pendingSuggestion;
    _pendingSuggestion = null;
    return suggestion;
  }

  void _onPositionUpdate(Position position) {
    if (_currentPage == 1) {
      _previousPosition = position;
      return;
    }

    final now = DateTime.now();
    if (_lastCheckAt != null &&
        now.difference(_lastCheckAt!) < _checkThrottle) {
      _previousPosition = position;
      return;
    }
    _lastCheckAt = now;

    final isMoving = _movementStrategy.isMoving(
      currentPosition: position,
      previousPosition: _previousPosition,
    );
    _previousPosition = position;

    if (!isMoving) {
      return;
    }

    if (_homeViewModel.properties.isEmpty ||
        _homeViewModel.favoritePropertyIds.isEmpty) {
      return;
    }

    final closest = _proximityStrategy.findClosestFavorite(
      userPosition: position,
      properties: _homeViewModel.properties,
      favoritePropertyIds: _homeViewModel.favoritePropertyIds,
    );

    if (closest == null) {
      return;
    }

    if (_lastPromptAt != null &&
        now.difference(_lastPromptAt!) < _promptCooldown &&
        _lastPromptPropertyId == closest.property.id) {
      return;
    }

    _lastPromptAt = now;
    _lastPromptPropertyId = closest.property.id;
    _pendingSuggestion = MapSuggestion(
      property: closest.property,
      distanceMeters: closest.distanceMeters,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
