import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFBF3EB); 
  static const Color cardBackground = Color(0xFFF6E5D4); 
  static const Color primary = Color(0xFFDA9958); 
  static const Color textDark = Color(0xFF3C2E26); 
  static const Color textMuted = Color(0xFF8B7264); 
  static const Color inputBackground = Color(0xFFFEFBF9); 
}

class AppTextStyles {
  // Asegúrate de descargar 'Instrument Sans' de Google Fonts después
  static const String fontFamily = 'Instrument Sans';

  static const TextStyle heading = TextStyle(
    color: AppColors.textDark,
    fontSize: 26,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.27,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: AppColors.textMuted,
    fontSize: 18,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
  );
}