import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String label;
  final Color seedColor;
  final Color? backgroundColor; // Optional intense background color

  const ThemePreset({
    required this.id,
    required this.label,
    required this.seedColor,
    this.backgroundColor,
  });
}

class ThemePresets {
  ThemePresets._();

  static const String defaultId = 'navy_intense';

  /// 스마트 레저 스타일(깔끔한 Material3 + SeedColor 기반) 프리셋 20개.
  /// 여성용 10개 (연한색 5 + 진한색 5), 남성용 10개 (연한색 5 + 진한색 5)
  static const List<ThemePreset> female = <ThemePreset>[
    // 연한색 (Soft)
    ThemePreset(
      id: 'pink_light',
      label: '여성 1 · 소프트 핑크',
      seedColor: Color(0xFFFFC1CC),
    ),
    ThemePreset(
      id: 'lavender_light',
      label: '여성 2 · 라벤더',
      seedColor: Color(0xFFE1BEE7),
    ),
    ThemePreset(
      id: 'peach_light',
      label: '여성 3 · 피치',
      seedColor: Color(0xFFFFE0B2),
    ),
    ThemePreset(
      id: 'mint_light',
      label: '여성 4 · 민트',
      seedColor: Color(0xFFB2DFDB),
    ),
    ThemePreset(
      id: 'sky_light',
      label: '여성 5 · 스카이',
      seedColor: Color(0xFFB3E5FC),
    ),

    // 진한색 (Intense)
    ThemePreset(
      id: 'rose_intense',
      label: '여성 6 · 딥 로즈 (진한색)',
      seedColor: Color(0xFFD81B60),
      backgroundColor: Color(0xFF2D0815), // Dark background for intense theme
    ),
    ThemePreset(
      id: 'purple_intense',
      label: '여성 7 · 로열 퍼플 (진한색)',
      seedColor: Color(0xFF6A1B9A),
      backgroundColor: Color(0xFF1A0626),
    ),
    ThemePreset(
      id: 'orange_intense',
      label: '여성 8 · 선셋 오렌지 (진한색)',
      seedColor: Color(0xFFEF6C00),
      backgroundColor: Color(0xFF261100),
    ),
    ThemePreset(
      id: 'emerald_intense',
      label: '여성 9 · 에메랄드 (진한색)',
      seedColor: Color(0xFF2E7D32),
      backgroundColor: Color(0xFF0A1A0B),
    ),
    ThemePreset(
      id: 'indigo_intense',
      label: '여성 10 · 인디고 (진한색)',
      seedColor: Color(0xFF283593),
      backgroundColor: Color(0xFF080B1A),
    ),
  ];

  static const List<ThemePreset> male = <ThemePreset>[
    // 연한색 (Soft)
    ThemePreset(
      id: 'grey_light',
      label: '남성 1 · 쿨 그레이',
      seedColor: Color(0xFFCFD8DC),
    ),
    ThemePreset(
      id: 'slate_light',
      label: '남성 2 · 슬레이트',
      seedColor: Color(0xFF90A4AE),
    ),
    ThemePreset(
      id: 'sage_light',
      label: '남성 3 · 세이지',
      seedColor: Color(0xFFC8E6C9),
    ),
    ThemePreset(
      id: 'sand_light',
      label: '남성 4 · 샌드',
      seedColor: Color(0xFFD7CCC8),
    ),
    ThemePreset(
      id: 'teal_light',
      label: '남성 5 · 페일 틸',
      seedColor: Color(0xFFB2EBF2),
    ),

    // 진한색 (Intense)
    ThemePreset(
      id: 'midnight_intense',
      label: '남성 6 · 미드나잇 (진한색)',
      seedColor: Color(0xFF0D47A1),
      backgroundColor: Color(0xFF030E21),
    ),
    ThemePreset(
      id: 'charcoal_intense',
      label: '남성 7 · 차콜 (진한색)',
      seedColor: Color(0xFF263238),
      backgroundColor: Color(0xFF12181B),
    ),
    ThemePreset(
      id: 'forest_intense',
      label: '남성 8 · 포레스트 (진한색)',
      seedColor: Color(0xFF1B5E20),
      backgroundColor: Color(0xFF061407),
    ),
    ThemePreset(
      id: 'burgundy_intense',
      label: '남성 9 · 버건디 (진한색)',
      seedColor: Color(0xFF880E4F),
      backgroundColor: Color(0xFF1F0312),
    ),
    ThemePreset(
      id: 'navy_intense',
      label: '남성 10 · 네이비 (진한색)',
      seedColor: Color(0xFF1A237E),
      backgroundColor: Color(0xFF05071A),
    ),
  ];

  static const List<ThemePreset> special = <ThemePreset>[
    ThemePreset(
      id: 'midnight_gold',
      label: '스페셜 · 미드나잇 골드',
      seedColor: Color(0xFFFFB300),
      backgroundColor: Color(0xFF050505),
    ),
    ThemePreset(
      id: 'starlight_navy',
      label: '스페셜 · 스타라이트 네이비',
      seedColor: Color(0xFF81D4FA),
      backgroundColor: Color(0xFF020817),
    ),
  ];

  static const List<ThemePreset> all = <ThemePreset>[
    ...female,
    ...male,
    ...special,
  ];

  static ThemePreset byId(String? id) {
    final key = (id ?? '').trim();
    for (final p in all) {
      if (p.id == key) return p;
    }
    return all.first;
  }
}
