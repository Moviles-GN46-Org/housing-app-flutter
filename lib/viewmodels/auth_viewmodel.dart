import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  AuthViewModel(this._repository);

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );

      await StorageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      _currentUser = response.user;
    } on Exception catch (e) {
      _error = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phone: phone,
      );

      await StorageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      _currentUser = response.user;
    } on Exception catch (e) {
      _error = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await StorageService.getAccessToken();
    if (token == null) return;

    _setLoading(true);

    try {
      _currentUser = await _repository.getMe();
    } on Exception {
      await StorageService.clearTokens();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await StorageService.clearTokens();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  String _parseError(Exception e) {
    final message = e.toString();
    if (message.contains('401')) return 'Invalid email or password.';
    if (message.contains('409'))
      return 'An account with this email already exists.';
    if (message.contains('SocketException')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }
}
