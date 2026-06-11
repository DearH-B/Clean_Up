import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF111111);
  static const coral = Color(0xFFC91515);
  static const coralSoft = Color(0xFFFFEEEE);
  static const steel = Color(0xFF3D4145);
  static const steelSoft = Color(0xFFF0F0EE);
  static const warmGray = Color(0xFFF4F1EB);
  static const coolGray = Color(0xFFEDEDEC);
  static const graySoft = Color(0xFFF5F5F3);
  static const background = Color(0xFFFAFAF8);
  static const rule = Color(0xFF171717);
  static const muted = Color(0xFF656565);
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
    secondaryContainer: AppColors.steelSoft,
    surface: Colors.white,
    onSurface: AppColors.ink,
    outline: const Color(0xFFB8B8B5),
    outlineVariant: const Color(0xFFDEDEDA),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamilyFallback: const ['Noto Sans KR', 'sans-serif'],
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        height: 1.08,
      ),
      headlineSmall: TextStyle(
        color: AppColors.ink,
        fontSize: 27,
        fontWeight: FontWeight.w900,
        height: 1.12,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        height: 1.15,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      labelLarge: TextStyle(fontWeight: FontWeight.w800),
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
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: const BorderSide(color: Color(0xFFCFCFCC)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.coral,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.ink,
        );
      }),
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
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: Color(0xFFB8B8B5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: AppColors.coral, width: 2),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.ink,
      unselectedLabelColor: Color(0xFF74797C),
      indicatorColor: AppColors.coral,
      dividerColor: Color(0xFFE4E7E7),
      labelStyle: TextStyle(fontWeight: FontWeight.w800),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.rule),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.coralSoft,
      side: const BorderSide(color: Color(0xFFB8B8B5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      checkmarkColor: AppColors.coral,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFD7D7D3),
      thickness: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.coral,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
    ),
  );
}
