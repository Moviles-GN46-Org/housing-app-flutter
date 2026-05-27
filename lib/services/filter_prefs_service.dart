import 'package:hive/hive.dart';

// S3: Local storage

class FilterPrefsService {
  final Box _box;

  FilterPrefsService(this._box);

  String get budget => (_box.get('filter_budget') as String?) ?? '';
  String get amenities => (_box.get('filter_amenities') as String?) ?? '';
  String get location => (_box.get('filter_location') as String?) ?? '';
  String get utilities => (_box.get('filter_utilities') as String?) ?? '';

  void save({
    required String budget,
    required String amenities,
    required String location,
    required String utilities,
  }) {
    _box.put('filter_budget', budget);
    _box.put('filter_amenities', amenities);
    _box.put('filter_location', location);
    _box.put('filter_utilities', utilities);
  }
}
