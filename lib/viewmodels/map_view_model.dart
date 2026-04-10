import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/property_model.dart';
import '../repositories/property_repository.dart';

class MapViewModel extends ChangeNotifier {
  final PropertyRepository _propertyRepository;
  MapViewModel(this._propertyRepository);

  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  List<Property> get properties => _filteredProperties;

  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get averageRentFormatted {
    if (_filteredProperties.isEmpty) return "No close listings";
    double total = _filteredProperties.fold(
      0.0,
      (sum, item) => sum + item.monthlyRent,
    );
    double avg = total / _filteredProperties.length;
    return "\$${(avg / 1000000).toStringAsFixed(2)}M COP";
  }

  Future<void> initializeMap() async {
    _isLoading = true;
    notifyListeners();

    try {
      Position position = await _determinePosition();
      _userLocation = LatLng(position.latitude, position.longitude);

      _allProperties = await _propertyRepository.getProperties();

      _filterPropertiesByDistance();
    } catch (e) {
      debugPrint("Error initializing map: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _filterPropertiesByDistance() {
    if (_userLocation == null) return;

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
