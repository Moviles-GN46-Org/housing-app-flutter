import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/property_model.dart';

class MapViewModel extends ChangeNotifier {
  final String _baseUrl = "http://localhost:3000/api/properties";
  
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

  Future<void> fetchProperties(String token) async {
    debugPrint("MapViewModel: Initializing fetchProperties...");
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("MapViewModel: Response status code ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
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
      } else {
        debugPrint("MapViewModel: Server error: ${response.body}");
      }
    } catch (e) {
      debugPrint("MapViewModel: Connection error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}