import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF242628);
  static const coral = Color(0xFFB85D52);
  static const coralSoft = Color(0xFFF8EBE8);
  static const steel = Color(0xFF52646B);
  static const steelSoft = Color(0xFFE8EDEF);
  static const warmGray = Color(0xFFF1EFEC);
  static const coolGray = Color(0xFFEDF0F1);
  static const graySoft = Color(0xFFF3F4F4);
  static const background = Color(0xFFF8F9F9);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.coral,
    brightness: Brightness.light,
    surface: Colors.white,
  ).copyWith(
    primary: AppColors.coral,
    primaryContainer: AppColors.coralSoft,
    secondary: AppColors.steel,
    secondaryContainer: const Color(0xFFE8EDEF),
    surface: Colors.white,
    onSurface: AppColors.ink,
    outline: const Color(0xFFD6DADB),
    outlineVariant: const Color(0xFFE7E9E9),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamilyFallback: const ['Noto Sans KR', 'sans-serif'],
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(height: 1.45),
      bodyMedium: TextStyle(height: 1.45),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE4E7E7)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.coralSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.coral,
      linearTrackColor: Color(0xFFE4E7E7),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD6DADB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD6DADB)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.ink,
      unselectedLabelColor: Color(0xFF74797C),
      indicatorColor: AppColors.coral,
      dividerColor: Color(0xFFE4E7E7),
      labelStyle: TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}
