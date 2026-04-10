import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// TikTok-type feed of housing listings

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.linen,
      body: Center(
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
