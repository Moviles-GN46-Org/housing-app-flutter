import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/casandes_logo.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: CasandesLogo(
          width: 220,
          color: AppColors.inputBackground,
        ),
      ),
    );
  }
}
