import 'package:flutter/material.dart';

class AppTheme {
  final ThemeData _themeApp = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: Color(0xFF2F80ED),
      primary: Color(0xFF2F80ED),
      secondary: Color(0xFF56CCF2),
      tertiary: Color(0xFFBB6BD9),
      surface: Color(0xFFF9FAFB),
      error: Color(0xFFEB5757),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.tertiary,
    ),
  );

  ThemeData get themeApp => _themeApp;

  static const titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const titleHighlightStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const titleSmallStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const titleSmallHighlightStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
}

class AppColors {
  static const seedColor = Color(0xFF3F51B5);
  static const primary = Color(0xFF3F51B5);
  static const secondary = Color(0xFF4CAF50);
  static const tertiary = Color(0xFFFF7043);
  static const surface = Color(0xFFF3F4F6);
  static const error = Colors.red;

  static const ingresos = Color(0xFF27AE60);
  static const gastos = Color(0xFFEB5757);
}
