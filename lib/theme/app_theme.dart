import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF2F2929);
  static const pink = Color(0xFFEFA9B2);
  static const pinkSoft = Color(0xFFFFEEF0);
  static const rose = Color(0xFFD9687A);
  static const peachSoft = Color(0xFFFFF2E9);
  static const lavenderSoft = Color(0xFFF4ECFF);
  static const graySoft = Color(0xFFF6F4F5);
  static const background = Color(0xFFFFFCFC);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.pink,
    brightness: Brightness.light,
    surface: Colors.white,
  ).copyWith(
    primary: AppColors.rose,
    primaryContainer: AppColors.pinkSoft,
    secondary: const Color(0xFF9C6671),
    secondaryContainer: AppColors.pinkSoft,
    surface: Colors.white,
    onSurface: AppColors.ink,
    outline: const Color(0xFFE4DADC),
    outlineVariant: const Color(0xFFF0E7E9),
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
        side: const BorderSide(color: Color(0xFFF0E5E7)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.pinkSoft,
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
      color: AppColors.rose,
      linearTrackColor: Color(0xFFFFE5E9),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4DADC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4DADC)),
      ),
    ),
  );
}
