import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'chats_screen.dart';
import 'feed_screen.dart';
import 'roomies_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import '../services/analytics_service.dart';
import '../utils/app_theme.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class _ScreenTracker extends StatefulWidget {
  const _ScreenTracker({required this.screenName, required this.child});
  final String screenName;
  final Widget child;

  @override
  State<_ScreenTracker> createState() => _ScreenTrackerState();
}

class _ScreenTrackerState extends State<_ScreenTracker> {
  @override
  void initState() {
    super.initState();
    context.read<AnalyticsService>().currentScreen = widget.screenName;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPage = 0;

  void _changePage(int value) {
    setState(() {
      currentPage = value;
    });
  }

  List<Widget> get pages => [
    _ScreenTracker(
      screenName: ScreenName.home,
      child: HomeScreen(onMapTap: () => _changePage(1)),
    ),
    const _ScreenTracker(
      screenName: ScreenName.mapSearch,
      child: MapScreen(),
    ),
    const _ScreenTracker(
      screenName: ScreenName.chatScreen,
      child: ChatsScreen(),
    ),
    const _ScreenTracker(
      screenName: ScreenName.feed,
      child: FeedScreen(),
    ),
    const _ScreenTracker(
      screenName: ScreenName.roomies,
      child: RoomiesScreen(),
    ),
    const _ScreenTracker(
      screenName: ScreenName.profileEdit,
      child: ProfileScreen(),
    ),
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
