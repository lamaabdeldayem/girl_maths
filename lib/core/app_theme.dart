// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const hotPink = Color(0xFFFF2A7A);
  static const bubblegum = Color(0xFFFF70A6);
  static const blush = Color(0xFFFFE3EC);
  static const petal = Color(0xFFFFD1DC);
  static const cream = Color(0xFFFFF1F5);
  static const lilac = Color(0xFF9D4EDD);
  static const danger = Color(0xFFE53950);
  static const success = Color(0xFF2E9E6A);

  static const darkBg = Color(0xFF16111A);
  static const darkSurface = Color(0xFF231A27);
  static const darkBorder = Color(0xFF3A2C40);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.hotPink,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.hotPink,
      onPrimary: Colors.white,
      secondary: AppColors.lilac,
      surface: isDark ? AppColors.darkSurface : Colors.white,
      error: AppColors.danger,
    );

    final border = isDark ? AppColors.darkBorder : AppColors.petal;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF333333),
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF333333)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkBg : AppColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.hotPink, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.hotPink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.hotPink,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: border),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.hotPink.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.hotPink.withValues(alpha: 0.18),
        selectedIconTheme: const IconThemeData(color: AppColors.hotPink),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.hotPink,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
