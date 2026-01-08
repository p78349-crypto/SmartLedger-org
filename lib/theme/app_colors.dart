import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Transaction Type Colors
  static const Color expense = Color(0xFFEF4444); // Red
  static const Color expenseLight = Color(0xFFFEE2E2);
  static const Color income = Color(0xFF10B981); // Green
  static const Color incomeLight = Color(0xFFD1FAE5);
  static const Color savings = Color(0xFFF59E0B); // Amber/Gold
  static const Color savingsLight = Color(0xFFFEF3C7);
  // Text color used for savings label (deep green)
  static const Color savingsText = Color(0xFF166534);

  // Neutral Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Border & Divider
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Chart Colors (for statistics)
  static const List<Color> chartColors = [
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
  ];

  // Named chart colors (const-friendly access without list indexing)
  static const Color chartIndigo = Color(0xFF6366F1);
  static const Color chartPink = Color(0xFFEC4899);
  static const Color chartPurple = Color(0xFF8B5CF6);
  static const Color chartTeal = Color(0xFF14B8A6);

  // Icon Background Color (Consumables)
  static const Color iconBackgroundLight = Color(0xFFF3E5E8); // 연분홍

  // Consumable Icon Colors (고급스러운 팔레트)
  static const List<Color> consumableIconColors = [
    // 첫 행
    Color(0xFFE85D5D),  // 딥 로즈
    Color(0xFFC94B7F),  // 매그넷 핑크
    Color(0xFF9B6B9E),  // 플럼
    Color(0xFF6B7E8E),  // 슬레이트
    // 둘째 행
    Color(0xFF8B6F47),  // 워싱턴 브라운
    Color(0xFF7E8B5E),  // 올리브 그린
    Color(0xFF5B8B7D),  // 틸
    Color(0xFF6B6B9E),  // 인디고
    // 셋째 행
    Color(0xFFB86B6B),  // 오래된 로즈
    Color(0xFF8B7B5E),  // 베이지
    Color(0xFF7B7B8B),  // 그레이 블루
    Color(0xFFB8A86B),  // 골드
    // 넷째 행
    Color(0xFFCE7D7D),  // 코럴 핑크
  ];

  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
