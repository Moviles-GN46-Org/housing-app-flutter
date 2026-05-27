import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:uuid/uuid.dart';

import '../models/offline_action.dart';
import '../repositories/property_repository.dart';
import '../repositories/chat_repository.dart'; 

class OfflineQueueService extends ChangeNotifier {
  OfflineQueueService({
    required PropertyRepository propertyRepository,
    required ChatRepository chatRepository, 
  })  : _propertyRepository = propertyRepository,
        _chatRepository = chatRepository;

  final PropertyRepository _propertyRepository;
  final ChatRepository _chatRepository;

  static const _manifestKey = 'offline_queue_manifest';
  static const _maxAttempts = 5;
  static const _uuid = Uuid();

  static final _cache = CacheManager(
    Config(
      'offlineActionQueue',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
    ),
  );

  final List<OfflineAction> _queue = [];
  bool _isProcessing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool hasPendingReviewForProperty(String propertyId) => _queue.any(
    (a) =>
        a.type == OfflineActionType.submitReview &&
        a.payload['propertyId'] == propertyId,
  );

  bool hasPendingFavoriteToggle(String propertyId) => _queue.any(
    (a) =>
        a.type == OfflineActionType.toggleFavorite &&
        a.payload['propertyId'] == propertyId,
  );

  Future<void> init() async {
    await _loadManifest();
    _listenToConnectivity();
    unawaited(flush());
  }

  void _listenToConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online =
          results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      if (online) unawaited(flush());
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> enqueueReview({
    required String propertyId,
    required int rating,
    required String comment,
  }) async {
    final action = OfflineAction(
      id: _uuid.v4(),
      type: OfflineActionType.submitReview,
      payload: {'propertyId': propertyId, 'rating': rating, 'comment': comment},
      queuedAt: DateTime.now(),
    );
    await _enqueue(action);
  }

  Future<void> enqueueFavoriteToggle({required String propertyId}) async {
    final existing = _queue.indexWhere(
      (a) =>
          a.type == OfflineActionType.toggleFavorite &&
          a.payload['propertyId'] == propertyId,
    );
    if (existing != -1) {
      await _dequeue(_queue[existing].id);
      return;
    }

    final action = OfflineAction(
      id: _uuid.v4(),
      type: OfflineActionType.toggleFavorite,
      payload: {'propertyId': propertyId},
      queuedAt: DateTime.now(),
    );
    await _enqueue(action);
  }

  /// Encola un mensaje de chat para enviarlo de forma eventual al recuperar conexión
  Future<void> enqueueMessage({
    required String chatId,
    required String content,
  }) async {
    final action = OfflineAction(
      id: _uuid.v4(),
      type: OfflineActionType.sendMessage,
      payload: {'chatId': chatId, 'content': content},
      queuedAt: DateTime.now(),
    );
    await _enqueue(action);
  }

  Future<void> flush() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    final snapshot = List<OfflineAction>.from(_queue);

    for (final action in snapshot) {
      final shouldContinue = await _replay(action);
      if (!shouldContinue) break;
    }

    _isProcessing = false;
  }

  Future<bool> _replay(OfflineAction action) async {
    try {
      switch (action.type) {
        case OfflineActionType.submitReview:
          await _propertyRepository.createReview(
            propertyId: action.payload['propertyId'] as String,
            rating: action.payload['rating'] as int,
            comment: action.payload['comment'] as String,
          );
          await _dequeue(action.id);
          break;

        case OfflineActionType.toggleFavorite:
          await _propertyRepository.toggleFavorite(
            action.payload['propertyId'] as String,
          );
          await _dequeue(action.id);
          break;

        case OfflineActionType.sendMessage:
          await _chatRepository.sendMessage(
            action.payload['chatId'] as String,
            action.payload['content'] as String,
          );
          await _dequeue(action.id);
          break;
      }
      return true;
    } on DioException catch (e) {
      if (_isOfflineError(e)) return false;
      final status = e.response?.statusCode;
      if (status == 409) {
        await _dequeue(action.id);
        return true;
      }
      await _incrementOrDrop(action);
      return true;
    } on ReviewSubmitException {
      await _dequeue(action.id);
      return true;
    } catch (e) {
      debugPrint('OfflineQueueService: unexpected error during replay: $e');
      await _incrementOrDrop(action);
      return true;
    }
  }

  Future<void> _enqueue(OfflineAction action) async {
    _queue.add(action);
    await _persistEntry(action);
    await _persistManifest();
    notifyListeners();
  }

  Future<void> _dequeue(String id) async {
    _queue.removeWhere((a) => a.id == id);
    await _cache.removeFile(id);
    await _persistManifest();
    notifyListeners();
  }

  Future<void> _incrementOrDrop(OfflineAction action) async {
    if (action.attempts + 1 >= _maxAttempts) {
      debugPrint(
        'OfflineQueueService: dropping ${action.id} after $_maxAttempts attempts',
      );
      await _dequeue(action.id);
    } else {
      final updated = action.copyWith(attempts: action.attempts + 1);
      final idx = _queue.indexWhere((a) => a.id == action.id);
      if (idx != -1) _queue[idx] = updated;
      await _persistEntry(updated);
      await _persistManifest();
    }
  }

  bool _isOfflineError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.error is SocketException;

  Future<void> _persistManifest() async {
    final ids = _queue.map((a) => a.id).toList();
    final bytes = utf8.encode(jsonEncode(ids));
    await _cache.putFile(_manifestKey, Uint8List.fromList(bytes));
  }

  Future<void> _persistEntry(OfflineAction action) async {
    final bytes = utf8.encode(jsonEncode(action.toJson()));
    await _cache.putFile(action.id, Uint8List.fromList(bytes));
  }

  Future<void> _loadManifest() async {
    _queue.clear();
    try {
      final manifestFile = await _cache.getFileFromCache(_manifestKey);
      if (manifestFile == null) return;

      final raw = await manifestFile.file.readAsString();
      final ids = (jsonDecode(raw) as List).cast<String>();

      for (final id in ids) {
        final entryFile = await _cache.getFileFromCache(id);
        if (entryFile == null) continue;
        final entryRaw = await entryFile.file.readAsString();
        _queue.add(
          OfflineAction.fromJson(jsonDecode(entryRaw) as Map<String, dynamic>),
        );
      }
    } catch (e) {
      debugPrint('OfflineQueueService: failed to load manifest: $e');
    }
    if (_queue.isNotEmpty) notifyListeners();
  }
}