import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // A JWT is three base64url-encoded strings separated by dots:
  //   header.payload.signature
  // Only the backend can verify the signature (it holds the key), but the
  // payload is readable by anyone — that's by design. We only need `exp` to
  // decide locally whether the token is still valid, so we never touch the
  // signature.
  static Future<Map<String, dynamic>?> decodeAccessTokenPayload() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      // base64Url.normalize adds the '=' padding that JWTs strip out.
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasValidAccessToken() async {
    final payload = await decodeAccessTokenPayload();
    final exp = payload?['exp'];
    if (exp is! int) return false;
    return DateTime.now().millisecondsSinceEpoch < exp * 1000;
  }
}
