import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:dio/dio.dart'; // Importante para detectar el error de red
import '../repositories/chat_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  // Usamos una variable para forzar la recarga cuando el usuario presiona "Reintentar"
  Key _futureKey = UniqueKey();

  void _retryConnection() {
    setState(() {
      _futureKey = UniqueKey(); // Esto obliga al FutureBuilder a ejecutarse de nuevo
    });
  }

  // Función para determinar si el error es por falta de internet
  bool _isOfflineError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.unknown; // En móviles a veces sale como unknown
    }
    return error.toString().contains('SocketException') || 
           error.toString().toLowerCase().contains('connection');
  }

  @override
  Widget build(BuildContext context) {
    final chatRepo = context.read<ChatRepository>();
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Mensajes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // RefreshIndicator permite al usuario "Halar hacia abajo" para recargar la pantalla
      body: RefreshIndicator(
        onRefresh: () async {
          _retryConnection();
          await Future.delayed(const Duration(seconds: 1)); // Pequeña pausa visual
        },
        color: AppColors.primary,
        child: FutureBuilder<List<dynamic>>(
          key: _futureKey, // Clave dinámica para forzar recargas
          future: chatRepo.getMyChats(),
          builder: (context, snapshot) {
            
            // 1. ESTADO DE CARGA
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            // 2. ESTADO DE ERROR (Sin internet)
            if (snapshot.hasError) {
              final isOffline = _isOfflineError(snapshot.error!);
              
              return ListView( // Usamos ListView para que el RefreshIndicator (halar para recargar) siga funcionando
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Icon(
                    isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isOffline ? 'No tienes conexión a internet' : 'Ocurrió un problema',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepMocha),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOffline 
                        ? 'Verifica tu conexión y vuelve a intentarlo.\nTus chats guardados están seguros.' 
                        : 'Hubo un error al cargar tus chats.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _retryConnection,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightBronze,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  )
                ],
              );
            }

            // 3. ESTADO DE ÉXITO
            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Icon(LucideIcons.message_square, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no tienes conversaciones.\nBusca una propiedad en el mapa para empezar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final propertyTitle = chat['property']?['title'] ?? 'Chat de propiedad';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lightBronze.withOpacity(0.15),
                      radius: 24,
                      child: const Icon(LucideIcons.house, color: AppColors.lightBronze),
                    ),
                    title: Text(propertyTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Toca para abrir la conversación...',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chat['id'] ?? chat['_id'],
                            currentUserId: authVM.currentUser?.id ?? '',
                            propertyTitle: propertyTitle,
                          ),
                        ),
                      ).then((_) => _retryConnection()); // Recargar si volvemos del chat
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}