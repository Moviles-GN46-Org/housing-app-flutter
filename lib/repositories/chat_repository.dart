import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message.dart';
import '../services/api_client.dart';

class ChatRepository {
  final ApiClient _api;
  final Box _chatBox;

  // Inyectamos el ApiClient y abrimos la caja de Hive donde guardaremos los chats
  ChatRepository(this._api) : _chatBox = Hive.box('chat_cache');

  /// OBTIENE LOS MENSAJES CACHEADOS (Funciona 100% offline)
  List<ChatMessage> getCachedMessages(String chatId) {
    final cachedData = _chatBox.get('messages_$chatId');
    if (cachedData == null) return [];
    
    final List<dynamic> list = cachedData;
    return list
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// TRAE MENSAJES DEL SERVIDOR Y ACTUALIZA HIVE
  Future<List<ChatMessage>> getMessages(String chatId, {String? after}) async {
    final queryParams = after != null ? {'after': after} : null;
    
    final response = await _api.get('/chats/$chatId/messages', queryParams: queryParams);
    
    if (response.statusCode == 200) {
      final List<dynamic> rawData = response.data['data'];
      final newMessages = rawData.map((e) => ChatMessage.fromJson(e)).toList();

      // Lógica para actualizar la caché local (Hive)
      if (after == null) {
        // Si no hay 'after', significa que cargamos todo desde cero
        await _chatBox.put('messages_$chatId', rawData);
      } else {
        // Si hay 'after', agregamos los nuevos mensajes a los que ya teníamos
        final existingData = _chatBox.get('messages_$chatId') as List<dynamic>? ?? [];
        existingData.addAll(rawData);
        await _chatBox.put('messages_$chatId', existingData);
      }
      
      return newMessages;
    }
    throw Exception('Failed to load messages');
  }

  /// ENVÍA UN MENSAJE AL SERVIDOR
  Future<ChatMessage> sendMessage(String chatId, String content) async {
    final response = await _api.post('/chats/$chatId/messages', data: {
      'content': content,
      'type': 'TEXT',
    });
    
    if (response.statusCode == 201) {
      return ChatMessage.fromJson(response.data['data']);
    }
    throw Exception('Failed to send message');
  }

  Future<String> startChat(String propertyId) async {
    final response = await _api.post('/chats', data: {
      'propertyId': propertyId,
    });
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data['data']['id']; // Retorna el ID del chat
    }
    throw Exception('Failed to start chat');
  }

  Future<List<dynamic>> getMyChats() async {
    final response = await _api.get('/chats');
    if (response.statusCode == 200) {
      return response.data['data'] as List<dynamic>;
    }
    return [];
  }

}