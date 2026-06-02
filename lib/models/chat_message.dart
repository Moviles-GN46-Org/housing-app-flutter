class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String type;
  final String content;
  final DateTime createdAt;
  final bool isPending;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.isPending = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {

      String extractedSenderId = 'unknown';
      if (json['senderId'] != null) {
        extractedSenderId = json['senderId'].toString();
      } else if (json['sender'] != null) {
        if (json['sender'] is Map) {

          extractedSenderId = (json['sender']['id'] ?? json['sender']['_id'] ?? 'unknown').toString();
        } else {

          extractedSenderId = json['sender'].toString();
        }
      }


      return ChatMessage(
        id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
        chatId: (json['chatId'] ?? json['chat'] ?? '').toString(),
        senderId: extractedSenderId,
        type: (json['type'] ?? 'TEXT').toString(),
        content: (json['content'] ?? '').toString(),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
        isPending: json['isPending'] ?? false,
      );
    } catch (e) {
      print("ERROR PARSEANDO MENSAJE: $e");
      print("JSON RECIBIDO DEL BACKEND: $json");
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: '',
        senderId: '',
        type: 'TEXT',
        content: ' Este mensaje tiene un formato ilegible desde la base de datos.',
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'type': type,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isPending': isPending,
      };
}