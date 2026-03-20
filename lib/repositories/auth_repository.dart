import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phone,
  }) async {
    final response = await _api.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        if (phone != null) 'phone': phone,
      },
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<User> getMe() async {
    final response = await _api.get('/auth/me');
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
