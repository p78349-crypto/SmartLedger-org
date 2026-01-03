import 'package:flutter/material.dart';
import 'package:smart_ledger/theme/app_colors.dart';
import 'package:smart_ledger/theme/app_text_styles.dart';

class AppTheme {
  // One UI-inspired light theme (seed-based palette + simple surfaces)
  static ThemeData oneUiLightTheme = buildOneUiTheme(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  );

  // One UI-inspired dark theme (seed-based palette + simple surfaces)
  static final ThemeData oneUiDarkTheme = buildOneUiTheme(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  );

  static ThemeData buildOneUiTheme({
    required Color seedColor,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // scaffoldBackgroundColor는 각 화면에서 동적으로 설정
      // scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        margin: const EdgeInsets.all(12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.90)),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.90),
        ),
        helperStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.90),
        ),
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.savings,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    // scaffoldBackgroundColor는 각 화면에서 동적으로 설정
    // scaffoldBackgroundColor: AppColors.background,

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: AppTextStyles.heading2,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: AppTextStyles.labelSmall,
      unselectedLabelStyle: AppTextStyles.labelSmall,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: AppTextStyles.bodyMedium,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textTertiary,
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: AppColors.income,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppColors.income.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: AppTextStyles.button,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.2);
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.white.withValues(alpha: 0.1);
              }
              return null;
            }),
          ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      headlineSmall: AppTextStyles.heading3,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      primaryContainer: AppColors.primaryDark,
      secondary: AppColors.savings,
      surface: Color(0xFF1F2937),
      surfaceContainerHighest: Color(0xFF374151),
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFFF9FAFB),
      onError: Colors.white,
    ),
    // scaffoldBackgroundColor는 각 화면에서 동적으로 설정
    // scaffoldBackgroundColor: const Color(0xFF111827),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color(0xFF1F2937),
      foregroundColor: Color(0xFFF9FAFB),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF9FAFB),
      ),
      iconTheme: IconThemeData(color: Color(0xFFF9FAFB)),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF374151), width: 0.5),
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1F2937),
      selectedItemColor: Color(0xFF818CF8),
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: AppTextStyles.labelSmall,
      unselectedLabelStyle: AppTextStyles.labelSmall,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF374151),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4B5563)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4B5563)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(color: Color(0xFFD1D5DB)),
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppColors.primaryLight.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: AppTextStyles.button,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.2);
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.white.withValues(alpha: 0.1);
              }
              return null;
            }),
          ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: Color(0xFF818CF8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFF374151),
      thickness: 1,
      space: 1,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: Color(0xFFD1D5DB), size: 24),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(
        color: const Color(0xFFF9FAFB),
      ),
      displayMedium: AppTextStyles.displayMedium.copyWith(
        color: const Color(0xFFF9FAFB),
      ),
      displaySmall: AppTextStyles.displaySmall.copyWith(
        color: const Color(0xFFF9FAFB),
      ),
      headlineLarge: AppTextStyles.heading1.copyWith(
        color: const Color(0xFFF9FAFB),
      ),
      headlineMedium: AppTextStyles.heading2.copyWith(
        color: const Color(0xFFF9FAFB),
      ),
      headlineSmall: AppTextStyles.heading3.copyWith(
        color: const Color(0xFFF9FAFB),
      ),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(
        color: const Color(0xFFE5E7EB),
      ),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(
        color: const Color(0xFFD1D5DB),
      ),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: const Color(0xFF9CA3AF),
      ),
      labelLarge: AppTextStyles.labelLarge.copyWith(
        color: const Color(0xFFF9FAFB),
      ),
      labelMedium: AppTextStyles.labelMedium.copyWith(
        color: const Color(0xFFD1D5DB),
      ),
      labelSmall: AppTextStyles.labelSmall.copyWith(
        color: const Color(0xFF9CA3AF),
      ),
    ),
  );
}
