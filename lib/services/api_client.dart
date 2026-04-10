import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiClient {
  // TODO: CHANGE BASED ON WHAT YOU'RE USING (EMULATOR, SIMULATOR, OR WEB)
  static const String _baseUrl =
      'http://10.0.2.2:3000/api'; // Use the IP address for Android emulator
  // static const String _baseUrl =
  //     'http://localhost:3000/api'; // Use localhost for iOS simulator and web
  final Dio _dio;

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _attachToken, onError: _handleError),
    );
  }

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await StorageService.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final token = await StorageService.getAccessToken();
        error.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.fetch(error.requestOptions);
        return handler.resolve(response);
      }
      await StorageService.clearTokens();
    }
    handler.next(error);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '$_baseUrl/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final newAccessToken = response.data['data']['accessToken'] as String;
      final currentRefresh = await StorageService.getRefreshToken();
      await StorageService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: currentRefresh!,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<bool> refreshAccessToken() => _tryRefreshToken();
}
