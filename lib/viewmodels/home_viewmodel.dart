import 'package:flutter/foundation.dart';
import '../models/property_model.dart';
import '../repositories/property_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final PropertyRepository _repository;

  HomeViewModel(this._repository);

  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;

  List<Property> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProperties => _properties.isNotEmpty;

  Future<void> fetchProperties() async {
    _setLoading(true);
    _clearError();

    try {
      _properties = await _repository.getProperties();
    } catch (e) {
      _error = 'Failed to load properties: ${e.toString()}';
      debugPrint('HomeViewModel: Error fetching properties - $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProperties() async {
    await fetchProperties();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
