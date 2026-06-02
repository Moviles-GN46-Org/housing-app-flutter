import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import '../models/chat_message.dart';
import '../services/api_client.dart';

class ChatRepository {
  final ApiClient _api;
  final Box _chatBox;

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
    try {
      final queryParams = after != null ? {'after': after} : null;
      final response = await _api.get('/chats/$chatId/messages', queryParams: queryParams);
      
      if (response.statusCode == 200) {
        final List<dynamic> rawData = response.data['data'];
        final newMessages = rawData.map((e) => ChatMessage.fromJson(e)).toList();

        // Actualizamos la caché local (Hive)
        if (after == null) {
          await _chatBox.put('messages_$chatId', rawData);
        } else {
          final existingData = _chatBox.get('messages_$chatId') as List<dynamic>? ?? [];
          existingData.addAll(rawData);
          await _chatBox.put('messages_$chatId', existingData);
        }
        
        return newMessages;
      }
      return [];
    } catch (e) {
      // SI FALLA (Ej. Modo Avión), retornamos el caché mágicamente
      return getCachedMessages(chatId);
    }
  }

  /// ENVÍA UN MENSAJE AL SERVIDOR
  Future<ChatMessage> sendMessage(String chatId, String content) async {
    final response = await _api.post('/chats/$chatId/messages', data: {
      'content': content,
      'type': 'TEXT',
    });
    
    if (response.statusCode == 201) {
      final newMsgRaw = response.data['data'];
      final newMsg = ChatMessage.fromJson(newMsgRaw);
      
      // ¡SOLUCIÓN! Guardamos el mensaje que acabamos de enviar en el caché local
      // para que cuando cerremos y abramos la app sin internet, el mensaje siga ahí.
      final existingData = _chatBox.get('messages_$chatId') as List<dynamic>? ?? [];
      existingData.add(newMsgRaw);
      await _chatBox.put('messages_$chatId', existingData);

      return newMsg;
    }
    throw Exception('Failed to send message');
  }

  Future<String> startChat(String propertyId) async {
    final response = await _api.post('/chats', data: {
      'propertyId': propertyId,
    });
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data['data']['id']; 
    }
    throw Exception('Failed to start chat');
  }

  /// OBTIENE LA BANDEJA DE ENTRADA (LISTA DE CHATS)
  Future<List<dynamic>> getMyChats() async {
    try {
      final response = await _api.get('/chats');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        
        // ¡SOLUCIÓN! Guardamos la lista de chats en Hive
        await _chatBox.put('my_inbox_list', data);
        
        return data;
      }
      return [];
    } catch (e) {
      // SI NO HAY INTERNET, devolvemos la última bandeja de entrada guardada
      return _chatBox.get('my_inbox_list', defaultValue: []) as List<dynamic>;
    }
  }
}