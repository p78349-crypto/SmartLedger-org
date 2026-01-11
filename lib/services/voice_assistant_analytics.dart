import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 음성 어시스턴트 사용 통계 분석 서비스
///
/// Bixby, Siri, Google Assistant 명령 사용 패턴을 로컬에 집계하여
/// 성공률, 실패 원인, 자주 사용하는 기능 등을 분석합니다.
class VoiceAssistantAnalytics {
  VoiceAssistantAnalytics._();

  static const _prefPrefix = 'va_stats_';
  static const _maxRetentionDays = 30;

  /// 명령 실행 로그 기록
  ///
  /// [assistant] - 'bixby', 'siri', 'google'
  /// [route] - 대상 라우트
  /// [intent] - 명령 의도 (upsert, scan 등)
  /// [success] - 성공 여부
  /// [failureReason] - 실패 이유 (선택)
  static Future<void> logCommand({
    required String assistant,
    required String route,
    required String intent,
    required bool success,
    String? failureReason,
    Map<String, String>? params,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 통계 키
      final key = '$_prefPrefix${assistant}_$route';

      // 기존 통계 불러오기
      final existing = prefs.getString(key);
      final stats = existing != null
          ? VoiceCommandStats.fromJson(jsonDecode(existing))
          : VoiceCommandStats(assistant: assistant, route: route);

      // 통계 업데이트
      stats.totalCommands++;
      if (success) {
        stats.successCount++;
      } else {
        stats.failureCount++;
        final reason = failureReason ?? 'unknown';
        stats.failureReasons[reason] = (stats.failureReasons[reason] ?? 0) + 1;
      }
      stats.lastUsed = DateTime.now();

      // 저장
      await prefs.setString(key, jsonEncode(stats.toJson()));

      // 디버그 로그
      debugPrint(
        'VoiceAssistant: $assistant → $route ($intent) '
        '${success ? "✓" : "✗${failureReason != null ? " ($failureReason)" : ""}"}',
      );
    } catch (e) {
      debugPrint('VoiceAssistantAnalytics.logCommand error: $e');
    }
  }

  /// 에러 로그 기록
  static Future<void> logError({
    required String errorType,
    required String route,
    String? assistant,
    Map<String, String>? context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefPrefix}error_$errorType';

      final existing = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, existing + 1);

      debugPrint(
        'VoiceAssistant Error: $errorType at $route '
        '${assistant != null ? "($assistant)" : ""}',
      );
    } catch (e) {
      debugPrint('VoiceAssistantAnalytics.logError error: $e');
    }
  }

  /// 거부된 파라미터 로그
  static Future<void> logRejectedParams({
    required String route,
    required List<String> rejected,
    String? assistant,
  }) async {
    try {
      if (rejected.isEmpty) return;

      debugPrint(
        'VoiceAssistant: Rejected params for $route: $rejected'
        '${assistant != null ? " ($assistant)" : ""}',
      );

      // 간단한 카운터 (향후 Firebase Analytics 연동 시 확장)
      final prefs = await SharedPreferences.getInstance();
      const key = '${_prefPrefix}rejected_params_count';
      final existing = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, existing + rejected.length);
    } catch (e) {
      debugPrint('VoiceAssistantAnalytics.logRejectedParams error: $e');
    }
  }

  /// 전체 통계 조회
  static Future<List<VoiceCommandStats>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (k) => k.startsWith(_prefPrefix) && !k.contains('error'),
      );

      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: _maxRetentionDays));

      final stats = <VoiceCommandStats>[];
      for (final key in keys) {
        final json = prefs.getString(key);
        if (json == null) continue;

        try {
          final stat = VoiceCommandStats.fromJson(jsonDecode(json));

          // 오래된 데이터 제거
          if (stat.lastUsed.isBefore(cutoff)) {
            await prefs.remove(key);
            continue;
          }

          stats.add(stat);
        } catch (_) {
          // 잘못된 데이터 제거
          await prefs.remove(key);
        }
      }

      // 사용 빈도순 정렬
      stats.sort((a, b) => b.totalCommands.compareTo(a.totalCommands));
      return stats;
    } catch (e) {
      debugPrint('VoiceAssistantAnalytics.getStats error: $e');
      return [];
    }
  }

  /// 통계 초기화
  static Future<void> clearStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefPrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('VoiceAssistant: Stats cleared');
    } catch (e) {
      debugPrint('VoiceAssistantAnalytics.clearStats error: $e');
    }
  }

  /// 어시스턴트 감지 (딥링크 컨텍스트 기반 추정)
  static String detectAssistant(Map<String, String>? params) {
    // 향후 확장: User-Agent 또는 딥링크 origin 파라미터 기반
    // 현재는 단순 추정
    return 'unknown';
  }
}

/// 음성 명령 통계 모델
class VoiceCommandStats {
  final String assistant;
  final String route;
  int totalCommands;
  int successCount;
  int failureCount;
  Map<String, int> failureReasons;
  DateTime lastUsed;

  VoiceCommandStats({
    required this.assistant,
    required this.route,
    this.totalCommands = 0,
    this.successCount = 0,
    this.failureCount = 0,
    Map<String, int>? failureReasons,
    DateTime? lastUsed,
  }) : failureReasons = failureReasons ?? {},
       lastUsed = lastUsed ?? DateTime.now();

  /// 성공률 (0.0 ~ 1.0)
  double get successRate =>
      totalCommands == 0 ? 0 : successCount / totalCommands;

  Map<String, dynamic> toJson() => {
    'assistant': assistant,
    'route': route,
    'totalCommands': totalCommands,
    'successCount': successCount,
    'failureCount': failureCount,
    'failureReasons': failureReasons,
    'lastUsed': lastUsed.toIso8601String(),
  };

  factory VoiceCommandStats.fromJson(Map<String, dynamic> json) =>
      VoiceCommandStats(
        assistant: json['assistant'] as String,
        route: json['route'] as String,
        totalCommands: json['totalCommands'] as int? ?? 0,
        successCount: json['successCount'] as int? ?? 0,
        failureCount: json['failureCount'] as int? ?? 0,
        failureReasons: Map<String, int>.from(
          json['failureReasons'] as Map? ?? {},
        ),
        lastUsed: DateTime.parse(json['lastUsed'] as String),
      );

  @override
  String toString() =>
      'VoiceCommandStats('
      'assistant: $assistant, '
      'route: $route, '
      'total: $totalCommands, '
      'success: $successCount, '
      'failure: $failureCount, '
      'successRate: ${(successRate * 100).toStringAsFixed(1)}%)';
}
