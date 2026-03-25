import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                    'Error loading listings',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => homeVM.fetchProperties(),
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
                'Welcome',
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
