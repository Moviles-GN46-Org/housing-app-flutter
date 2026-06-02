import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/property_model.dart';
import '../repositories/property_repository.dart';
import '../services/analytics_service.dart';
import '../services/property_cache_service.dart'; 

class MapViewModel extends ChangeNotifier {
  final PropertyRepository _propertyRepository;
  final AnalyticsService _analyticsService;
  

  final PropertyCacheService _cacheService = PropertyCacheService();
  StreamSubscription? _connectivitySubscription;

  MapViewModel(this._propertyRepository, this._analyticsService) {
    _initConnectivityListener(); 
  }

  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  List<Property> get properties => _filteredProperties;

  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;


  bool _isOffline = false;
  bool get isOffline => _isOffline;


  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      bool wasOffline = _isOffline;
      _isOffline = result.contains(ConnectivityResult.none);
      

      if (wasOffline != _isOffline) {
        notifyListeners();

        if (!_isOffline && _allProperties.isEmpty) {
          initializeMap();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel(); 
    super.dispose();
  }

  String get averageRentFormatted {
    if (_filteredProperties.isEmpty) return "No hay ofertas cerca";
    double total = _filteredProperties.fold(
      0.0,
      (sum, item) => sum + item.monthlyRent,
    );
    double avg = total / _filteredProperties.length;
    return "\$${(avg / 1000000).toStringAsFixed(2)}M COP";
  }

  double get supplyDensity {
    if (_allProperties.isEmpty) return 0.0;
    return _filteredProperties.length / _allProperties.length;
  }

  String get supplyDensityFormatted {
    return "${(supplyDensity * 100).toStringAsFixed(1)}%";
  }

  Future<void> initializeMap() async {
    _isLoading = true;
    notifyListeners();

    try {

      try {
        Position position = await _determinePosition();
        _userLocation = LatLng(position.latitude, position.longitude);

        if (!_isOffline) {
          await _analyticsService.logLocationBQ(position.latitude, position.longitude);
        }
      } catch (locError) {
        debugPrint("Aviso: No se pudo obtener ubicación exacta: $locError");
      }

      var conn = await Connectivity().checkConnectivity();
      if (conn.contains(ConnectivityResult.none)) {

        _isOffline = true;
        _allProperties = await _cacheService.readFirstPage() ?? [];
        debugPrint("MODO OFFLINE: Mapa cargado desde el caché local (${_allProperties.length} propiedades)");
      } else {

        _isOffline = false;
        _allProperties = await _propertyRepository.getProperties();
        _analyticsService.logDeviceBrandOnMapOpen();

        await _cacheService.writeFirstPage(_allProperties);
        debugPrint("MODO ONLINE: Propiedades descargadas y guardadas en caché exitosamente.");
      }


      _filterPropertiesByDistance();
      
      if (!_isOffline && _userLocation != null) {
        await _logSupplyDensityAnalytics();
      }

    } catch (e) {

      debugPrint("Error general en el mapa: $e. Forzando modo offline.");
      _isOffline = true;
      _allProperties = await _cacheService.readFirstPage() ?? [];
      _filterPropertiesByDistance();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _filterPropertiesByDistance() {

    if (_userLocation == null) {
      _filteredProperties = List.from(_allProperties);
      return;
    }
    
    final Distance distance = const Distance();
    
    _filteredProperties = _allProperties.where((p) {
      double km = distance.as(
        LengthUnit.Kilometer,
        _userLocation!,
        LatLng(p.latitude, p.longitude),
      );
      return km <= 25.0; 
    }).toList();
  }

  Future<void> _logSupplyDensityAnalytics() async {
    await _analyticsService.logGenericEvent('SUPPLY_DENSITY_CHECK', {
      "value": supplyDensity,
      "nearby_count": _filteredProperties.length,
      "total_count": _allProperties.length,
      "coords": "${_userLocation?.latitude},${_userLocation?.longitude}"
    });
    debugPrint("Analítica de densidad procesada vía Outbox.");
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('Location permission denied.');
    }
    return await Geolocator.getCurrentPosition();
  }
}