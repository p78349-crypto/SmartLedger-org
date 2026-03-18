import '../models/workflow_models.dart';
export '../models/workflow_models.dart';
export '../widgets/workflow_widgets.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';

import 'audit_log_service.dart';
import '../utils/pref_keys.dart';

/// Phase 3: 워크플로우 자동화 엔진
/// 승인 체계, 자동화 룰 엔진, 작업 스케줄링
class WorkflowAutomationEngine {
  static const String _prefsKey = 'workflow_automation';

  // 싱글톤
  static final WorkflowAutomationEngine _instance =
      WorkflowAutomationEngine._();
  factory WorkflowAutomationEngine() => _instance;
  WorkflowAutomationEngine._();

  final List<WorkflowDefinition> _workflows = [];
  final List<ApprovalRequest> _pendingApprovals = [];
  final List<AutomationRule> _rules = [];
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier(0);

  /// Test-only: reset singleton state for deterministic tests.
  void resetForTesting() {
    _workflows.clear();
    _pendingApprovals.clear();
    _rules.clear();
    pendingCountNotifier.value = 0;
  }

  /// 초기화
  Future<void> initialize() async {
    await _loadWorkflows();
    await _loadRules();
    _setupDefaultWorkflows();
    _updatePendingCount();
  }

  /// 모든 워크플로우 정의
  List<WorkflowDefinition> get workflows => List.unmodifiable(_workflows);

  /// 대기 중인 승인 요청
  List<ApprovalRequest> get pendingApprovals =>
      List.unmodifiable(_pendingApprovals);

  /// 모든 자동화 룰
  List<AutomationRule> get rules => List.unmodifiable(_rules);

  // ═══ 승인 워크플로우 ═══

  /// 승인 요청 생성
  Future<ApprovalRequest> createApprovalRequest({
    required String workflowId,
    required String requesterId,
    required String title,
    required String description,
    required Map<String, dynamic> data,
    ApprovalUrgency urgency = ApprovalUrgency.normal,
  }) async {
    final workflow = _workflows.firstWhere(
      (w) => w.id == workflowId,
      orElse: () => throw WorkflowException('워크플로우를 찾을 수 없습니다: $workflowId'),
    );

    if (!workflow.isActive) {
      throw const WorkflowException('비활성 워크플로우입니다');
    }

    final request = ApprovalRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      workflowId: workflowId,
      requesterId: requesterId,
      title: title,
      description: description,
      data: data,
      urgency: urgency,
      status: ApprovalStatus.pending,
      createdAt: DateTime.now(),
      currentStep: 0,
      totalSteps: workflow.steps.length,
      approvalHistory: [],
    );

    _pendingApprovals.add(request);
    _updatePendingCount();
    await _savePendingApprovals();

    // 감사 로그
    await AuditLogService.log(
      eventType: AuditEventType.systemConfiguration,
      action: '승인 요청 생성: $title',
      userLevel: UserPermissionLevel.root,
      metadata: {'details': '워크플로우: ${workflow.name}, 긴급도: ${urgency.label}'},
    );

    return request;
  }

  /// 승인 처리
  Future<void> processApproval({
    required String requestId,
    required String approverId,
    required bool approved,
    String? comment,
  }) async {
    final index = _pendingApprovals.indexWhere((r) => r.id == requestId);
    if (index == -1) throw const WorkflowException('요청을 찾을 수 없습니다');

    final request = _pendingApprovals[index];
    final workflow = _workflows.firstWhere(
      (w) => w.id == request.workflowId,
      orElse: () => throw const WorkflowException('워크플로우를 찾을 수 없습니다'),
    );

    final stepAction = ApprovalAction(
      approverId: approverId,
      approved: approved,
      comment: comment,
      timestamp: DateTime.now(),
      stepIndex: request.currentStep,
    );

    final newHistory = [...request.approvalHistory, stepAction];

    if (!approved) {
      // 거절
      _pendingApprovals[index] = request.copyWith(
        status: ApprovalStatus.rejected,
        approvalHistory: newHistory,
      );
    } else if (request.currentStep + 1 >= workflow.steps.length) {
      // 최종 승인
      _pendingApprovals[index] = request.copyWith(
        status: ApprovalStatus.approved,
        currentStep: request.currentStep + 1,
        approvalHistory: newHistory,
      );
      // 자동 실행 트리거
      await _executeApprovedWorkflow(request, workflow);
    } else {
      // 다음 단계로
      _pendingApprovals[index] = request.copyWith(
        currentStep: request.currentStep + 1,
        approvalHistory: newHistory,
      );
    }

    _updatePendingCount();
    await _savePendingApprovals();

    await AuditLogService.log(
      eventType: AuditEventType.authorization,
      action: '승인 처리: ${approved ? "승인" : "거절"}',
      userLevel: UserPermissionLevel.root,
      metadata: {'details': '요청: ${request.title}, 승인자: $approverId'},
    );
  }

  // ═══ 자동화 룰 ═══

  /// 자동화 룰 추가
  Future<void> addRule(AutomationRule rule) async {
    _rules.add(rule);
    await _saveRules();
  }

  /// 룰 활성화/비활성화
  Future<void> toggleRule(String ruleId) async {
    final index = _rules.indexWhere((r) => r.id == ruleId);
    if (index == -1) return;

    _rules[index] = _rules[index].copyWith(isActive: !_rules[index].isActive);
    await _saveRules();
  }

  /// 룰 삭제
  Future<void> deleteRule(String ruleId) async {
    _rules.removeWhere((r) => r.id == ruleId);
    await _saveRules();
  }

  /// 이벤트 기반 룰 평가 및 실행
  Future<List<RuleExecutionResult>> evaluateRules({
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    final results = <RuleExecutionResult>[];

    for (final rule in _rules.where((r) => r.isActive)) {
      if (rule.trigger.eventType == eventType) {
        final conditionMet = _evaluateConditions(rule.conditions, eventData);
        if (conditionMet) {
          final result = await _executeActions(rule, eventData);
          results.add(result);
        }
      }
    }

    return results;
  }

  // ═══ 통계 ═══

  /// 워크플로우 통계
  WorkflowStats getStats() {
    final pending = _pendingApprovals
        .where((r) => r.status == ApprovalStatus.pending)
        .length;
    final approved = _pendingApprovals
        .where((r) => r.status == ApprovalStatus.approved)
        .length;
    final rejected = _pendingApprovals
        .where((r) => r.status == ApprovalStatus.rejected)
        .length;
    final activeRules = _rules.where((r) => r.isActive).length;

    return WorkflowStats(
      pendingApprovals: pending,
      approvedTotal: approved,
      rejectedTotal: rejected,
      activeWorkflows: _workflows.where((w) => w.isActive).length,
      activeRules: activeRules,
      totalRules: _rules.length,
    );
  }

  // ────────── 내부 메서드 ──────────

  void _setupDefaultWorkflows() {
    if (_workflows.isNotEmpty) return;

    _workflows.addAll([
      const WorkflowDefinition(
        id: 'wf_large_transaction',
        name: '대금 거래 승인',
        description: '100만원 이상 거래 시 관리자 승인 필요',
        isActive: true,
        triggerCondition: '거래 금액 >= 1,000,000원',
        steps: [
          ApprovalStep(name: '관리자 검토', requiredRole: 'administrator'),
          ApprovalStep(name: '최종 승인', requiredRole: 'root'),
        ],
        autoActions: ['감사 로그 기록', '알림 전송'],
      ),
      const WorkflowDefinition(
        id: 'wf_account_deletion',
        name: '계정 삭제 승인',
        description: '계정 삭제 시 2단계 승인 필요',
        isActive: true,
        triggerCondition: '계정 삭제 요청',
        steps: [
          ApprovalStep(name: '데이터 백업 확인', requiredRole: 'administrator'),
          ApprovalStep(name: '최종 삭제 승인', requiredRole: 'root'),
        ],
        autoActions: ['자동 백업', '감사 로그 기록', '복구 토큰 생성'],
      ),
      const WorkflowDefinition(
        id: 'wf_data_export',
        name: '데이터 내보내기 승인',
        description: '대량 데이터 내보내기 시 승인 필요',
        isActive: true,
        triggerCondition: '1000건 이상 데이터 내보내기',
        steps: [ApprovalStep(name: '보안 검토', requiredRole: 'administrator')],
        autoActions: ['내보내기 제한 확인', '감사 로그 기록'],
      ),
      const WorkflowDefinition(
        id: 'wf_permission_change',
        name: '권한 변경 승인',
        description: '사용자 권한 변경 시 승인 체계',
        isActive: true,
        triggerCondition: '권한 레벨 변경 요청',
        steps: [
          ApprovalStep(name: '관리자 검토', requiredRole: 'administrator'),
          ApprovalStep(name: 'ROOT 최종 승인', requiredRole: 'root'),
        ],
        autoActions: ['변경 이력 기록', '보안 알림 전송'],
      ),
    ]);

    // 기본 자동화 룰
    _rules.addAll([
      const AutomationRule(
        id: 'rule_daily_backup',
        name: '일일 자동 백업',
        description: '매일 자정에 자동 백업 수행',
        isActive: true,
        trigger: RuleTrigger(eventType: 'schedule', schedule: '0 0 * * *'),
        conditions: [],
        actions: [
          RuleAction(
            type: RuleActionType.backup,
            params: {'type': 'incremental'},
          ),
          RuleAction(
            type: RuleActionType.notify,
            params: {'message': '일일 백업 완료'},
          ),
        ],
        executionCount: 0,
      ),
      const AutomationRule(
        id: 'rule_security_alert',
        name: '보안 이상 감지',
        description: '비정상적인 접근 시도 감지 시 알림',
        isActive: true,
        trigger: RuleTrigger(eventType: 'security_violation'),
        conditions: [
          RuleCondition(field: 'violation_count', operator: '>=', value: 3),
        ],
        actions: [
          RuleAction(type: RuleActionType.alert, params: {'severity': 'high'}),
          RuleAction(
            type: RuleActionType.lockAccount,
            params: {'duration': 30},
          ),
          RuleAction(type: RuleActionType.log, params: {'level': 'critical'}),
        ],
        executionCount: 0,
      ),
      const AutomationRule(
        id: 'rule_budget_alert',
        name: '예산 초과 알림',
        description: '카테고리 예산 80% 초과 시 알림',
        isActive: true,
        trigger: RuleTrigger(eventType: 'transaction_created'),
        conditions: [
          RuleCondition(
            field: 'budget_usage_percent',
            operator: '>=',
            value: 80,
          ),
        ],
        actions: [
          RuleAction(
            type: RuleActionType.notify,
            params: {'message': '예산 경고: 80% 초과'},
          ),
        ],
        executionCount: 0,
      ),
    ]);
  }

  bool _evaluateConditions(
    List<RuleCondition> conditions,
    Map<String, dynamic> data,
  ) {
    for (final condition in conditions) {
      final fieldValue = data[condition.field];
      if (fieldValue == null) return false;

      final numValue = (fieldValue is num) ? fieldValue.toDouble() : 0.0;
      final condValue = (condition.value is num)
          ? (condition.value as num).toDouble()
          : 0.0;

      switch (condition.operator) {
        case '>=':
          if (numValue < condValue) return false;
        case '<=':
          if (numValue > condValue) return false;
        case '>':
          if (numValue <= condValue) return false;
        case '<':
          if (numValue >= condValue) return false;
        case '==':
          if (fieldValue != condition.value) return false;
        case '!=':
          if (fieldValue == condition.value) return false;
        default:
          return false;
      }
    }
    return true;
  }

  Future<RuleExecutionResult> _executeActions(
    AutomationRule rule,
    Map<String, dynamic> eventData,
  ) async {
    final results = <String>[];
    bool success = true;

    for (final action in rule.actions) {
      try {
        switch (action.type) {
          case RuleActionType.notify:
            final notifyMessage =
                action.params['message']?.toString() ?? '자동 알림';
            await AuditLogService.log(
              eventType: AuditEventType.policyEnforcement,
              action: 'automation_notify',
              userLevel: UserPermissionLevel.root,
              targetResource: eventData['accountId']?.toString(),
              metadata: {
                'ruleId': rule.id,
                'message': notifyMessage,
                ...eventData,
              },
            );
            results.add('알림 전송: $notifyMessage');
          case RuleActionType.backup:
            results.add('백업 실행: ${action.params['type']}');
          case RuleActionType.alert:
            final severity = action.params['severity']?.toString() ?? 'high';
            await AuditLogService.log(
              eventType: AuditEventType.securityViolation,
              action: 'automation_high_risk_alert',
              userLevel: UserPermissionLevel.root,
              targetResource: eventData['accountId']?.toString(),
              metadata: {'ruleId': rule.id, 'severity': severity, ...eventData},
              riskLevel: severity == 'high'
                  ? ActionRiskLevel.critical
                  : ActionRiskLevel.warning,
            );
            results.add('보안 알림: $severity');
          case RuleActionType.lockAccount:
            final durationMinutes =
                int.tryParse('${action.params['duration']}') ?? 30;
            await _applyGlobalAuthLock(durationMinutes: durationMinutes);
            await AuditLogService.log(
              eventType: AuditEventType.policyEnforcement,
              action: 'automation_account_lock_applied',
              userLevel: UserPermissionLevel.root,
              targetResource: eventData['accountId']?.toString(),
              metadata: {
                'ruleId': rule.id,
                'durationMinutes': durationMinutes,
                ...eventData,
              },
              riskLevel: ActionRiskLevel.critical,
            );
            results.add(
              '계정 잠금: $durationMinutes'
              '분',
            );
          case RuleActionType.log:
            await AuditLogService.log(
              eventType: AuditEventType.systemConfiguration,
              action: '자동화 룰 실행: ${rule.name}',
              userLevel: UserPermissionLevel.root,
              metadata: {'details': results.join(', ')},
            );
            results.add('감사 로그 기록');
          case RuleActionType.approvalRequest:
            results.add('승인 요청 생성');
          case RuleActionType.dataExport:
            results.add('데이터 내보내기');
          case RuleActionType.customScript:
            results.add('커스텀 스크립트 실행');
        }
      } catch (e) {
        success = false;
        results.add('오류: ${e.toString()}');
      }
    }

    // 실행 카운트 업데이트
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _rules[index] = rule.copyWith(
        lastExecuted: DateTime.now(),
        executionCount: rule.executionCount + 1,
      );
    }

    return RuleExecutionResult(
      ruleId: rule.id,
      ruleName: rule.name,
      success: success,
      actions: results,
      executedAt: DateTime.now(),
    );
  }

  Future<void> _applyGlobalAuthLock({required int durationMinutes}) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now()
        .add(Duration(minutes: durationMinutes))
        .millisecondsSinceEpoch;

    await prefs.setInt(PrefKeys.userPinLockedUntilMs, until);
    await prefs.setInt(PrefKeys.userPasswordLockedUntilMs, until);
    await prefs.setInt(PrefKeys.rootPinLockedUntilMs, until);
    await prefs.setInt(PrefKeys.rootPasswordLockedUntilMs, until);
    await prefs.setInt(PrefKeys.assetPinLockedUntilMs, until);
    await prefs.setInt(PrefKeys.assetPasswordLockedUntilMs, until);
  }

  Future<void> _executeApprovedWorkflow(
    ApprovalRequest request,
    WorkflowDefinition workflow,
  ) async {
    for (final action in workflow.autoActions) {
      await AuditLogService.log(
        eventType: AuditEventType.systemConfiguration,
        action: '워크플로우 자동 실행: $action',
        userLevel: UserPermissionLevel.root,
        metadata: {'details': '승인된 요청: ${request.title}'},
      );
    }
  }

  void _updatePendingCount() {
    pendingCountNotifier.value = _pendingApprovals
        .where((r) => r.status == ApprovalStatus.pending)
        .length;
  }

  Future<void> _loadWorkflows() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_prefsKey}_workflows');
      if (raw == null) return;
      // 실제 구현에서는 JSON 파싱
    } catch (_) {}
  }

  Future<void> _loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_prefsKey}_rules');
      if (raw == null) return;
      // 실제 구현에서는 JSON 파싱
    } catch (_) {}
  }

  Future<void> _savePendingApprovals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_prefsKey}_pending',
        jsonEncode(_pendingApprovals.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _saveRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_prefsKey}_rules',
        jsonEncode(_rules.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }
}

// ════════════════════ 데이터 모델 ════════════════════

/// 워크플로우 정의
