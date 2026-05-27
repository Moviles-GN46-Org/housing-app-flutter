import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/storage_service.dart';
import '../services/user_cache_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final UserCacheService _userCache;

  AuthViewModel(this._repository, {UserCacheService? userCache})
    : _userCache = userCache ?? UserCacheService();

  User? _currentUser;
  bool _isLoading = false;
  bool _isCheckingStatus = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  bool get isCheckingStatus => _isCheckingStatus;
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
      await _userCache.write(response.user);
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
      await _userCache.write(response.user);
    } on Exception catch (e) {
      _error = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAuthStatus() async {
    if (!await StorageService.hasValidAccessToken()) {
      return;
    }

    _isCheckingStatus = true;
    _setLoading(true);

    try {
      final fresh = await _repository.getMe();
      _currentUser = fresh;
      await _userCache.write(fresh);
    } on DioException catch (e) {
      if (_isOfflineError(e)) {
        _currentUser = await _userCache.read() ?? await _userFromTokenClaims();
      } else {
        await StorageService.clearTokens();
        await _userCache.clear();
      }
    } on Exception {
      await StorageService.clearTokens();
      await _userCache.clear();
    } finally {
      _isCheckingStatus = false;
      _setLoading(false);
    }
  }

  bool _isOfflineError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.error is SocketException;
  }

  Future<User?> _userFromTokenClaims() async {
    final payload = await StorageService.decodeAccessTokenPayload();
    if (payload == null) return null;
    final id = payload['userId'];
    final role = payload['role'];
    final isVerified = payload['isVerified'];
    if (id is! String || role is! String || isVerified is! bool) return null;

    return User(
      id: id,
      email: '',
      firstName: '',
      lastName: '',
      role: role,
      isVerified: isVerified,
      authProvider: 'local',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> verifyEmail({required String code}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _repository.verifyEmail(code: code);

      await StorageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      _currentUser = response.user;
      await _userCache.write(response.user);
    } on Exception catch (e) {
      _error = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendCode() async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.resendCode();
    } on Exception catch (e) {
      _error = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await StorageService.clearTokens();
    await _userCache.clear();
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
    if (e is DioException) {
      if (_isOfflineError(e)) return 'No internet connection.';
      final status = e.response?.statusCode;
      if (status == 401) return 'Invalid email or password.';
      if (status == 409) return 'An account with this email already exists.';
      if (status == 422 || status == 400) {
        final body = e.response?.data;
        if (body is Map && body['message'] != null) {
          return body['message'].toString();
        }
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
