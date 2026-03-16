import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';

/// 감사 로그 템플릿 시스템
/// Phase 1 개선: 감사 로그 표준화 및 템플릿 통일
class AuditLogService {
  static const String _logFileName = 'audit_log.jsonl';
  static const Set<String> _reservedTransactionMetadataKeys = {
    'schemaVersion',
    'accountId',
    'amount',
    'transactionId',
  };

  /// 거래 이벤트 표준 로그 기록
  ///
  /// 필수 메타 필드:
  /// - accountId
  /// - amount
  /// - transactionId
  /// - schemaVersion
  static Future<void> logTransactionEvent({
    required String action,
    required String accountId,
    required double amount,
    required String transactionId,
    String? transactionType,
    bool success = true,
    String? errorMessage,
    ActionRiskLevel? riskLevel,
    Map<String, dynamic>? metadata,
  }) async {
    await _validateReservedTransactionMetadataKeys(metadata);

    final mergedMetadata = <String, dynamic>{
      ...?metadata,
      'schemaVersion': 'transaction_event_v1',
      'accountId': accountId,
      'amount': amount,
      'transactionId': transactionId,
    };
    if (transactionType != null) {
      mergedMetadata['transactionType'] = transactionType;
    }

    if (success) {
      return logSuccess(
        eventType: AuditEventType.dataModification,
        action: action,
        userLevel: UserPermissionLevel.operator,
        targetResource: accountId,
        metadata: mergedMetadata,
        riskLevel: riskLevel,
      );
    }

    return logFailure(
      eventType: AuditEventType.dataModification,
      action: action,
      userLevel: UserPermissionLevel.operator,
      targetResource: accountId,
      metadata: mergedMetadata,
      riskLevel: riskLevel,
      errorMessage: errorMessage ?? 'transaction_event_failed',
    );
  }

  static Future<void> _validateReservedTransactionMetadataKeys(
    Map<String, dynamic>? metadata,
  ) async {
    if (metadata == null || metadata.isEmpty) {
      return;
    }

    final conflicts = metadata.keys
        .where(_reservedTransactionMetadataKeys.contains)
        .toList();
    if (conflicts.isNotEmpty) {
      final message =
          '거래 표준 로그의 고정 키는 metadata에서 설정할 수 없습니다. '
          '충돌 키: ${conflicts.join(', ')}. '
          '확장 정보는 custom.* 형태의 별도 키를 사용해 주세요.';
      debugPrint('[AuditLogService] reserved-key conflict: $message');
      await log(
        eventType: AuditEventType.policyEnforcement,
        action: 'reserved_metadata_key_conflict',
        userLevel: UserPermissionLevel.operator,
        metadata: {'conflictKeys': conflicts},
        success: false,
        errorMessage: message,
      );
      throw ArgumentError(message);
    }
  }
  
  /// 감사 로그 기록
  static Future<void> log({
    required AuditEventType eventType,
    required String action,
    required UserPermissionLevel userLevel,
    String? userId,
    String? targetResource,
    Map<String, dynamic>? metadata,
    bool? success,
    String? errorMessage,
    ActionRiskLevel? riskLevel,
  }) async {
    final entry = AuditLogEntry(
      timestamp: DateTime.now(),
      eventType: eventType,
      action: action,
      userLevel: userLevel,
      userId: userId,
      targetResource: targetResource,
      metadata: metadata,
      success: success,
      errorMessage: errorMessage,
      riskLevel: riskLevel,
    );

    await _writeLogEntry(entry);
  }

  /// 성공적인 작업 로깅
  static Future<void> logSuccess({
    required AuditEventType eventType,
    required String action,
    required UserPermissionLevel userLevel,
    String? userId,
    String? targetResource,
    Map<String, dynamic>? metadata,
    ActionRiskLevel? riskLevel,
  }) async {
    return log(
      eventType: eventType,
      action: action,
      userLevel: userLevel,
      userId: userId,
      targetResource: targetResource,
      metadata: metadata,
      success: true,
      riskLevel: riskLevel,
    );
  }

  /// 실패한 작업 로깅
  static Future<void> logFailure({
    required AuditEventType eventType,
    required String action,
    required UserPermissionLevel userLevel,
    required String errorMessage,
    String? userId,
    String? targetResource,
    Map<String, dynamic>? metadata,
    ActionRiskLevel? riskLevel,
  }) async {
    return log(
      eventType: eventType,
      action: action,
      userLevel: userLevel,
      userId: userId,
      targetResource: targetResource,
      metadata: metadata,
      success: false,
      errorMessage: errorMessage,
      riskLevel: riskLevel,
    );
  }

  /// 권한 검사 실패 로깅
  static Future<void> logPermissionDenied({
    required String action,
    required UserPermissionLevel userLevel,
    required ActionRiskLevel requiredLevel,
    String? userId,
    String? targetResource,
    Map<String, dynamic>? metadata,
  }) async {
    return log(
      eventType: AuditEventType.securityViolation,
      action: action,
      userLevel: userLevel,
      userId: userId,
      targetResource: targetResource,
      success: false,
      errorMessage: 'Permission denied: required ${requiredLevel.displayName}, current ${userLevel.displayName}',
      riskLevel: requiredLevel,
      metadata: {
        'required_permission': requiredLevel.displayName,
        'actual_permission': userLevel.displayName,
        ...?metadata,
      },
    );
  }

  /// 로그 파일에 엔트리 작성
  static Future<void> _writeLogEntry(AuditLogEntry entry) async {
    try {
      // TODO: 실제 로그 파일 경로 설정
      final logFile = File(_logFileName);
      final jsonLine = '${jsonEncode(entry.toJson())}\n';
      await logFile.writeAsString(jsonLine, mode: FileMode.append);
    } catch (e) {
      // 로깅 실패는 조용히 처리 (무한 루프 방지)
      debugPrint('Audit log write failed: $e');
    }
  }

  /// 실시간 상태 계산용 스냅샷 (파일 1회 읽기)
  static Future<AuditRealtimeSnapshot> getRealtimeSnapshot({
    int lookback = 30,
  }) async {
    final logs = await getRecentLogs(limit: lookback);
    var hasSecurityViolation = false;
    var anomalyDetections = 0;
    var recentFailures = 0;

    for (final log in logs) {
      if (log.eventType == AuditEventType.securityViolation) {
        hasSecurityViolation = true;
      }
      if (log.success == false) {
        recentFailures += 1;
      }
      if (log.eventType == AuditEventType.policyEnforcement &&
          log.action.startsWith('anomaly_signal_')) {
        anomalyDetections += 1;
      } else if (log.eventType == AuditEventType.securityViolation &&
          log.action == 'anomaly_detection_summary') {
        anomalyDetections += 1;
      }
    }

    return AuditRealtimeSnapshot(
      hasSecurityViolation: hasSecurityViolation,
      anomalyDetections: anomalyDetections,
      recentFailures: recentFailures,
    );
  }

  /// 최근 로그 항목들 조회
  static Future<List<AuditLogEntry>> getRecentLogs({int limit = 100}) async {
    try {
      final logFile = File(_logFileName);
      if (!logFile.existsSync()) return [];
      
        final lines = await logFile
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();
      final entries = <AuditLogEntry>[];
      
      // 뒤에서부터 읽어서 최신 순으로
      for (int i = lines.length - 1; i >= 0 && entries.length < limit; i--) {
        try {
          final json = jsonDecode(lines[i]);
          entries.add(AuditLogEntry.fromJson(json));
        } catch (_) {
          // 잘못된 JSON 라인은 건너뛰기
        }
      }
      
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// 실패한 작업들만 조회
  static Future<List<AuditLogEntry>> getFailedActions({int limit = 50}) async {
    final allLogs = await getRecentLogs(limit: limit * 2);
    return allLogs.where((log) => log.success == false).take(limit).toList();
  }

  /// 보안 위반 사항들만 조회
  static Future<List<AuditLogEntry>> getSecurityViolations({int limit = 50}) async {
    final allLogs = await getRecentLogs(limit: limit * 2);
    return allLogs
        .where((log) => log.eventType == AuditEventType.securityViolation)
        .take(limit)
        .toList();
  }

  /// 최근 이상 징후 탐지 항목 조회 (대시보드용)
  static Future<List<AuditLogEntry>> getRecentAnomalyDetections({
    int limit = 10,
  }) async {
    final allLogs = await getRecentLogs(limit: limit * 5);
    return allLogs
        .where((log) {
          if (log.eventType == AuditEventType.policyEnforcement) {
            return log.action.startsWith('anomaly_signal_');
          }
          return log.eventType == AuditEventType.securityViolation &&
              log.action == 'anomaly_detection_summary';
        })
        .take(limit)
        .toList();
  }
}

class AuditRealtimeSnapshot {
  final bool hasSecurityViolation;
  final int anomalyDetections;
  final int recentFailures;

  const AuditRealtimeSnapshot({
    required this.hasSecurityViolation,
    required this.anomalyDetections,
    required this.recentFailures,
  });
}

/// 감사 로그 이벤트 타입
enum AuditEventType {
  authentication('인증'),
  authorization('권한 부여'),
  dataAccess('데이터 접근'),
  dataModification('데이터 수정'),
  systemConfiguration('시스템 구성'),
  securityViolation('보안 위반'),
  policyEnforcement('정책 시행'),
  backup('백업'),
  restore('복원');

  const AuditEventType(this.displayName);
  final String displayName;
}

/// 감사 로그 엔트리
class AuditLogEntry {
  final DateTime timestamp;
  final AuditEventType eventType;
  final String action;
  final UserPermissionLevel userLevel;
  final String? userId;
  final String? targetResource;
  final Map<String, dynamic>? metadata;
  final bool? success;
  final String? errorMessage;
  final ActionRiskLevel? riskLevel;

  const AuditLogEntry({
    required this.timestamp,
    required this.eventType,
    required this.action,
    required this.userLevel,
    this.userId,
    this.targetResource,
    this.metadata,
    this.success,
    this.errorMessage,
    this.riskLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.name,
      'action': action,
      'userLevel': userLevel.name,
      'userId': userId,
      'targetResource': targetResource,
      'metadata': metadata,
      'success': success,
      'errorMessage': errorMessage,
      'riskLevel': riskLevel?.name,
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      eventType: AuditEventType.values.byName(json['eventType']),
      action: json['action'],
      userLevel: UserPermissionLevel.values.byName(json['userLevel']),
      userId: json['userId'],
      targetResource: json['targetResource'],
      metadata: json['metadata'],
      success: json['success'],
      errorMessage: json['errorMessage'],
      riskLevel: json['riskLevel'] != null 
          ? ActionRiskLevel.values.byName(json['riskLevel'])
          : null,
    );
  }

  /// 로그 레벨 (로그 시각화용)
  LogLevel get logLevel {
    if (success == false) {
      if (eventType == AuditEventType.securityViolation) {
        return LogLevel.critical;
      }
      return riskLevel?.index == ActionRiskLevel.critical.index 
          ? LogLevel.critical 
          : LogLevel.error;
    }
    
    if (riskLevel?.index == ActionRiskLevel.critical.index) {
      return LogLevel.warning;
    }
    
    return LogLevel.info;
  }

  /// 사용자 친화적 설명
  String get displaySummary {
    final result = success == true ? '성공' : 
                  success == false ? '실패' : '진행 중';
    return '${eventType.displayName}: $action ($result)';
  }
}

/// 로그 레벨 (시각화용)
enum LogLevel {
  info('INFO', Colors.blue),
  warning('WARN', Colors.orange),
  error('ERROR', Colors.red),
  critical('CRITICAL', Colors.deepPurple);

  const LogLevel(this.name, this.color);
  final String name;
  final Color color;
}

/// 감사 로그 위젯 (요약 뷰용)
class AuditLogSummaryCard extends StatelessWidget {
  final int maxItems;
  final VoidCallback? onViewAll;

  const AuditLogSummaryCard({
    super.key,
    this.maxItems = 5,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AuditLogEntry>>(
      future: AuditLogService.getRecentLogs(limit: maxItems),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final logs = snapshot.data!;
        final theme = Theme.of(context);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '최근 감사 로그',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (onViewAll != null)
                      TextButton(
                        onPressed: onViewAll,
                        child: const Text('전체 보기'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (logs.isEmpty)
                  const Text('감사 로그가 없습니다.')
                else
                  ...logs.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: log.logLevel.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.displaySummary,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          DateFormat('MM-dd HH:mm').format(log.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 실패 작업 알림 카드
class FailedActionsCard extends StatelessWidget {
  const FailedActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AuditLogEntry>>(
      future: AuditLogService.getFailedActions(limit: 3),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final failedLogs = snapshot.data!;
        final theme = Theme.of(context);

        return Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      '최근 실패 작업 (${failedLogs.length}건)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...failedLogs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${log.displaySummary}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}