import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'chats_screen.dart';
import 'feed_screen.dart';
import 'roomies_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import '../models/property_model.dart';
import '../utils/app_theme.dart';
import '../viewmodels/main_page_viewmodel.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPage = 0;
  late final MainPageViewModel _mainPageViewModel;
  bool _isPromptVisible = false;

  @override
  void initState() {
    super.initState();
    _mainPageViewModel = context.read<MainPageViewModel>();
    _mainPageViewModel.addListener(_onMainPageViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _mainPageViewModel.startMonitoring();
        }
      });
    });
  }

  @override
  void dispose() {
    _mainPageViewModel.removeListener(_onMainPageViewModelChanged);
    _mainPageViewModel.stopMonitoring();
    super.dispose();
  }

  void _changePage(int value) {
    setState(() {
      currentPage = value;
    });
    _mainPageViewModel.setCurrentPage(value);
  }

  void _onMainPageViewModelChanged() {
    if (!mounted) return;

    final status = _mainPageViewModel.debugStatus;
    if (status != null && _mainPageViewModel.showDebugToasts) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('[Proximity check] $status'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (_isPromptVisible || currentPage == 1) {
      return;
    }
    final suggestion = _mainPageViewModel.consumePendingSuggestion();
    if (suggestion == null) {
      return;
    }
    _showMapSuggestionModal(suggestion.property, suggestion.distanceMeters);
  }

  Future<void> _showMapSuggestionModal(
    Property property,
    double distanceMeters,
  ) async {
    if (!mounted) return;

    _isPromptVisible = true;
    final distanceLabel = distanceMeters < 1000
        ? '${distanceMeters.round()} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    final shouldOpenMap = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: const Text(
            'Saved listing nearby',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.deepMocha,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
          content: Text(
            'You are moving and "${property.title}" is about $distanceLabel away. Open the map tab?',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.dustyTaupe,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Not now',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.dustyTaupe,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightBronze,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(LucideIcons.map, size: 16),
              label: const Text(
                'Open map',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    _isPromptVisible = false;

    if (shouldOpenMap == true && mounted) {
      _changePage(1);
    }
  }

  List<Widget> get pages => [
    HomeScreen(onMapTap: () => _changePage(1)),
    const MapScreen(),
    const ChatsScreen(),
    const FeedScreen(),
    const RoomiesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: pages[currentPage],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(splashColor: AppColors.lightBronze.withValues(alpha: 0.2)),
          child: BottomNavigationBar(
            currentIndex: currentPage,
            onTap: _changePage,

            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Icon(LucideIcons.house),
                ),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Icon(LucideIcons.map),
                ),
                label: "Map",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Icon(LucideIcons.messages_square),
                ),
                label: "Chats",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Icon(LucideIcons.images),
                ),
                label: "Feed",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Icon(LucideIcons.heart_handshake),
                ),
                label: "Roomies",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Icon(LucideIcons.circle_user_round),
                ),
                label: "Profile",
              ),
            ],
            backgroundColor: const Color(0xFFF6E5D4),
            elevation: 16.0,
            selectedItemColor: AppColors.lightBronze,
            unselectedItemColor: AppColors.dustyTaupe,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedIconTheme: const IconThemeData(size: 28.0),
          ),
        ),
      ),
    );
  }
}
