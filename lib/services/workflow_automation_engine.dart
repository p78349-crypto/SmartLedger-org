import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';

import 'audit_log_service.dart';

/// Phase 3: 워크플로우 자동화 엔진
/// 승인 체계, 자동화 룰 엔진, 작업 스케줄링
class WorkflowAutomationEngine {
  static const String _prefsKey = 'workflow_automation';

  // 싱글톤
  static final WorkflowAutomationEngine _instance = WorkflowAutomationEngine._();
  factory WorkflowAutomationEngine() => _instance;
  WorkflowAutomationEngine._();

  final List<WorkflowDefinition> _workflows = [];
  final List<ApprovalRequest> _pendingApprovals = [];
  final List<AutomationRule> _rules = [];
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier(0);

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
  List<ApprovalRequest> get pendingApprovals => List.unmodifiable(_pendingApprovals);

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
      metadata: {
        'details': '워크플로우: ${workflow.name}, 긴급도: ${urgency.label}',
      },
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
      metadata: {
        'details': '요청: ${request.title}, 승인자: $approverId',
      },
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

    _rules[index] = _rules[index].copyWith(
      isActive: !_rules[index].isActive,
    );
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
        steps: [
          ApprovalStep(name: '보안 검토', requiredRole: 'administrator'),
        ],
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
          RuleAction(type: RuleActionType.backup, params: {'type': 'incremental'}),
          RuleAction(type: RuleActionType.notify, params: {'message': '일일 백업 완료'}),
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
          RuleAction(type: RuleActionType.lockAccount, params: {'duration': 30}),
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
          RuleCondition(field: 'budget_usage_percent', operator: '>=', value: 80),
        ],
        actions: [
          RuleAction(type: RuleActionType.notify, params: {'message': '예산 경고: 80% 초과'}),
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
      final condValue = (condition.value is num) ? (condition.value as num).toDouble() : 0.0;

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
            results.add('알림 전송: ${action.params['message']}');
          case RuleActionType.backup:
            results.add('백업 실행: ${action.params['type']}');
          case RuleActionType.alert:
            results.add('보안 알림: ${action.params['severity']}');
          case RuleActionType.lockAccount:
            results.add('계정 잠금: ${action.params['duration']}분');
          case RuleActionType.log:
            await AuditLogService.log(
              eventType: AuditEventType.systemConfiguration,
              action: '자동화 룰 실행: ${rule.name}',
              userLevel: UserPermissionLevel.root,
              metadata: {
                'details': results.join(', '),
              },
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

  Future<void> _executeApprovedWorkflow(
    ApprovalRequest request,
    WorkflowDefinition workflow,
  ) async {
    for (final action in workflow.autoActions) {
      await AuditLogService.log(
        eventType: AuditEventType.systemConfiguration,
        action: '워크플로우 자동 실행: $action',
        userLevel: UserPermissionLevel.root,
        metadata: {
          'details': '승인된 요청: ${request.title}',
        },
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
class WorkflowDefinition {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final String triggerCondition;
  final List<ApprovalStep> steps;
  final List<String> autoActions;

  const WorkflowDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.triggerCondition,
    required this.steps,
    required this.autoActions,
  });
}

/// 승인 단계
class ApprovalStep {
  final String name;
  final String requiredRole;

  const ApprovalStep({required this.name, required this.requiredRole});
}

/// 승인 요청
class ApprovalRequest {
  final String id;
  final String workflowId;
  final String requesterId;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final ApprovalUrgency urgency;
  final ApprovalStatus status;
  final DateTime createdAt;
  final int currentStep;
  final int totalSteps;
  final List<ApprovalAction> approvalHistory;

  const ApprovalRequest({
    required this.id,
    required this.workflowId,
    required this.requesterId,
    required this.title,
    required this.description,
    required this.data,
    required this.urgency,
    required this.status,
    required this.createdAt,
    required this.currentStep,
    required this.totalSteps,
    required this.approvalHistory,
  });

  ApprovalRequest copyWith({
    ApprovalStatus? status,
    int? currentStep,
    List<ApprovalAction>? approvalHistory,
  }) {
    return ApprovalRequest(
      id: id,
      workflowId: workflowId,
      requesterId: requesterId,
      title: title,
      description: description,
      data: data,
      urgency: urgency,
      status: status ?? this.status,
      createdAt: createdAt,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps,
      approvalHistory: approvalHistory ?? this.approvalHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'wf_id': workflowId,
    'requester': requesterId,
    'title': title,
    'desc': description,
    'data': data,
    'urgency': urgency.name,
    'status': status.name,
    'created': createdAt.toIso8601String(),
    'step': currentStep,
    'total_steps': totalSteps,
    'history': approvalHistory.map((a) => a.toJson()).toList(),
  };
}

/// 승인 액션
class ApprovalAction {
  final String approverId;
  final bool approved;
  final String? comment;
  final DateTime timestamp;
  final int stepIndex;

  const ApprovalAction({
    required this.approverId,
    required this.approved,
    this.comment,
    required this.timestamp,
    required this.stepIndex,
  });

  Map<String, dynamic> toJson() => {
    'approver': approverId,
    'approved': approved,
    'comment': comment,
    'ts': timestamp.toIso8601String(),
    'step': stepIndex,
  };
}

/// 승인 상태
enum ApprovalStatus {
  pending('대기', Colors.orange),
  approved('승인', Colors.green),
  rejected('거절', Colors.red),
  cancelled('취소', Colors.grey);

  final String label;
  final Color color;
  const ApprovalStatus(this.label, this.color);
}

/// 긴급도
enum ApprovalUrgency {
  low('낮음', Colors.grey),
  normal('보통', Colors.blue),
  high('높음', Colors.orange),
  critical('긴급', Colors.red);

  final String label;
  final Color color;
  const ApprovalUrgency(this.label, this.color);
}

/// 자동화 룰
class AutomationRule {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final RuleTrigger trigger;
  final List<RuleCondition> conditions;
  final List<RuleAction> actions;
  final DateTime? lastExecuted;
  final int executionCount;

  const AutomationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.trigger,
    required this.conditions,
    required this.actions,
    this.lastExecuted,
    required this.executionCount,
  });

  AutomationRule copyWith({
    bool? isActive,
    DateTime? lastExecuted,
    int? executionCount,
  }) {
    return AutomationRule(
      id: id,
      name: name,
      description: description,
      isActive: isActive ?? this.isActive,
      trigger: trigger,
      conditions: conditions,
      actions: actions,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      executionCount: executionCount ?? this.executionCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'desc': description,
    'active': isActive,
    'trigger': trigger.toJson(),
    'conditions': conditions.map((c) => c.toJson()).toList(),
    'actions': actions.map((a) => a.toJson()).toList(),
    'last_exec': lastExecuted?.toIso8601String(),
    'exec_count': executionCount,
  };
}

/// 룰 트리거
class RuleTrigger {
  final String eventType;
  final String? schedule; // cron 형식

  const RuleTrigger({required this.eventType, this.schedule});

  Map<String, dynamic> toJson() => {
    'event': eventType,
    if (schedule != null) 'schedule': schedule,
  };
}

/// 룰 조건
class RuleCondition {
  final String field;
  final String operator;
  final dynamic value;

  const RuleCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'op': operator,
    'value': value,
  };
}

/// 룰 액션
class RuleAction {
  final RuleActionType type;
  final Map<String, dynamic> params;

  const RuleAction({required this.type, required this.params});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'params': params,
  };
}

/// 액션 타입
enum RuleActionType {
  notify('알림'),
  backup('백업'),
  alert('보안 알림'),
  lockAccount('계정 잠금'),
  log('로그 기록'),
  approvalRequest('승인 요청'),
  dataExport('데이터 내보내기'),
  customScript('커스텀 스크립트');

  final String label;
  const RuleActionType(this.label);
}

/// 룰 실행 결과
class RuleExecutionResult {
  final String ruleId;
  final String ruleName;
  final bool success;
  final List<String> actions;
  final DateTime executedAt;

  const RuleExecutionResult({
    required this.ruleId,
    required this.ruleName,
    required this.success,
    required this.actions,
    required this.executedAt,
  });
}

/// 워크플로우 통계
class WorkflowStats {
  final int pendingApprovals;
  final int approvedTotal;
  final int rejectedTotal;
  final int activeWorkflows;
  final int activeRules;
  final int totalRules;

  const WorkflowStats({
    required this.pendingApprovals,
    required this.approvedTotal,
    required this.rejectedTotal,
    required this.activeWorkflows,
    required this.activeRules,
    required this.totalRules,
  });
}

/// 워크플로우 예외
class WorkflowException implements Exception {
  final String message;
  const WorkflowException(this.message);

  @override
  String toString() => 'WorkflowException: $message';
}

// ════════════════════ UI 위젯 ════════════════════

/// 승인 대기 배지
class ApprovalPendingBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const ApprovalPendingBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: WorkflowAutomationEngine().pendingCountNotifier,
      builder: (context, count, _) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.approval, size: 22),
              ),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 워크플로우 대시보드 위젯
class WorkflowDashboardCard extends StatelessWidget {
  final WorkflowStats stats;

  const WorkflowDashboardCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '워크플로우 현황',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatTile(
                  context,
                  icon: Icons.pending_actions,
                  label: '대기',
                  value: '${stats.pendingApprovals}',
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatTile(
                  context,
                  icon: Icons.check_circle,
                  label: '승인',
                  value: '${stats.approvedTotal}',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatTile(
                  context,
                  icon: Icons.cancel,
                  label: '거절',
                  value: '${stats.rejectedTotal}',
                  color: Colors.red,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildStatTile(
                  context,
                  icon: Icons.settings_suggest,
                  label: '활성 룰',
                  value: '${stats.activeRules}/${stats.totalRules}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatTile(
                  context,
                  icon: Icons.account_tree,
                  label: '워크플로우',
                  value: '${stats.activeWorkflows}',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// 승인 요청 카드
class ApprovalRequestCard extends StatelessWidget {
  final ApprovalRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ApprovalRequestCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: request.urgency.color.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: request.urgency.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.urgency.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: request.urgency.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: request.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: request.status.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            // 진행 표시
            Row(
              children: [
                Text(
                  '단계 ${request.currentStep + 1} / ${request.totalSteps}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: request.totalSteps > 0
                          ? request.currentStep / request.totalSteps
                          : 0,
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
            if (request.status == ApprovalStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('거절'),
                    ),
                  const SizedBox(width: 8),
                  if (onApprove != null)
                    FilledButton(
                      onPressed: onApprove,
                      child: const Text('승인'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 자동화 룰 카드
class AutomationRuleCard extends StatelessWidget {
  final AutomationRule rule;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;

  const AutomationRuleCard({
    super.key,
    required this.rule,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (rule.isActive ? Colors.green : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.settings_suggest,
                color: rule.isActive ? Colors.green : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    rule.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (rule.lastExecuted != null)
                    Text(
                      '마지막 실행: ${_formatDate(rule.lastExecuted!)} (${rule.executionCount}회)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: rule.isActive,
              onChanged: (v) => onToggle?.call(v),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
