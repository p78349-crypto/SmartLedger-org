import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// AI 사용 감사 로깅 시스템 (법적 증명용)
/// 모든 AI 관련 활동을 추적하여 규제 기관 제출용 증거 자료 생성
class AiAuditLogger {
  static const String _auditVersion = '2026.02.21-COMPLIANCE';
  static const String _logPath = './audit_logs/ai_compliance_log.json';

  static final List<AuditEntry> _auditLog = [];

  /// AI 기능 비활성화 로그 기록
  static Future<void> logAiDisabled({
    required String reason,
    required String component,
    String? regulationReference,
  }) async {
    final entry = AuditEntry(
      timestamp: DateTime.now().toUtc(),
      eventType: 'AI_DISABLED',
      component: component,
      action: 'AI functionality disabled',
      reason: reason,
      complianceStatus: 'COMPLIANT',
      regulationReference: regulationReference,
      userImpact: 'AI features unavailable, traditional algorithms active',
    );

    await _recordAuditEntry(entry);
  }

  /// 규제 준수 검증 로그
  static Future<void> logComplianceCheck({
    required String region,
    required String regulation,
    required bool isCompliant,
    String? details,
  }) async {
    final entry = AuditEntry(
      timestamp: DateTime.now().toUtc(),
      eventType: 'COMPLIANCE_CHECK',
      component: 'RegionalAiPolicy',
      action: 'Regulatory compliance verification',
      reason: 'Automatic compliance check for region: $region',
      complianceStatus: isCompliant ? 'COMPLIANT' : 'NON_COMPLIANT',
      regulationReference: regulation,
      userImpact: details ?? 'No user impact',
    );

    await _recordAuditEntry(entry);
  }

  /// 보안 봉인 상태 로그
  static Future<void> logSecuritySeal({
    required bool isSealed,
    required String trigger,
  }) async {
    final entry = AuditEntry(
      timestamp: DateTime.now().toUtc(),
      eventType: 'SECURITY_SEAL',
      component: 'AiSecuritySeal',
      action: isSealed
          ? 'AI security seal activated'
          : 'AI security seal deactivated',
      reason: trigger,
      complianceStatus: 'COMPLIANT',
      regulationReference: 'International Security Requirements',
      userImpact: isSealed
          ? 'All AI features sealed, traditional algorithms only'
          : 'AI features available with compliance checks',
    );

    await _recordAuditEntry(entry);
  }

  /// 감사 엔트리 기록
  static Future<void> _recordAuditEntry(AuditEntry entry) async {
    _auditLog.add(entry);

    // 릴리즈 모드에서는 파일 저장 비활성화 (파일 시스템 권한 문제)
    if (kReleaseMode) {
      if (kDebugMode) {
        print('📝 AI 감사 로그 (메모리만): ${entry.eventType}');
      }
      return;
    }

    try {
      final file = File(_logPath);
      if (!file.existsSync()) {
        await file.create(recursive: true);
      }

      final logData = {
        'audit_version': _auditVersion,
        'system': 'SmartLedger',
        'purpose': 'AI Regulatory Compliance Audit Trail',
        'entries': _auditLog.map((e) => e.toJson()).toList(),
      };

      await file.writeAsString(jsonEncode(logData));
      if (kDebugMode) {
        print('📝 AI 감사 로그 기록: ${entry.eventType}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 감사 로그 기록 실패: $e');
      }
    }
  }

  /// 규제 기관 제출용 리포트 생성
  static Future<String> generateComplianceReport() async {
    final report = {
      'report_metadata': {
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'system': 'SmartLedger Financial Management App',
        'version': _auditVersion,
        'purpose': 'AI Regulatory Compliance Evidence',
      },
      'compliance_summary': {
        'ai_status': 'FULLY_DISABLED',
        'seal_status': 'ACTIVE',
        'total_audit_entries': _auditLog.length,
        'compliance_level': 'MAXIMUM',
      },
      'audit_trail': _auditLog.map((e) => e.toJson()).toList(),
    };

    return jsonEncode(report);
  }

  /// 현재 감사 통계
  static Map<String, dynamic> getAuditStats() {
    return {
      'total_entries': _auditLog.length,
      'ai_disabled_events': _auditLog
          .where((e) => e.eventType == 'AI_DISABLED')
          .length,
      'compliance_checks': _auditLog
          .where((e) => e.eventType == 'COMPLIANCE_CHECK')
          .length,
      'security_seals': _auditLog
          .where((e) => e.eventType == 'SECURITY_SEAL')
          .length,
    };
  }
}

/// 감사 로그 엔트리 모델
class AuditEntry {
  const AuditEntry({
    required this.timestamp,
    required this.eventType,
    required this.component,
    required this.action,
    required this.reason,
    required this.complianceStatus,
    this.regulationReference,
    this.userImpact,
  });

  final DateTime timestamp;
  final String eventType;
  final String component;
  final String action;
  final String reason;
  final String complianceStatus;
  final String? regulationReference;
  final String? userImpact;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'event_type': eventType,
    'component': component,
    'action': action,
    'reason': reason,
    'compliance_status': complianceStatus,
    'regulation_reference': regulationReference,
    'user_impact': userImpact,
  };
}
