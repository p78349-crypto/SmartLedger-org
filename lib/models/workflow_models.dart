import 'package:flutter/material.dart';

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

  Map<String, dynamic> toJson() => {'type': type.name, 'params': params};
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
