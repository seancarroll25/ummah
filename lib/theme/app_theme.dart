import 'package:flutter/material.dart';
import './app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white,
    primaryColor: AppColors.mountain,
    colorScheme: ColorScheme.light(
      primary: AppColors.mountain,
      secondary: AppColors.colorAccent,
      background: AppColors.white,
      onBackground: AppColors.black,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: AppColors.black,
        fontFamily: 'Comfortaa',
      ),
      bodyMedium: TextStyle(
        color: AppColors.black,
        fontFamily: 'Comfortaa',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bottomNavBackgroundColor,
      selectedItemColor: AppColors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
    ),
    fontFamily: 'Comfortaa',
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBlueBlack,
    primaryColor: AppColors.mountain,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.mountain,
      secondary: AppColors.colorAccent,
      background: AppColors.darkBlueBlack,
      onBackground: AppColors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: AppColors.white,
        fontFamily: 'Comfortaa',
      ),
      bodyMedium: TextStyle(
        color: AppColors.white,
        fontFamily: 'Comfortaa',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.mountain,
      selectedItemColor: AppColors.white,
      unselectedItemColor: Colors.white54,
      showUnselectedLabels: true,
    ),
    fontFamily: 'Comfortaa',
  );
}
