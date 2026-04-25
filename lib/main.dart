import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/analytics_service.dart';
import 'services/api_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/property_repository.dart';
import 'utils/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/main_page_viewmodel.dart';
import 'viewmodels/map_view_model.dart';
import 'viewmodels/strategies/favorite_proximity_strategy.dart';
import 'viewmodels/strategies/movement_detection_strategy.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/verify_email_screen.dart';
import 'views/main_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:housing_app_flutter/models/local_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(LocalEventAdapter());
  await Hive.openBox<LocalEvent>('pending_locations');

  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient);
  final propertyRepository = PropertyRepository(apiClient);
  final notificationRepository = NotificationRepository(apiClient);
  
  
  final analyticsService = AnalyticsService(apiClient);

  FlutterError.onError = (details) {
    analyticsService.logCrash(
      screenName: analyticsService.currentScreen ?? 'unknown',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    analyticsService.logCrash(
      screenName: analyticsService.currentScreen ?? 'unknown',
      error: error,
      stackTrace: stack,
    );
    return false;
  };

  runApp(
    MultiProvider(
      providers: [
        Provider<AnalyticsService>.value(value: analyticsService),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(
          create: (_) =>
              HomeViewModel(propertyRepository, notificationRepository),
        ),
        ChangeNotifierProxyProvider<HomeViewModel, MainPageViewModel>(
          create: (context) => MainPageViewModel(
            homeViewModel: context.read<HomeViewModel>(),
            movementStrategy: const SpeedAndDeltaMovementStrategy(
              speedThresholdMps: 0.05,
            ),
            proximityStrategy: const RadiusFavoriteProximityStrategy(
              radiusMeters: 5000.0,
            ),
          ),
          update: (context, homeVM, previous) {
            if (previous == null) {
              return MainPageViewModel(
                homeViewModel: homeVM,
                movementStrategy: const SpeedAndDeltaMovementStrategy(
                  speedThresholdMps: 0.05,
                ),
                proximityStrategy: const RadiusFavoriteProximityStrategy(
                  radiusMeters: 5000.0,
                ),
              );
            }
            previous.updateHomeViewModel(homeVM);
            return previous;
          },
        ),
        ChangeNotifierProvider(create: (_) => MapViewModel(propertyRepository,analyticsService,)),
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

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().checkAuthStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authVM = context.read<AuthViewModel>();
    if (!authVM.isAuthenticated) return;
    final analytics = context.read<AnalyticsService>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Drop any in-flight feature-load timer. A backgrounded user isn't
      // actually waiting for the screen to load — resuming would report a
      // bogus multi-minute duration.
      analytics.discardPendingLoad();
      analytics.endSession();
    } else if (state == AppLifecycleState.resumed) {
      analytics.startSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    if (authVM.isAuthenticated && !_wasAuthenticated) {
      _wasAuthenticated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AnalyticsService>().startSession();
      });
    } else if (!authVM.isAuthenticated) {
      _wasAuthenticated = false;
    }

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
