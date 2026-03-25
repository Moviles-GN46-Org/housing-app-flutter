import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/property_repository.dart';
import 'utils/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/map_view_model.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/verify_email_screen.dart';
import 'views/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient);
  final propertyRepository = PropertyRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(propertyRepository),
        ),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
      ],
      child: const UniHousingApp(),
    ),
  );
}

class UniHousingApp extends StatelessWidget {
  const UniHousingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniHousing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Instrument Sans',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    if (authVM.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (authVM.isAuthenticated) {
      if (authVM.currentUser != null && !authVM.currentUser!.isVerified) {
        return VerifyEmailScreen(email: authVM.currentUser!.email);
      }

      return const MainPage();
    }

    return const LoginScreen();
  }
}
