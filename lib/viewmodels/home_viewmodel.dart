import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProperties() async {
    await fetchProperties();
  }

  Future<void> retryProperties() async {
    _setLoading(true);
    _clearError();

    try {
      _properties = await _repository.getProperties();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _repository.refreshAccessToken();
        if (refreshed) {
          try {
            _properties = await _repository.getProperties();
          } catch (retryError) {}
        }
      }
    } catch (e) {
    } finally {
      _setLoading(false);
    }
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
