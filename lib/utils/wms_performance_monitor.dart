import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// 📊 WMS 성능 모니터링 및 최적화 도구
class WmsPerformanceMonitor {
  WmsPerformanceMonitor._();
  static final WmsPerformanceMonitor instance = WmsPerformanceMonitor._();

  // 📊 성능 메트릭 수집
  final Queue<PerformanceMetric> _metrics = Queue<PerformanceMetric>();
  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, List<int>> _operationTimes = {};

  // 📈 실시간 통계
  final ValueNotifier<WmsPerformanceStats> _currentStats = ValueNotifier(
    WmsPerformanceStats.empty(),
  );

  // ⚙️ 설정
  static const int _maxMetrics = 1000; // 최대 메트릭 수
  static const Duration _statsUpdateInterval = Duration(
    seconds: 5,
  ); // 통계 업데이트 간격

  Timer? _statsUpdateTimer;
  bool _isInitialized = false;

  /// 🚀 모니터링 시작
  void initialize() {
    if (_isInitialized) return;

    _startStatsUpdateTimer();
    _isInitialized = true;
    _log('WMS 성능 모니터링 시작');
  }

  /// ⏰ 작업 시간 측정 시작
  void startOperation(String operationName) {
    final timer = Stopwatch()..start();
    _activeTimers[operationName] = timer;

    _log('작업 시작: $operationName');
  }

  /// ⏹️ 작업 시간 측정 종료
  int endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final timer = _activeTimers.remove(operationName);
    if (timer == null) {
      _log('경고: 시작되지 않은 작업 종료 시도 - $operationName');
      return 0;
    }

    timer.stop();
    final elapsedMs = timer.elapsedMilliseconds;

    // 📊 메트릭 기록
    _recordMetric(
      PerformanceMetric(
        operationName: operationName,
        elapsedMs: elapsedMs,
        timestamp: DateTime.now(),
        metadata: metadata,
      ),
    );

    // 📈 통계 업데이트
    _updateOperationStats(operationName, elapsedMs);

    _log('작업 완료: $operationName (${elapsedMs}ms)');
    return elapsedMs;
  }

  /// 📝 메트릭 기록
  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);

    // 📊 메모리 관리: 오래된 메트릭 정리
    while (_metrics.length > _maxMetrics) {
      _metrics.removeFirst();
    }
  }

  /// 📈 작업별 통계 업데이트
  void _updateOperationStats(String operationName, int elapsedMs) {
    // 📊 카운트 증가
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    // ⏱️ 시간 기록
    if (!_operationTimes.containsKey(operationName)) {
      _operationTimes[operationName] = [];
    }
    _operationTimes[operationName]!.add(elapsedMs);

    // 📚 메모리 관리: 최근 100개만 유지
    if (_operationTimes[operationName]!.length > 100) {
      _operationTimes[operationName]!.removeAt(0);
    }
  }

  /// ⏰ 주기적 통계 업데이트
  void _startStatsUpdateTimer() {
    _statsUpdateTimer?.cancel();
    _statsUpdateTimer = Timer.periodic(_statsUpdateInterval, (_) {
      _updateCurrentStats();
    });
  }

  /// 📊 현재 통계 계산 및 업데이트
  void _updateCurrentStats() {
    final stats = WmsPerformanceStats(
      totalOperations: _operationCounts.values.fold(0, (a, b) => a + b),
      operationStats: _calculateOperationStats(),
      recentMetrics: _getRecentMetrics(50),
      slowOperations: _identifySlowOperations(),
      systemHealth: _calculateSystemHealth(),
      memoryUsage: _calculateMemoryUsage(),
      lastUpdated: DateTime.now(),
    );

    _currentStats.value = stats;
  }

  /// 📊 작업별 상세 통계 계산
  Map<String, OperationStats> _calculateOperationStats() {
    final stats = <String, OperationStats>{};

    for (final entry in _operationTimes.entries) {
      final operationName = entry.key;
      final times = entry.value;

      if (times.isEmpty) continue;

      times.sort();
      final count = times.length;
      final total = times.fold(0, (a, b) => a + b);
      final average = total / count;
      final median = times[count ~/ 2].toDouble();
      final p95 = times[(count * 0.95).round() - 1].toDouble();
      final min = times.first.toDouble();
      final max = times.last.toDouble();

      stats[operationName] = OperationStats(
        operationName: operationName,
        count: count,
        averageMs: average,
        medianMs: median,
        p95Ms: p95,
        minMs: min,
        maxMs: max,
        totalMs: total,
      );
    }

    return stats;
  }

  /// 🕐 최근 메트릭 가져오기
  List<PerformanceMetric> _getRecentMetrics(int count) {
    final recent = _metrics.toList();
    recent.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return recent.take(count).toList();
  }

  /// 🐌 느린 작업 식별
  List<SlowOperation> _identifySlowOperations() {
    final slowOps = <SlowOperation>[];

    for (final entry in _operationTimes.entries) {
      final operationName = entry.key;
      final times = entry.value;

      if (times.isEmpty) continue;

      final average = times.fold(0, (a, b) => a + b) / times.length;
      final threshold = _getSlowThreshold(operationName);

      if (average > threshold) {
        slowOps.add(
          SlowOperation(
            operationName: operationName,
            averageMs: average,
            threshold: threshold,
            severity: _calculateSeverity(average, threshold),
          ),
        );
      }
    }

    // 심각도 순으로 정렬
    slowOps.sort((a, b) => b.severity.compareTo(a.severity));
    return slowOps.take(10).toList(); // 상위 10개만
  }

  /// 🎯 작업별 임계값 설정
  double _getSlowThreshold(String operationName) {
    switch (operationName) {
      case 'barcode_search':
        return 1000; // 1초
      case 'cache_load':
        return 500; // 0.5초
      case 'db_query':
        return 300; // 0.3초
      case 'api_call':
        return 2000; // 2초
      default:
        return 1000; // 기본 1초
    }
  }

  /// ⚠️ 심각도 계산
  double _calculateSeverity(double average, double threshold) {
    return (average / threshold).clamp(1.0, 5.0);
  }

  /// 💚 시스템 건강도 계산
  SystemHealth _calculateSystemHealth() {
    final recentMetrics = _getRecentMetrics(100);
    if (recentMetrics.isEmpty) {
      return SystemHealth.unknown;
    }

    final averageTime =
        recentMetrics.map((m) => m.elapsedMs).fold(0, (a, b) => a + b) /
        recentMetrics.length;

    final errorRate = _calculateErrorRate();

    if (averageTime < 500 && errorRate < 0.05) {
      return SystemHealth.excellent;
    } else if (averageTime < 1000 && errorRate < 0.1) {
      return SystemHealth.good;
    } else if (averageTime < 2000 && errorRate < 0.2) {
      return SystemHealth.fair;
    } else {
      return SystemHealth.poor;
    }
  }

  /// ❌ 오류율 계산 (임시 구현)
  double _calculateErrorRate() {
    // TODO: 실제 오류 추적 로직 구현
    return 0.0;
  }

  /// 💾 메모리 사용량 추정
  MemoryUsage _calculateMemoryUsage() {
    final metricsSize = _metrics.length * 200; // 대략적인 메트릭 크기
    final timersSize = _activeTimers.length * 100; // 타이머 크기
    final statsSize =
        _operationTimes.values.fold(0, (total, times) => total + times.length) *
        4; // int 크기

    final totalBytes = metricsSize + timersSize + statsSize;

    return MemoryUsage(
      totalBytes: totalBytes,
      metricsBytes: metricsSize,
      timersBytes: timersSize,
      statsBytes: statsSize,
    );
  }

  /// 📊 성능 리포트 생성
  String generateReport() {
    final stats = _currentStats.value;
    final buffer = StringBuffer();

    buffer.writeln('=== WMS 성능 리포트 ===');
    buffer.writeln('생성 시간: ${DateTime.now()}');
    buffer.writeln('총 작업 수: ${stats.totalOperations}');
    buffer.writeln('시스템 건강도: ${stats.systemHealth}');
    buffer.writeln();

    buffer.writeln('=== 작업별 통계 ===');
    for (final entry in stats.operationStats.entries) {
      final opStat = entry.value;
      buffer.writeln('${opStat.operationName}:');
      buffer.writeln('  • 실행 횟수: ${opStat.count}');
      buffer.writeln('  • 평균 시간: ${opStat.averageMs.toStringAsFixed(1)}ms');
      buffer.writeln('  • 중간값: ${opStat.medianMs.toStringAsFixed(1)}ms');
      buffer.writeln(
        '  • 95th percentile: ${opStat.p95Ms.toStringAsFixed(1)}ms',
      );
      buffer.writeln();
    }

    if (stats.slowOperations.isNotEmpty) {
      buffer.writeln('=== 느린 작업 ===');
      for (final slowOp in stats.slowOperations) {
        buffer.writeln(
          '${slowOp.operationName}: ${slowOp.averageMs.toStringAsFixed(1)}ms (기준: ${slowOp.threshold}ms)',
        );
      }
    }

    return buffer.toString();
  }

  /// 📊 현재 통계 스트림
  ValueNotifier<WmsPerformanceStats> get statsStream => _currentStats;

  /// 🧹 리소스 정리
  void dispose() {
    _statsUpdateTimer?.cancel();
    _activeTimers.clear();
    _metrics.clear();
    _operationCounts.clear();
    _operationTimes.clear();
    _currentStats.dispose();
    _isInitialized = false;
  }

  /// 📝 로깅
  void _log(String message) {
    if (kDebugMode) {
      print('[WmsPerformanceMonitor] $message');
    }
  }
}

/// 📊 성능 메트릭 모델
class PerformanceMetric {
  final String operationName;
  final int elapsedMs;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const PerformanceMetric({
    required this.operationName,
    required this.elapsedMs,
    required this.timestamp,
    this.metadata,
  });
}

/// 📈 전체 성능 통계
class WmsPerformanceStats {
  final int totalOperations;
  final Map<String, OperationStats> operationStats;
  final List<PerformanceMetric> recentMetrics;
  final List<SlowOperation> slowOperations;
  final SystemHealth systemHealth;
  final MemoryUsage memoryUsage;
  final DateTime lastUpdated;

  const WmsPerformanceStats({
    required this.totalOperations,
    required this.operationStats,
    required this.recentMetrics,
    required this.slowOperations,
    required this.systemHealth,
    required this.memoryUsage,
    required this.lastUpdated,
  });

  factory WmsPerformanceStats.empty() {
    return WmsPerformanceStats(
      totalOperations: 0,
      operationStats: {},
      recentMetrics: [],
      slowOperations: [],
      systemHealth: SystemHealth.unknown,
      memoryUsage: MemoryUsage.empty(),
      lastUpdated: DateTime.now(),
    );
  }
}

/// 📊 작업별 통계
class OperationStats {
  final String operationName;
  final int count;
  final double averageMs;
  final double medianMs;
  final double p95Ms;
  final double minMs;
  final double maxMs;
  final int totalMs;

  const OperationStats({
    required this.operationName,
    required this.count,
    required this.averageMs,
    required this.medianMs,
    required this.p95Ms,
    required this.minMs,
    required this.maxMs,
    required this.totalMs,
  });
}

/// 🐌 느린 작업
class SlowOperation {
  final String operationName;
  final double averageMs;
  final double threshold;
  final double severity;

  const SlowOperation({
    required this.operationName,
    required this.averageMs,
    required this.threshold,
    required this.severity,
  });
}

/// 💚 시스템 건강도
enum SystemHealth {
  excellent, // 우수
  good, // 양호
  fair, // 보통
  poor, // 나쁨
  unknown, // 알 수 없음
}

/// 💾 메모리 사용량
class MemoryUsage {
  final int totalBytes;
  final int metricsBytes;
  final int timersBytes;
  final int statsBytes;

  const MemoryUsage({
    required this.totalBytes,
    required this.metricsBytes,
    required this.timersBytes,
    required this.statsBytes,
  });

  factory MemoryUsage.empty() {
    return const MemoryUsage(
      totalBytes: 0,
      metricsBytes: 0,
      timersBytes: 0,
      statsBytes: 0,
    );
  }

  double get totalKB => totalBytes / 1024;
  double get totalMB => totalKB / 1024;
}
