import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:smart_ledger/services/audit_log_service.dart';

/// Phase 2 개선: 운영 KPI 대시보드 위젯
/// 정량적 운영 지표를 시각화하여 운영 품질 모니터링
class OperationalKPIDashboard extends StatelessWidget {
  const OperationalKPIDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OperationalMetrics>(
      future: _calculateMetrics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final metrics = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '운영 KPI 대시보드',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MM월 dd일 HH:mm').format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // KPI 메트릭 그리드
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _buildKPITile(
                      context,
                      '성공률',
                      '${metrics.successRate.toStringAsFixed(1)}%',
                      metrics.successRate >= 95
                          ? Colors.green
                          : metrics.successRate >= 85
                          ? Colors.orange
                          : Colors.red,
                      Icons.check_circle,
                      'SLA 목표: 95%',
                    ),
                    _buildKPITile(
                      context,
                      '평균 응답시간',
                      '${metrics.avgResponseTime.toStringAsFixed(1)}ms',
                      metrics.avgResponseTime <= 200
                          ? Colors.green
                          : metrics.avgResponseTime <= 500
                          ? Colors.orange
                          : Colors.red,
                      Icons.speed,
                      '목표: <200ms',
                    ),
                    _buildKPITile(
                      context,
                      '보안 위반',
                      '${metrics.securityViolations}건',
                      metrics.securityViolations == 0
                          ? Colors.green
                          : Colors.red,
                      Icons.security,
                      '목표: 0건',
                    ),
                    _buildKPITile(
                      context,
                      '일일 처리량',
                      '${metrics.dailyTransactions}건',
                      Colors.blue,
                      Icons.trending_up,
                      '전일 대비 ${metrics.dailyGrowth > 0 ? '+' : ''}${metrics.dailyGrowth.toStringAsFixed(1)}%',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 빠른 상태 표시등
                Row(
                  children: [
                    Text(
                      '시스템 상태',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusIndicator('데이터베이스', SystemStatus.healthy),
                    const SizedBox(width: 8),
                    _buildStatusIndicator('백업', SystemStatus.healthy),
                    const SizedBox(width: 8),
                    _buildStatusIndicator(
                      '보안',
                      metrics.anomalyDetections >= 3
                          ? SystemStatus.critical
                          : metrics.anomalyDetections > 0
                          ? SystemStatus.warning
                          : SystemStatus.healthy,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 최근 알림 요약
                if (metrics.recentAlerts.isNotEmpty) ...[
                  Text(
                    '주의가 필요한 항목',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...metrics.recentAlerts
                      .take(3)
                      .map(
                        (alert) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: alert.severity.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: alert.severity.color.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                alert.severity == AlertSeverity.critical
                                    ? Icons.error
                                    : alert.severity == AlertSeverity.warning
                                    ? Icons.warning
                                    : Icons.info,
                                size: 16,
                                color: alert.severity.color,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.message,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      '${DateFormat('HH:mm').format(alert.timestamp)} · ${alert.reason} · ${alert.severity.label}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPITile(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, SystemStatus status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: status.color)),
      ],
    );
  }

  /// KPI 메트릭 계산 (실제 구현에서는 실제 데이터 사용)
  Future<OperationalMetrics> _calculateMetrics() async {
    // 감사 로그에서 실제 데이터 수집
    final recentLogs = await AuditLogService.getRecentLogs();
    final failedLogs = await AuditLogService.getFailedActions();
    final securityViolations = await AuditLogService.getSecurityViolations(
      limit: 10,
    );
    final anomalyDetections =
        await AuditLogService.getRecentAnomalyDetections();

    // 성공률 계산
    final totalActions = recentLogs.length;
    final successfulActions = recentLogs
        .where((log) => log.success == true)
        .length;
    final successRate = totalActions > 0
        ? (successfulActions / totalActions * 100)
        : 100.0;

    // 평균 응답시간 (시뮬레이션)
    final avgResponseTime = 150.0 + (math.Random().nextDouble() * 100);

    // 일일 처리량 (시뮬레이션)
    final dailyTransactions = 45 + math.Random().nextInt(25);
    final dailyGrowth = (math.Random().nextDouble() - 0.5) * 20;

    // 최근 알림 생성
    final recentAlerts = <Alert>[];

    if (failedLogs.isNotEmpty) {
      recentAlerts.add(
        Alert(
          message: '최근 ${failedLogs.length}건의 실패한 작업이 있습니다',
          severity: failedLogs.length > 5
              ? AlertSeverity.critical
              : AlertSeverity.warning,
          timestamp: DateTime.now(),
          reason: '실패 작업 집계',
        ),
      );
    }

    if (securityViolations.isNotEmpty) {
      recentAlerts.add(
        Alert(
          message: '보안 위반 ${securityViolations.length}건 감지됨',
          severity: AlertSeverity.critical,
          timestamp: DateTime.now(),
          reason: '보안 위반 요약',
        ),
      );
    }

    if (anomalyDetections.isNotEmpty) {
      recentAlerts.add(
        Alert(
          message: '최근 이상 징후 ${anomalyDetections.length}건 탐지됨',
          severity: anomalyDetections.length >= 3
              ? AlertSeverity.critical
              : AlertSeverity.warning,
          timestamp: DateTime.now(),
          reason: '탐지 임계치 기반',
        ),
      );
    }

    if (avgResponseTime > 500) {
      recentAlerts.add(
        Alert(
          message: '평균 응답시간이 목표치를 초과했습니다',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now(),
          reason: '성능 임계치 초과',
        ),
      );
    }

    for (final detection in anomalyDetections.take(3)) {
      recentAlerts.add(
        Alert(
          message: _buildDetectionMessage(detection),
          severity: _severityFromDetection(detection),
          timestamp: detection.timestamp,
          reason: _reasonFromDetection(detection),
        ),
      );
    }

    return OperationalMetrics(
      successRate: successRate,
      avgResponseTime: avgResponseTime,
      securityViolations: securityViolations.length,
      anomalyDetections: anomalyDetections.length,
      dailyTransactions: dailyTransactions,
      dailyGrowth: dailyGrowth,
      recentAlerts: recentAlerts,
    );
  }

  String _buildDetectionMessage(AuditLogEntry entry) {
    final observed = entry.metadata?['observedValue'];
    final threshold = entry.metadata?['threshold'];
    if (observed != null && threshold != null) {
      return '${_reasonFromDetection(entry)} (관측: $observed / 임계: $threshold)';
    }
    return _reasonFromDetection(entry);
  }

  String _reasonFromDetection(AuditLogEntry entry) {
    switch (entry.action) {
      case 'anomaly_signal_large_transaction':
        return '고액 거래 이상 징후';
      case 'anomaly_signal_repeated_failures':
        return '반복 실패 이상 징후';
      case 'anomaly_signal_off_hours_sensitive_action':
        return '비정상 시간대 민감 작업';
      case 'anomaly_detection_summary':
        return '이상 징후 종합 경고';
      default:
        return '이상 징후 탐지';
    }
  }

  AlertSeverity _severityFromDetection(AuditLogEntry entry) {
    if (entry.eventType == AuditEventType.securityViolation) {
      return AlertSeverity.critical;
    }
    final observed = entry.metadata?['observedValue'];
    final threshold = entry.metadata?['threshold'];
    if (observed is num && threshold is num && observed >= threshold) {
      return AlertSeverity.critical;
    }
    return AlertSeverity.warning;
  }
}

/// 운영 메트릭 데이터 모델
class OperationalMetrics {
  final double successRate;
  final double avgResponseTime;
  final int securityViolations;
  final int anomalyDetections;
  final int dailyTransactions;
  final double dailyGrowth;
  final List<Alert> recentAlerts;

  const OperationalMetrics({
    required this.successRate,
    required this.avgResponseTime,
    required this.securityViolations,
    required this.anomalyDetections,
    required this.dailyTransactions,
    required this.dailyGrowth,
    required this.recentAlerts,
  });
}

/// 시스템 상태
enum SystemStatus {
  healthy('정상', Colors.green),
  warning('주의', Colors.orange),
  critical('위험', Colors.red);

  const SystemStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// 알림 모델
class Alert {
  final String message;
  final String reason;
  final AlertSeverity severity;
  final DateTime timestamp;

  const Alert({
    required this.message,
    required this.reason,
    required this.severity,
    required this.timestamp,
  });
}

/// 알림 심각도
enum AlertSeverity {
  info('정보', Colors.blue),
  warning('경고', Colors.orange),
  critical('심각', Colors.red);

  const AlertSeverity(this.label, this.color);
  final String label;
  final Color color;
}

/// 실시간 시스템 상태 표시등 위젯
class RealTimeStatusIndicator extends StatefulWidget {
  const RealTimeStatusIndicator({super.key});

  @override
  State<RealTimeStatusIndicator> createState() =>
      _RealTimeStatusIndicatorState();
}

class _RealTimeStatusIndicatorState extends State<RealTimeStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  SystemStatus _currentStatus = SystemStatus.healthy;
  Timer? _refreshTimer;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _updateStatus();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateStatus(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    if (_isUpdating) {
      return;
    }
    _isUpdating = true;

    // 실제 시스템 상태 확인 로직
    try {
      final snapshot = await AuditLogService.getRealtimeSnapshot();
      if (!mounted) return;

      setState(() {
        if (snapshot.hasSecurityViolation || snapshot.anomalyDetections >= 3) {
          _currentStatus = SystemStatus.critical;
        } else if (snapshot.anomalyDetections > 0 ||
            snapshot.recentFailures >= 3) {
          _currentStatus = SystemStatus.warning;
        } else {
          _currentStatus = SystemStatus.healthy;
        }
      });
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _currentStatus.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _currentStatus.color.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 트렌드 차트 위젯 (간단한 선형 차트)
class SimpleTrendChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final String label;

  const SimpleTrendChart({
    super.key,
    required this.data,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _TrendChartPainter(data: data, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _TrendChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final valueRange = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = valueRange > 0
          ? (data[i] - minValue) / valueRange
          : 0.5;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
