import 'package:flutter/material.dart';
import 'app_colors_dark.dart';
import 'ui_style.dart';

/// 다크 모드 전용 테마 설정을 분리하여 관리
class DarkTheme {
  DarkTheme._();

  static ThemeData build({
    required Color seedColor,
    UIStyle uiStyle = UIStyle.standard,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.textPrimary,
      surfaceContainerHighest: AppColorsDark.surfaceContainerHighest,
      error: AppColorsDark.error,
      onError: Colors.black, // 다크모드에서 에러 바탕 위 텍스트
    );

    // UI 스타일별 수치 설정
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
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColorsDark.background,
      
      // 텍스트 테마 적용
      textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
        decorationColor: scheme.onSurface,
      ),

      // 앱바 테마
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

      // 아이콘 테마
      iconTheme: IconThemeData(color: scheme.onSurface),

      // 구분선 테마
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      // 카드 테마
      cardTheme: CardThemeData(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: showBorders
              ? BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  width: borderWidth > 0 ? borderWidth : 1,
                )
              : BorderSide.none,
        ),
        elevation: elevation,
        margin: const EdgeInsets.all(12),
      ),

      // 입력창 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 1.5),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
