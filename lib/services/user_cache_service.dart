import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/user.dart';

class UserCacheService {
  static final CacheManager _manager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 1,
    ),
  );

  static const String _cacheKey = 'currentUserCache';
  static const String _fileKey = 'me';

  Future<User?> read() async {
    try {
      final file = await _manager.getFileFromCache(_fileKey);
      if (file == null) return null;
      final bytes = await file.file.readAsBytes();
      final data = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      debugPrint('UserCacheService.read failed: $e');
      return null;
    }
  }

  Future<void> write(User user) async {
    try {
      final bytes = utf8.encode(json.encode(user.toJson()));
      await _manager.putFile(
        _fileKey,
        Uint8List.fromList(bytes),
        fileExtension: 'json',
      );
    } catch (e) {
      debugPrint('UserCacheService.write failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _manager.removeFile(_fileKey);
    } catch (e) {
      debugPrint('UserCacheService.clear failed: $e');
    }
  }
}
