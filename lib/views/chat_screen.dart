import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/offline_queue_service.dart';
import '../viewmodels/chat_viewmodel.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final String propertyTitle;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    this.propertyTitle = 'Chat',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatViewModel(
        chatRepository: context.read<ChatRepository>(),
        offlineQueueService: context.read<OfflineQueueService>(),
        chatId: chatId,
        currentUserId: currentUserId,
      ),
      child: _ChatScreenView(propertyTitle: propertyTitle),
    );
  }
}

class _ChatScreenView extends StatefulWidget {
  final String propertyTitle;
  const _ChatScreenView({Key? key, required this.propertyTitle}) : super(key: key);

  @override
  State<_ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<_ChatScreenView> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      context.read<ChatViewModel>().sendMessage(text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          if (viewModel.errorMessage != null)
            Container(
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.orange, fontSize: 13))),
                ],
              ),
            ),
          Expanded(
            child: viewModel.messages.isEmpty && viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.messages.length,
                    itemBuilder: (context, index) {
                      final message = viewModel.messages[index];
                      final isMe = message.senderId == viewModel.currentUserId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(child: Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black))),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                Icon(message.isPending ? Icons.access_time : Icons.done_all, size: 14, color: Colors.white70),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mensaje...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}