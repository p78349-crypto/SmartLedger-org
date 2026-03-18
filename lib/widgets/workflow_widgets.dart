import 'package:flutter/material.dart';
import '../services/workflow_automation_engine.dart';

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
            Text(label, style: Theme.of(context).textTheme.labelSmall),
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
        side: BorderSide(color: request.urgency.color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: request.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.label,
                    style: TextStyle(fontSize: 11, color: request.status.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
                    FilledButton(onPressed: onApprove, child: const Text('승인')),
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
                color: (rule.isActive ? Colors.green : Colors.grey).withValues(
                  alpha: 0.1,
                ),
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
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ),
            Switch(value: rule.isActive, onChanged: (v) => onToggle?.call(v)),
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
