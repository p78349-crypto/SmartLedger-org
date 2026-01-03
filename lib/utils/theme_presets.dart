import 'package:flutter/material.dart';

/// Small model for theme presets used across the app.
class ThemeVariant {
  final String id;
  final String name;
  final List<Color> gradient;
  final Color onColor;

  const ThemeVariant({
    required this.id,
    required this.name,
    required this.gradient,
    required this.onColor,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gradient': gradient.map((c) => c.toARGB32()).toList(),
    'onColor': onColor.toARGB32(),
  };

  static ThemeVariant fromJson(Map<String, dynamic> json) {
    final gradient = (json['gradient'] as List)
        .map((v) => Color(v as int))
        .toList();
    return ThemeVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      gradient: gradient,
      onColor: Color(json['onColor'] as int),
    );
  }

  static const ThemeVariant flSoftPink = ThemeVariant(
    id: 'fl_soft_pink',
    name: '소프트 핑크 (여성)',
    gradient: [Color(0xFFFFC1CC), Color(0xFFFFD1DC)],
    onColor: Colors.black87,
  );

  static const ThemeVariant flLavender = ThemeVariant(
    id: 'fl_lavender',
    name: '라벤더 (여성)',
    gradient: [Color(0xFFE1BEE7), Color(0xFFF3E5F5)],
    onColor: Colors.black87,
  );

  static const ThemeVariant flPeach = ThemeVariant(
    id: 'fl_peach',
    name: '피치 (여성)',
    gradient: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)],
    onColor: Colors.black87,
  );

  static const ThemeVariant flMint = ThemeVariant(
    id: 'fl_mint',
    name: '민트 (여성)',
    gradient: [Color(0xFFB2DFDB), Color(0xFFE0F2F1)],
    onColor: Colors.black87,
  );

  static const ThemeVariant flSky = ThemeVariant(
    id: 'fl_sky',
    name: '스카이 (여성)',
    gradient: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
    onColor: Colors.black87,
  );

  static const ThemeVariant fiRose = ThemeVariant(
    id: 'fi_rose',
    name: '딥 로즈 (여성 진한색)',
    gradient: [Color(0xFFD81B60), Color(0xFFAD1457)],
    onColor: Colors.white,
  );

  static const ThemeVariant fiPurple = ThemeVariant(
    id: 'fi_purple',
    name: '로열 퍼플 (여성 진한색)',
    gradient: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
    onColor: Colors.white,
  );

  static const ThemeVariant fiOrange = ThemeVariant(
    id: 'fi_orange',
    name: '선셋 오렌지 (여성 진한색)',
    gradient: [Color(0xFFEF6C00), Color(0xFFE65100)],
    onColor: Colors.white,
  );

  static const ThemeVariant fiEmerald = ThemeVariant(
    id: 'fi_emerald',
    name: '에메랄드 (여성 진한색)',
    gradient: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    onColor: Colors.white,
  );

  static const ThemeVariant fiIndigo = ThemeVariant(
    id: 'fi_indigo',
    name: '인디고 (여성 진한색)',
    gradient: [Color(0xFF283593), Color(0xFF1A237E)],
    onColor: Colors.white,
  );

  static const ThemeVariant mlGrey = ThemeVariant(
    id: 'ml_grey',
    name: '쿨 그레이 (남성)',
    gradient: [Color(0xFFCFD8DC), Color(0xFFECEFF1)],
    onColor: Colors.black87,
  );

  static const ThemeVariant mlSlate = ThemeVariant(
    id: 'ml_slate',
    name: '슬레이트 블루 (남성)',
    gradient: [Color(0xFF90A4AE), Color(0xFFB0BEC5)],
    onColor: Colors.black87,
  );

  static const ThemeVariant mlSage = ThemeVariant(
    id: 'ml_sage',
    name: '세이지 그린 (남성)',
    gradient: [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
    onColor: Colors.black87,
  );

  static const ThemeVariant mlSand = ThemeVariant(
    id: 'ml_sand',
    name: '샌드 (남성)',
    gradient: [Color(0xFFD7CCC8), Color(0xFFEFEBE9)],
    onColor: Colors.black87,
  );

  static const ThemeVariant mlTeal = ThemeVariant(
    id: 'ml_teal',
    name: '페일 틸 (남성)',
    gradient: [Color(0xFFB2EBF2), Color(0xFFE0F7FA)],
    onColor: Colors.black87,
  );

  static const ThemeVariant miMidnight = ThemeVariant(
    id: 'mi_midnight',
    name: '미드나잇 블루 (남성 진한색)',
    gradient: [Color(0xFF0D47A1), Color(0xFF01579B)],
    onColor: Colors.white,
  );

  static const ThemeVariant miCharcoal = ThemeVariant(
    id: 'mi_charcoal',
    name: '차콜 (남성 진한색)',
    gradient: [Color(0xFF263238), Color(0xFF212121)],
    onColor: Colors.white,
  );

  static const ThemeVariant miForest = ThemeVariant(
    id: 'mi_forest',
    name: '포레스트 그린 (남성 진한색)',
    gradient: [Color(0xFF1B5E20), Color(0xFF004D40)],
    onColor: Colors.white,
  );

  static const ThemeVariant miBurgundy = ThemeVariant(
    id: 'mi_burgundy',
    name: '딥 버건디 (남성 진한색)',
    gradient: [Color(0xFF880E4F), Color(0xFF4A148C)],
    onColor: Colors.white,
  );

  static const ThemeVariant miNavy = ThemeVariant(
    id: 'mi_navy',
    name: '네이비 블루 (남성 진한색)',
    gradient: [Color(0xFF1A237E), Color(0xFF0D47A1)],
    onColor: Colors.white,
  );

  static const List<ThemeVariant> all = [
    flSoftPink,
    flLavender,
    flPeach,
    flMint,
    flSky,
    fiRose,
    fiPurple,
    fiOrange,
    fiEmerald,
    fiIndigo,
    mlGrey,
    mlSlate,
    mlSage,
    mlSand,
    mlTeal,
    miMidnight,
    miCharcoal,
    miForest,
    miBurgundy,
    miNavy,
  ];

  static ThemeVariant? byId(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }
}
