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

  static const ThemeVariant vibrantBlue = ThemeVariant(
    id: 'vibrant_blue',
    name: 'Vibrant Blue',
    gradient: [Color(0xFF0F62FE), Color(0xFF00D4FF)],
    onColor: Colors.white,
  );

  static const ThemeVariant aquaGreen = ThemeVariant(
    id: 'aqua_green',
    name: 'Aqua Green',
    gradient: [Color(0xFF00C2A8), Color(0xFF00E676)],
    onColor: Colors.white,
  );

  static const ThemeVariant purplePink = ThemeVariant(
    id: 'purple_pink',
    name: 'Purple Pink',
    gradient: [Color(0xFF7C4DFF), Color(0xFFFF6EC7)],
    onColor: Colors.white,
  );

  static const ThemeVariant warmOrange = ThemeVariant(
    id: 'warm_orange',
    name: 'Warm Orange',
    gradient: [Color(0xFFFF9A3D), Color(0xFFFFD54F)],
    onColor: Colors.black,
  );

  static const ThemeVariant neutralDark = ThemeVariant(
    id: 'neutral_dark',
    name: 'Dark Neutral',
    gradient: [Color(0xFF0F1720), Color(0xFF161B22)],
    onColor: Colors.white,
  );

  static const List<ThemeVariant> all = [
    vibrantBlue,
    aquaGreen,
    purplePink,
    warmOrange,
    neutralDark,
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
