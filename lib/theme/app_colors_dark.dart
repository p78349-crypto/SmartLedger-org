import 'package:flutter/material.dart';

/// 다크 모드 전용 색상 상수 정의
class AppColorsDark {
  AppColorsDark._();

  // 기본 배경 및 표면 색상 (AppTheme.dart의 brightness == Brightness.dark 로직 참고)
  static const Color background = Color(0xFF121212); // 표준 다크 배경
  static const Color surface = Color(0xFF1A1614);    // 기존 코드의 dark surface
  static const Color surfaceContainerHighest = Color(0xFF2D2825); // 기존 코드 참고

  // 텍스트 색상
  static const Color textPrimary = Color(0xFFF9FAFB);   // 밝은 텍스트
  static const Color textSecondary = Color(0xFFD1D5DB); // 보조 텍스트
  static const Color textTertiary = Color(0xFF9CA3AF);  // 비활성/힌트 텍스트

  // 프라이머리 및 포인트 컬러 (다크모드에 최적화된 채도)
  static const Color primary = Color(0xFF818CF8);      // Indigo Light (다크모드용)
  static const Color secondary = Color(0xFF94A3B8);    // Slate
  
  // 상태 색상 (다크모드 가독성 고려)
  static const Color error = Color(0xFFF87171);        // Red 400
  static const Color success = Color(0xFF34D399);      // Emerald 400
  static const Color warning = Color(0xFFFBBF24);      // Amber 400
  static const Color info = Color(0xFF60A5FA);         // Blue 400

  // 거래 타입별 색상
  static const Color expense = Color(0xFFF87171);
  static const Color income = Color(0xFF34D399);
  static const Color savings = Color(0xFFFBBF24);

  // 구분선 및 테두리
  static const Color border = Color(0xFF374151);      // Gray 700
  static const Color divider = Color(0xFF374151);
}
