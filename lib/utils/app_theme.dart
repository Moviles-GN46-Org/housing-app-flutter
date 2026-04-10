import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFBF3EB);
  static const Color cardBackground = Color(0xFFF6E5D4);
  static const Color primary = Color(0xFFDA9958);
  static const Color textDark = Color(0xFF3C2E26);
  static const Color textMuted = Color(0xFF8B7264);
  static const Color inputBackground = Color(0xFFFEFBF9);
  static const Color dustyTaupe = Color(0xFF8B7364); // Secondary labels
  static const Color ashBrown = Color(0xFF58463A); // Body text
  static const Color deepMocha = Color(0xFF3C2E26); // Titles
  static const Color lightBronze = Color(0xFFDA9958); // Key elements
  static const Color linen = Color(0xFFFBF3EB); // Backgrounds
  static const Color white = Color(0xFFFEFBF9); // Cards, accent components
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromARGB(29, 60, 46, 38),
      offset: Offset(0, 4),
      blurRadius: 6.0,
    ),
  ];

  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color.fromARGB(10, 60, 46, 38),
      offset: Offset(2, 4),
      blurRadius: 3.0,
    ),
  ];
}

class AppTextStyles {
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
