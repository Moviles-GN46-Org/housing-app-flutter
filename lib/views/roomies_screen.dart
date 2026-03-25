import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';

// Dating app-like swiping interface to match with roommates

class RoomiesScreen extends StatefulWidget {
  const RoomiesScreen({super.key});

  @override
  State<RoomiesScreen> createState() => _RoomiesScreenState();
}

class _RoomiesScreenState extends State<RoomiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: AppColors.linen,
      body: homeVM.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lightBronze),
            )
          : homeVM.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading roomies',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBronze,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : const Center(
              child: Text(
                'Coming soon!',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
    );
  }
}
