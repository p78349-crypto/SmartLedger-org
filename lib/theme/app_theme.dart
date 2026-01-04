import 'package:flutter/material.dart';
import 'package:smart_ledger/theme/app_colors.dart';
import 'package:smart_ledger/theme/app_text_styles.dart';
import 'package:smart_ledger/theme/ui_style.dart';

class AppTheme {
  // Smart Ledger style light theme (seed-based palette + simple surfaces)
  static ThemeData smartLightTheme = buildSmartTheme(
    seedColor: Colors.blue,
    brightness: Brightness.light,
    uiStyle: UIStyle.standard,
  );

  // Smart Ledger style dark theme (seed-based palette + simple surfaces)
  static final ThemeData smartDarkTheme = buildSmartTheme(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
    uiStyle: UIStyle.standard,
  );

  static ThemeData buildSmartTheme({
    required Color seedColor,
    required Brightness brightness,
    required UIStyle uiStyle,
    Color? backgroundColor,
  }) {
    var scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    if (brightness == Brightness.dark) {
      scheme = scheme.copyWith(
        surface: const Color(0xFF1A1614),
        onSurface: const Color(0xFFF9FAFB),
        surfaceContainerHighest: const Color(0xFF2D2825),
      );
    }

    // UI Style based adjustments
    double borderRadius;
    double elevation;
    double borderWidth;
    bool showBorders;

    switch (uiStyle) {
      case UIStyle.modern:
        borderRadius = 28.0;
        elevation = 0.0;
        borderWidth = 0.0;
        showBorders = false;
        break;
      case UIStyle.classic:
        borderRadius = 4.0;
        elevation = 1.0;
        borderWidth = 1.0;
        showBorders = true;
        break;
      case UIStyle.bold:
        borderRadius = 12.0;
        elevation = 0.0;
        borderWidth = 2.0;
        showBorders = true;
        break;
      case UIStyle.standard:
        borderRadius = 16.0;
        elevation = 2.0;
        borderWidth = 1.0;
        showBorders = false;
        break;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          backgroundColor ??
          (brightness == Brightness.dark
              ? null
              : scheme.surfaceContainerLowest),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
        decorationColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 48,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      iconTheme: IconThemeData(
        color: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.dark
            ? scheme.outlineVariant.withValues(alpha: 0.5)
            : scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: (showBorders || brightness == Brightness.dark)
              ? BorderSide(
                  color: scheme.outlineVariant.withValues(
                    alpha: brightness == Brightness.dark ? 0.5 : 1.0,
                  ),
                  width: borderWidth > 0 ? borderWidth : 1,
                )
              : BorderSide.none,
        ),
        elevation: elevation,
        margin: const EdgeInsets.all(12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            brightness == Brightness.light
                ? scheme.surfaceContainerLow
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide:
              brightness == Brightness.dark
                  ? BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  )
                  : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide:
              brightness == Brightness.dark
                  ? BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  )
                  : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: BorderSide(
            color: scheme.primary,
            width: borderWidth > 0 ? borderWidth : 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: BorderSide(
            color: scheme.error,
            width: borderWidth > 0 ? borderWidth : 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: BorderSide(
            color: scheme.error,
            width: borderWidth > 0 ? borderWidth : 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        helperStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: elevation + 2,
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.savings,
      error: AppColors.error,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    // scaffoldBackgroundColor는 각 화면에서 동적으로 설정
    // scaffoldBackgroundColor: AppColors.background,

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      toolbarHeight: 48,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
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
      color: Color(0xFF374151),
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
      surface: Color(0xFF1A1614),
      surfaceContainerHighest: Color(0xFF2D2825),
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: Color(0xFFF9FAFB),
      onError: Colors.white,
    ),
    // scaffoldBackgroundColor는 각 화면에서 동적으로 설정
    // scaffoldBackgroundColor: const Color(0xFF111827),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF9FAFB),
      toolbarHeight: 48,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF9FAFB),
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFFF9FAFB)),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      color: const Color(0xFF2D2825),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3D3835), width: 0.5),
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1614),
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
