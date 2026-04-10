import '../models/property_model.dart';
import '../services/api_client.dart';

class PropertyRepository {
  final ApiClient _api;

  PropertyRepository(this._api);

  Future<List<Property>> getProperties() async {
    final response = await _api.get('/properties');

    if (response.statusCode == 200) {
      final responseData = response.data;

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

        return propertiesList
            .map((item) => Property.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<bool> refreshAccessToken() {
    return _api.refreshAccessToken();
  }

  Future<Property?> getPropertyById(String id) async {
    try {
      final response = await _api.get('/properties/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Property.fromJson(response.data['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}
