import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/property_model.dart';

// Caches the first page of Home properties as a single JSON blob so the user
// can see something on launch even without a network connection. A dedicated
// CacheManager keeps TTL/eviction isolated from the user cache and from image
// caching done by cached_network_image.
class PropertyCacheService {
  static final CacheManager _manager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 1,
    ),
  );

  static const String _cacheKey = 'propertyDataCache';
  static const String _firstPageKey = 'home_first_page_v1';

  Future<List<Property>?> readFirstPage() async {
    try {
      final file = await _manager.getFileFromCache(_firstPageKey);
      if (file == null) return null;
      final bytes = await file.file.readAsBytes();
      final list = json.decode(utf8.decode(bytes)) as List;
      return list
          .map((item) => Property.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('PropertyCacheService.readFirstPage failed: $e');
      return null;
    }
  }

  Future<DateTime?> readCachedAt() async {
    try {
      final file = await _manager.getFileFromCache(_firstPageKey);
      if (file == null) return null;
      return file.file.lastModifiedSync();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeFirstPage(List<Property> items) async {
    try {
      final payload = items.map((p) => p.toJson()).toList();
      final bytes = utf8.encode(json.encode(payload));
      await _manager.putFile(
        _firstPageKey,
        Uint8List.fromList(bytes),
        fileExtension: 'json',
      );
    } catch (e) {
      debugPrint('PropertyCacheService.writeFirstPage failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _manager.removeFile(_firstPageKey);
    } catch (e) {
      debugPrint('PropertyCacheService.clear failed: $e');
    }
  }
}
