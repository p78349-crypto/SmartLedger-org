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
    Color(0xFFE85D5D), // 딥 로즈
    Color(0xFFC94B7F), // 매그넷 핑크
    Color(0xFF9B6B9E), // 플럼
    Color(0xFF6B7E8E), // 슬레이트
    // 둘째 행
    Color(0xFF8B6F47), // 워싱턴 브라운
    Color(0xFF7E8B5E), // 올리브 그린
    Color(0xFF5B8B7D), // 틸
    Color(0xFF6B6B9E), // 인디고
    // 셋째 행
    Color(0xFFB86B6B), // 오래된 로즈
    Color(0xFF8B7B5E), // 베이지
    Color(0xFF7B7B8B), // 그레이 블루
    Color(0xFFB8A86B), // 골드
    // 넷째 행
    Color(0xFFCE7D7D), // 코럴 핑크
  ];

  // Feature Icon Colors by Page Category
  // Page 1: 거래/지출 (Warm Reds & Oranges)
  static const List<Color> page1IconColors = [
    Color(0xFFE85D5D), // 딥 로즈
    Color(0xFFD4674B), // 테라코타
    Color(0xFFCF7E4A), // 번트 오렌지
    Color(0xFFB8704E), // 코퍼
    Color(0xFFE07C5F), // 살몬
    Color(0xFFC9705B), // 시에나
    Color(0xFFBB6B5B), // 마룬
    Color(0xFFD88C6E), // 피치
    Color(0xFFCC7A5E), // 앱리콧
    Color(0xFFC06E4F), // 러스트
    Color(0xFFE89A7B), // 코럴
    Color(0xFFCF8066), // 클레이
  ];

  // Page 2: 수입 (Fresh Greens)
  static const List<Color> page2IconColors = [
    Color(0xFF4CAF50), // 그린
    Color(0xFF66BB6A), // 라이트 그린
    Color(0xFF81C784), // 세이지
    Color(0xFF2E7D32), // 포레스트
    Color(0xFF388E3C), // 에메랄드
    Color(0xFF43A047), // 켈리
    Color(0xFF6B8E6B), // 올리브 그린
    Color(0xFF5B8B7D), // 틸
    Color(0xFF7E8B5E), // 모스
    Color(0xFF689F63), // 민트
  ];

  // Page 3: 자산 (Cool Blues)
  static const List<Color> page3IconColors = [
    Color(0xFF5C6BC0), // 인디고
    Color(0xFF42A5F5), // 스카이 블루
    Color(0xFF1976D2), // 로얄 블루
    Color(0xFF7986CB), // 라벤더 블루
    Color(0xFF3F51B5), // 딥 블루
    Color(0xFF5E8AC6), // 스틸 블루
    Color(0xFF6B7E8E), // 슬레이트
    Color(0xFF4A7C9B), // 세룰리안
    Color(0xFF5D9CBA), // 애쿠아
    Color(0xFF6B9DC5), // 페리윙클
  ];

  // Page 4: 예산/계획 (Warm Purples & Pinks)
  static const List<Color> page4IconColors = [
    Color(0xFF9B6B9E), // 플럼
    Color(0xFFC94B7F), // 매그넷 핑크
    Color(0xFFAB47BC), // 오키드
    Color(0xFF8E6BB8), // 아메시스트
    Color(0xFFBA68C8), // 라일락
    Color(0xFF9C5A8A), // 모브
    Color(0xFFA76BB8), // 헬리오트로프
    Color(0xFFB47BA8), // 로즈 쿼츠
    Color(0xFF8B5A9E), // 바이올렛
    Color(0xFFC97BA8), // 핑크 라벤더
  ];

  // Page 5: 통계/분석 (Earth Tones & Golds)
  static const List<Color> page5IconColors = [
    Color(0xFFB8A86B), // 골드
    Color(0xFF8B7B5E), // 베이지
    Color(0xFF8B6F47), // 워싱턴 브라운
    Color(0xFFA0926B), // 샌드
    Color(0xFF9E8B6E), // 탄
    Color(0xFFB09060), // 카멜
    Color(0xFF7B7B8B), // 그레이 블루
    Color(0xFF8E8B7D), // 토프
    Color(0xFF9B917B), // 크림
    Color(0xFFA89070), // 허니
  ];

  // Page 6: 설정/기타 (Neutral Grays & Teals)
  static const List<Color> page6IconColors = [
    Color(0xFF607D8B), // 블루 그레이
    Color(0xFF546E7A), // 차콜
    Color(0xFF78909C), // 슬레이트 그레이
    Color(0xFF26A69A), // 틸
    Color(0xFF00897B), // 다크 틸
    Color(0xFF009688), // 사이언
    Color(0xFF4DB6AC), // 아쿠아마린
    Color(0xFF80CBC4), // 민트 그린
    Color(0xFF5F9EA0), // 카뎃 블루
    Color(0xFF708090), // 슬레이트
  ];

  /// Get icon color by page index and item index
  static Color getFeatureIconColor(int pageIndex, int itemIndex) {
    final palette = switch (pageIndex) {
      1 => page1IconColors,
      2 => page2IconColors,
      3 => page3IconColors,
      4 => page4IconColors,
      5 => page5IconColors,
      6 => page6IconColors,
      _ => page1IconColors,
    };
    return palette[itemIndex % palette.length];
  }

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
