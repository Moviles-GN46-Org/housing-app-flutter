import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/map_view_model.dart';
import 'views/login_view.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
      ],
      child: const CasAndesApp(),
    ),
  );
}

class CasAndesApp extends StatelessWidget {
  const CasAndesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CasAndes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Iniciamos en el Login para obtener el token de David
      home: const LoginView(),
    );
  }
}