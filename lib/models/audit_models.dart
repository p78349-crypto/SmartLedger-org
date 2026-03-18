import 'package:smart_ledger/widgets/user_permission_badge.dart';
import 'package:flutter/material.dart';

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
    final result = success == true
        ? '성공'
        : success == false
        ? '실패'
        : '진행 중';
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
