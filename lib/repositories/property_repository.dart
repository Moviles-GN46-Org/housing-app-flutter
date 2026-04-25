import '../models/property_model.dart';
import '../services/api_client.dart';

class PropertyPage {
  final List<Property> items;
  final int total;
  final int page;
  final int limit;

  const PropertyPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  bool get hasMore => page * limit < total;
}

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

  Future<PropertyPage> getPropertiesPage({
    required int page,
    required int limit,
  }) async {
    final response = await _api.get(
      '/properties',
      queryParams: {'page': page, 'limit': limit},
    );

    if (response.statusCode != 200 || response.data['success'] != true) {
      return PropertyPage(items: const [], total: 0, page: page, limit: limit);
    }

    final data = response.data['data'];
    final rawList = (data is Map && data['properties'] is List)
        ? data['properties'] as List
        : const [];
    final items = rawList
        .map((item) => Property.fromJson(item as Map<String, dynamic>))
        .toList();

    return PropertyPage(
      items: items,
      total: (data is Map && data['total'] is int) ? data['total'] as int : items.length,
      page: (data is Map && data['page'] is int) ? data['page'] as int : page,
      limit: (data is Map && data['limit'] is int) ? data['limit'] as int : limit,
    );
  }

  Future<Set<String>> getFavoritePropertyIds() async {
    final response = await _api.get('/favorites/ids/list');

    if (response.statusCode != 200) return <String>{};

    final responseData = response.data;
    final dynamic data = responseData is Map<String, dynamic>
        ? responseData['data']
        : null;

    final List<dynamic> rawIds = (data is List)
        ? data
        : (data is Map<String, dynamic>)
        ? _extractIdsFromMap(data)
        : <dynamic>[];

    return rawIds.map((id) => id.toString()).toSet();
  }

  Future<bool> toggleFavorite(String propertyId) async {
    final response = await _api.put('/favorites/$propertyId');
    return response.statusCode == 200;
  }

  List<dynamic> _extractIdsFromMap(Map<String, dynamic> data) {
    if (data['ids'] is List) return data['ids'] as List<dynamic>;
    if (data['favoriteIds'] is List) {
      return data['favoriteIds'] as List<dynamic>;
    }
    if (data['propertyIds'] is List)
      return data['propertyIds'] as List<dynamic>;
    if (data['favorites'] is List) return data['favorites'] as List<dynamic>;
    return <dynamic>[];
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
