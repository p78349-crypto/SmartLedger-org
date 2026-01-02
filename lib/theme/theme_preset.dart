import 'package:flutter/material.dart';
import 'package:smart_ledger/theme/app_colors.dart';

class ThemePreset {
  final String id;
  final String label;
  final Color seedColor;

  const ThemePreset({
    required this.id,
    required this.label,
    required this.seedColor,
  });
}

class ThemePresets {
  ThemePresets._();

  static const String defaultId = 'blue';

  /// Samsung One UI 느낌(깔끔한 Material3 + SeedColor 기반)으로 쓰기 좋은
  /// 프리셋 10개.
  ///
  /// - 새로운 색을 하드코딩하지 않고, 기존 AppColors / 기본 Colors만 사용.
  static const List<ThemePreset> female = <ThemePreset>[
    ThemePreset(id: 'pink', label: '여성 1 · 핑크', seedColor: AppColors.chartPink),
    ThemePreset(id: 'purple', label: '여성 2 · 퍼플', seedColor: AppColors.chartPurple),
    ThemePreset(id: 'violet', label: '여성 3 · 바이올렛', seedColor: AppColors.primaryDark),
    ThemePreset(id: 'amber', label: '여성 4 · 골드', seedColor: AppColors.warning),
    ThemePreset(id: 'sky', label: '여성 5 · 스카이', seedColor: AppColors.info),
  ];

  static const List<ThemePreset> male = <ThemePreset>[
    ThemePreset(id: 'blue', label: '남성 1 · 블루(기본)', seedColor: Colors.blue),
    ThemePreset(id: 'indigo', label: '남성 2 · 인디고', seedColor: AppColors.primary),
    ThemePreset(id: 'teal', label: '남성 3 · 틸', seedColor: AppColors.chartTeal),
    ThemePreset(id: 'green', label: '남성 4 · 그린', seedColor: AppColors.success),
    ThemePreset(id: 'red', label: '남성 5 · 레드', seedColor: AppColors.error),
  ];

  static const List<ThemePreset> all = <ThemePreset>[
    ...female,
    ...male,
  ];

  static ThemePreset byId(String? id) {
    final key = (id ?? '').trim();
    for (final p in all) {
      if (p.id == key) return p;
    }
    return all.first;
  }
}

