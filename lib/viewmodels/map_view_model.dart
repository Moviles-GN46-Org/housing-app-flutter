import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/api_client.dart'; 

class MapViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Property> _properties = [];
  List<Property> get properties => _properties;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double get averageRent {
    if (_properties.isEmpty) return 0.0;
    double total = _properties.fold(0, (sum, item) => sum + item.monthlyRent);
    return total / _properties.length;
  }

  String get averageRentFormatted {
    if (_properties.isEmpty) return "Calculating...";
    return "\$${(averageRent / 1000000).toStringAsFixed(2)}M COP";
  }

  Future<void> fetchProperties() async {
    debugPrint("MapViewModel: Fetching properties using ApiClient...");
    
    _isLoading = true;
    notifyListeners();

    try {
      // Usamos el cliente de David que ya tiene el /api y el Token incluido
      final response = await _apiClient.get('/properties');

      debugPrint("MapViewModel: Response received with status ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = response.data; // En Dio ya es un Map
        
        if (responseData['success'] == true) {
          var rawData = responseData['data'];
          List<dynamic> propertiesList = [];

          if (rawData is List) {
            propertiesList = rawData;
          } else if (rawData is Map && rawData.containsKey('properties')) {
            propertiesList = rawData['properties'];
          } else if (rawData is Map && rawData.containsKey('data')) {
            propertiesList = rawData['data'];
          }

          _properties = propertiesList.map((item) => Property.fromJson(item)).toList();
          debugPrint("MapViewModel: Successfully loaded ${_properties.length} properties.");
        }
      }
    } catch (e) {
      debugPrint("MapViewModel: Error fetching properties: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}