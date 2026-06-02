import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/offline_queue_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final OfflineQueueService _offlineQueueService;
  final String chatId;
  final String currentUserId; 

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  StreamSubscription? _connectivitySubscription; // <-- NUEVO: Escucha la red

  bool _isOffline = false; // <-- NUEVO: Estado explícito de la red
  bool get isOffline => _isOffline;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChatViewModel({
    required ChatRepository chatRepository,
    required OfflineQueueService offlineQueueService,
    required this.chatId,
    required this.currentUserId,
  })  : _chatRepository = chatRepository,
        _offlineQueueService = offlineQueueService {
    _init();
  }

  void _init() {
    // 1. OFFLINE FIRST: Cargamos la caché local de inmediato
    _loadCachedMessages();
    
    // 2. Escuchamos cambios de red proactivamente
    _initConnectivityListener();
    
    // 3. Primera petición
    _fetchMessages();
    _startPolling();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final isCurrentlyOffline = result.contains(ConnectivityResult.none);
      
      if (_isOffline != isCurrentlyOffline) {
        _isOffline = isCurrentlyOffline;
        
        if (_isOffline) {
          _errorMessage = 'Sin conexión. Mostrando historial local.';
        } else {
          _errorMessage = null; // Se fue el error
          _fetchMessages(); // Volvió la red, descargamos mensajes nuevos
        }
        notifyListeners();
      }
    });
  }

  void _loadCachedMessages() {
    _messages = _chatRepository.getCachedMessages(chatId);
    notifyListeners();
  }

  Future<void> _fetchMessages() async {
    if (_isOffline) return; // Si sabemos que no hay red, no gastamos batería intentando
    
    if (_isLoading && _messages.isEmpty) return;
    if (_messages.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      String? afterTimestamp;
      if (_messages.isNotEmpty) {
        final confirmedMessages = _messages.where((m) => !m.isPending).toList();
        if (confirmedMessages.isNotEmpty) {
          afterTimestamp = confirmedMessages.last.createdAt.toIso8601String();
        }
      }

      final newMessages = await _chatRepository.getMessages(chatId, after: afterTimestamp);
      
      if (newMessages.isNotEmpty) {
        if (afterTimestamp == null) {
          _messages = newMessages; 
        } else {
          final existingIds = _messages.map((m) => m.id).toSet();
          for (var msg in newMessages) {
            if (!existingIds.contains(msg.id)) {
              _messages.add(msg);
            }
          }
        }
        notifyListeners();
      }
      _errorMessage = null;
    } catch (e) {
       // Silencioso, ya manejamos el error visual con el listener de red
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isOffline) _fetchMessages(); // Solo hacemos polling si hay internet
    });
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 1. UI OPTIMISTA: Mostramos el mensaje al usuario inmediatamente
    final tempId = const Uuid().v4();
    final tempMessage = ChatMessage(
      id: tempId,
      chatId: chatId,
      senderId: currentUserId, 
      type: 'TEXT',
      content: content,
      createdAt: DateTime.now(),
      isPending: true, 
    );

    _messages.add(tempMessage);
    notifyListeners();

    try {
      // 2. Intentamos enviarlo al servidor
      final confirmedMessage = await _chatRepository.sendMessage(chatId, content);
      
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = confirmedMessage;
        notifyListeners();
      }
    } on DioException catch (e) {
      if (_isOfflineError(e) || _isOffline) {
        // 3. OFFLINE QUEUE: No hay internet. A la cola.
        await _offlineQueueService.enqueueMessage(chatId: chatId, content: content);
        // Dejamos isPending=true en la UI.
      } else {
        _removeTempMessage(tempId);
        _errorMessage = 'No se pudo enviar el mensaje';
        notifyListeners();
      }
    } catch (e) {
      _removeTempMessage(tempId);
      _errorMessage = 'Error técnico: ${e.toString()}';
      notifyListeners();
    }
  }

  void _removeTempMessage(String id) {
    _messages.removeWhere((m) => m.id == id);
  }

  bool _isOfflineError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.error is SocketException;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _connectivitySubscription?.cancel(); // Limpiamos el listener
    super.dispose();
  }
}