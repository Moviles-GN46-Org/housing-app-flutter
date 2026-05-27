import 'dart:async';
import 'dart:io';

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
  final String currentUserId; // Necesitamos el ID del estudiante para saber qué mensajes son suyos

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

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
    // 1. CARGA OFFLINE FIRST: Mostramos lo que haya en Hive inmediatamente
    _loadCachedMessages();
    
    // 2. Primera petición para actualizar
    _fetchMessages();

    // 3. POLLING: Preguntar cada 5 segundos al servidor, tal como recomendó Paul
    _startPolling();
  }

  void _loadCachedMessages() {
    _messages = _chatRepository.getCachedMessages(chatId);
    notifyListeners();
  }

  Future<void> _fetchMessages() async {
    // Evitamos bloqueos de UI si ya hay mensajes cargados en caché
    if (_isLoading && _messages.isEmpty) return;
    if (_messages.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Optimizamos usando el parámetro 'after' (timestamp) para no descargar todo de nuevo
      String? afterTimestamp;
      if (_messages.isNotEmpty) {
        // Buscamos la fecha del último mensaje confirmado
        final confirmedMessages = _messages.where((m) => !m.isPending).toList();
        if (confirmedMessages.isNotEmpty) {
          afterTimestamp = confirmedMessages.last.createdAt.toIso8601String();
        }
      }

      final newMessages = await _chatRepository.getMessages(chatId, after: afterTimestamp);
      
      if (newMessages.isNotEmpty) {
        if (afterTimestamp == null) {
          // Si no había 'after', es carga inicial desde cero
          _messages = newMessages; 
        } else {
          // Filtramos duplicados por seguridad y añadimos los nuevos
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
      // Si no hay internet, simplemente fallará silenciosamente y el usuario
      // seguirá viendo los mensajes cacheados (Offline First)
      _errorMessage = 'Modo sin conexión. Mostrando historial local.';
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
      _fetchMessages();
    });
  }

  /// ENVÍO DE MENSAJES (Maneja online y offline)
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 1. UI Optimista: Creamos un mensaje temporal y lo mostramos instantáneamente
    final tempId = const Uuid().v4();
    final tempMessage = ChatMessage(
      id: tempId,
      chatId: chatId,
      senderId: currentUserId, 
      type: 'TEXT',
      content: content,
      createdAt: DateTime.now(),
      isPending: true, // ¡Pendiente! Podremos mostrar un icono de "enviando..." en la UI
    );

    _messages.add(tempMessage);
    notifyListeners();

    try {
      // 2. Intentamos enviarlo de verdad a la API
      final confirmedMessage = await _chatRepository.sendMessage(chatId, content);
      
      // Si hay éxito, reemplazamos el mensaje temporal por el real con el ID del servidor
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = confirmedMessage;
        notifyListeners();
      }
    } on DioException catch (e) {
      if (_isOfflineError(e)) {
        // 3. EVENTUAL CONNECTIVITY: Falla por falta de internet. 
        // Lo mandamos a la cola del servicio offline.
        await _offlineQueueService.enqueueMessage(chatId: chatId, content: content);
        
        // No borramos el tempMessage. Se queda en la UI con isPending=true.
        // Cuando vuelva el internet, el OfflineQueueService hará el POST por debajo,
        // y nuestro Polling de 5 segundos eventualmente descargará la versión oficial de la base de datos.
      } else {
        // Error real del servidor (ej. 403, 500)
        _removeTempMessage(tempId);
        _errorMessage = 'No se pudo enviar el mensaje';
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR EN SEND MESSAGE: $e');
      debugPrint('STACKTRACE: $stackTrace'); // ESTO TE DIRÁ EXACTAMENTE LA LÍNEA QUE FALLA
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
    // ¡CRÍTICO! Apagar el timer al salir de la pantalla para no gastar batería ni hacer DDoS al servidor
    _pollingTimer?.cancel();
    super.dispose();
  }
}