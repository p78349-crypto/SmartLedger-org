import 'package:flutter/material.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

/// 날씨 수집 유틸리티
/// - 하루 1회 자동 수집 (앱 시작 시)
/// - 수동 수집 (사용자 요청 시)

class WeatherSnapshot {
  final String condition; // 맑음, 흐림, 비, 눈
  final double tempC;
  final DateTime capturedAt;
  final String source; // 'auto', 'manual'

  WeatherSnapshot({
    required this.condition,
    required this.tempC,
    required this.capturedAt,
    required this.source,
  });

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      condition: json['condition'] as String,
      tempC: (json['tempC'] as num).toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'tempC': tempC,
      'capturedAt': capturedAt.toIso8601String(),
      'source': source,
    };
  }

  @override
  String toString() => 'WeatherSnapshot($condition, $tempC°C, $capturedAt)';
}

class WeatherCaptureUtils {
  /// 하루 1회 자동 수집 여부 체크
  static bool shouldCaptureToday(DateTime? lastCaptureDate) {
    if (lastCaptureDate == null) return true;

    final now = DateTime.now();
    return !(lastCaptureDate.year == now.year &&
        lastCaptureDate.month == now.month &&
        lastCaptureDate.day == now.day);
  }

  /// 날씨 자동 수집 (시뮬레이션)
  static Future<WeatherSnapshot> captureWeather({bool isAuto = false}) async {
    // 실제 API 호출 시간 시뮬레이션 (1~2초)
    await Future.delayed(const Duration(milliseconds: 1500));

    final now = DateTime.now();
    final conditions = ['맑음', '흐림', '비', '눈'];
    final randomCondition = conditions[now.second % conditions.length];

    return WeatherSnapshot(
      condition: randomCondition,
      tempC: 20.0 + (now.second % 10).toDouble(), // 20~30°C
      capturedAt: now,
      source: isAuto ? 'auto' : 'manual',
    );
  }

  /// 날씨 스냅샷 조건 레이블
  static IconData getWeatherIcon(String condition) {
    return switch (condition) {
      '맑음' => IconCatalog.wbSunny,
      '흐림' => IconCatalog.wbCloudy,
      '비' => IconCatalog.cloudQueue,
      '눈' => IconCatalog.acUnit,
      _ => IconCatalog.wbSunny,
    };
  }

  /// 날씨 배경 색상
  static Color getWeatherColor(String condition) {
    return switch (condition) {
      '맑음' => Colors.orange.shade300,
      '흐림' => Colors.grey.shade400,
      '비' => Colors.blue.shade300,
      '눈' => Colors.blue.shade100,
      _ => Colors.grey.shade300,
    };
  }
}

