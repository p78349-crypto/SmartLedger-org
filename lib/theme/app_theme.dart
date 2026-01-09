import 'package:flutter/material.dart';
import 'ui_style.dart';

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

  // Simple cache to avoid redundant theme builds
  static final Map<String, ThemeData> _themeCache = {};

  static ThemeData buildSmartTheme({
    required Color seedColor,
    required Brightness brightness,
    required UIStyle uiStyle,
    Color? backgroundColor,
  }) {
    final cacheKey =
        '${seedColor.toARGB32()}_${brightness.name}_'
        '${uiStyle.name}_${backgroundColor?.toARGB32()}';
    if (_themeCache.containsKey(cacheKey)) {
      return _themeCache[cacheKey]!;
    }

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

    final theme = ThemeData(
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
      iconTheme: IconThemeData(color: scheme.onSurface),
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
        fillColor: brightness == Brightness.light
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: brightness == Brightness.dark
              ? BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4))
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: brightness == Brightness.dark
              ? BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4))
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

    _themeCache[cacheKey] = theme;
    return theme;
  }
}
