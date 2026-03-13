import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Estos son los archivos que tú creaste
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'viewmodels/auth_view_model.dart';
import 'views/sign_up_view.dart'; // Lo descomentaremos en el siguiente paso

void main() async {
  // 1. Asegura que el motor de Flutter esté listo antes de llamar a Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Conecta tu app con el proyecto "CasAndes" usando el archivo autogenerado
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Arranca la app inyectando el AuthViewModel para que toda la app lo escuche (Observer Pattern)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
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
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: AppTextStyles.fontFamily,
      ),
      home: const SignUpView(),
    );
  }
}