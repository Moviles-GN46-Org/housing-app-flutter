import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'chats_screen.dart';
import 'feed_screen.dart';
import 'roomies_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import '../utils/app_theme.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPage = 0;

  final List<Widget> pages = [
    const HomeScreen(),
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
            onTap: (value) {
              setState(() {
                currentPage = value;
              });
            },

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
