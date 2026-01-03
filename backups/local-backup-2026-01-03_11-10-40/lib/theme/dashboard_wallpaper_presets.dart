import 'package:flutter/material.dart';

/// Immutable descriptor for dashboard wallpaper presets.
class DashboardWallpaperPreset {
  final String id;
  final String name;
  final String description;
  final Gradient gradient;
  final Color overlayColor;

  const DashboardWallpaperPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.gradient,
    this.overlayColor = const Color(0x33000000),
  });
}

const List<DashboardWallpaperPreset> dashboardWallpaperPresets = [
  DashboardWallpaperPreset(
    id: 'vibrant_blue',
    name: '비브런트 블루',
    description: '푸른 그라디언트로 시원한 느낌 제공',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    ),
  ),
  DashboardWallpaperPreset(
    id: 'sunset_orange',
    name: '선셋 오렌지',
    description: '주황/보라 조합으로 생동감 부여',
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF512F), Color(0xFFF09819)],
    ),
  ),
  DashboardWallpaperPreset(
    id: 'forest_green',
    name: '포레스트 그린',
    description: '녹색 계열로 차분하고 안정적인 분위기',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0B486B), Color(0xFF3B8686), Color(0xFF79BD9A)],
    ),
  ),
  DashboardWallpaperPreset(
    id: 'midnight',
    name: '미드나잇',
    description: '짙은 남색/보라 톤으로 다크 모드 느낌',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1D2B64), Color(0xFF1E3C72)],
    ),
    overlayColor: Color(0x55000000),
  ),
];
