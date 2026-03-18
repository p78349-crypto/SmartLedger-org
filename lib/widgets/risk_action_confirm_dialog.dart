import 'package:flutter/material.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';

/// 위험한 작업 수행 전 2단계 확인 다이얼로그
/// Phase 1 개선: 위험 작업 경고 강화
class RiskActionConfirmDialog extends StatefulWidget {
  final String actionTitle;
  final String actionDescription;
  final ActionRiskLevel riskLevel;
  final UserPermissionLevel currentUserLevel;
  final String? impactDescription;
  final List<String>? affectedSystems;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const RiskActionConfirmDialog({
    super.key,
    required this.actionTitle,
    required this.actionDescription,
    required this.riskLevel,
    required this.currentUserLevel,
    this.impactDescription,
    this.affectedSystems,
    this.onConfirm,
    this.onCancel,
  });

  /// 편의 메서드: 간단한 확인 다이얼로그 표시
  static Future<bool> show({
    required BuildContext context,
    required String actionTitle,
    required String actionDescription,
    ActionRiskLevel riskLevel = ActionRiskLevel.warning,
    String? impactDescription,
    List<String>? affectedSystems,
  }) async {
    final currentLevel = PermissionUtils.getCurrentUserLevel();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RiskActionConfirmDialog(
        actionTitle: actionTitle,
        actionDescription: actionDescription,
        riskLevel: riskLevel,
        currentUserLevel: currentLevel,
        impactDescription: impactDescription,
        affectedSystems: affectedSystems,
      ),
    );

    return result ?? false;
  }

  @override
  State<RiskActionConfirmDialog> createState() =>
      _RiskActionConfirmDialogState();
}

class _RiskActionConfirmDialogState extends State<RiskActionConfirmDialog> {
  bool _firstConfirmation = false;
  bool _secondConfirmation = false;
  bool _understandRisk = false;

  bool get _canProceed {
    // 권한 확인
    if (!widget.currentUserLevel.canPerformAction(widget.riskLevel)) {
      return false;
    }

    // 위험도에 따른 확인 단계
    switch (widget.riskLevel) {
      case ActionRiskLevel.safe:
        return true;
      case ActionRiskLevel.warning:
        return _firstConfirmation;
      case ActionRiskLevel.danger:
        return _firstConfirmation && _secondConfirmation;
      case ActionRiskLevel.critical:
        return _firstConfirmation && _secondConfirmation && _understandRisk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 권한 부족 시
    if (!widget.currentUserLevel.canPerformAction(widget.riskLevel)) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('권한 부족'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이 작업을 수행할 권한이 없습니다.'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('필요 권한: '),
                _buildRiskBadge(widget.riskLevel),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('현재 권한: '),
                UserPermissionBadge(
                  level: widget.currentUserLevel,
                  showLabel: true,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('확인'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          _buildRiskIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.actionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildRiskBadge(widget.riskLevel),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작업 설명
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.actionDescription,
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // 영향받는 시스템
            if (widget.affectedSystems?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                '영향받는 시스템/사용자:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.affectedSystems!.map(
                (system) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: widget.riskLevel.color,
                      ),
                      const SizedBox(width: 8),
                      Text(system),
                    ],
                  ),
                ),
              ),
            ],

            // 영향 설명
            if (widget.impactDescription?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.riskLevel.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.riskLevel.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: widget.riskLevel.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '예상 영향:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.riskLevel.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.impactDescription!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],

            // 확인 체크박스들
            const SizedBox(height: 20),
            _buildConfirmationChecks(theme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel?.call();
            Navigator.pop(context, false);
          },
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _canProceed
              ? () {
                  widget.onConfirm?.call();
                  Navigator.pop(context, true);
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: widget.riskLevel.color,
          ),
          child: const Text('실행'),
        ),
      ],
    );
  }

  Widget _buildRiskIcon() {
    switch (widget.riskLevel) {
      case ActionRiskLevel.safe:
        return Icon(Icons.check_circle, color: widget.riskLevel.color);
      case ActionRiskLevel.warning:
        return Icon(Icons.warning_amber, color: widget.riskLevel.color);
      case ActionRiskLevel.danger:
        return Icon(Icons.error, color: widget.riskLevel.color);
      case ActionRiskLevel.critical:
        return Icon(Icons.dangerous, color: widget.riskLevel.color);
    }
  }

  Widget _buildRiskBadge(ActionRiskLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        level.displayName,
        style: TextStyle(
          color: level.color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildConfirmationChecks(ThemeData theme) {
    return Column(
      children: [
        // 첫 번째 확인 (주의 이상)
        if (widget.riskLevel.index >= ActionRiskLevel.warning.index)
          CheckboxListTile(
            title: const Text('이 작업의 내용과 영향을 이해했습니다'),
            value: _firstConfirmation,
            onChanged: (value) =>
                setState(() => _firstConfirmation = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),

        // 두 번째 확인 (위험 이상)
        if (widget.riskLevel.index >= ActionRiskLevel.danger.index)
          CheckboxListTile(
            title: const Text('되돌릴 수 없는 작업임을 확인합니다'),
            value: _secondConfirmation,
            onChanged: _firstConfirmation
                ? (value) =>
                      setState(() => _secondConfirmation = value ?? false)
                : null,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),

        // 세 번째 확인 (치명적)
        if (widget.riskLevel == ActionRiskLevel.critical)
          CheckboxListTile(
            title: Text(
              '시스템 전체에 치명적 영향을 줄 수 있음을 이해합니다',
              style: TextStyle(
                color: widget.riskLevel.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            value: _understandRisk,
            onChanged: _secondConfirmation
                ? (value) => setState(() => _understandRisk = value ?? false)
                : null,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
      ],
    );
  }
}

/// 위험 작업 래퍼 유틸리티
class RiskActionWrapper {
  /// 위험한 작업을 안전하게 실행
  static Future<T?> executeWithConfirmation<T>({
    required BuildContext context,
    required String actionTitle,
    required String actionDescription,
    required Future<T> Function() action,
    ActionRiskLevel riskLevel = ActionRiskLevel.warning,
    String? impactDescription,
    List<String>? affectedSystems,
    Function(Object error)? onError,
  }) async {
    // 확인 다이얼로그 표시
    final confirmed = await RiskActionConfirmDialog.show(
      context: context,
      actionTitle: actionTitle,
      actionDescription: actionDescription,
      riskLevel: riskLevel,
      impactDescription: impactDescription,
      affectedSystems: affectedSystems,
    );

    if (!confirmed) return null;

    try {
      // 실제 작업 실행
      return await action();
    } catch (error) {
      onError?.call(error);
      rethrow;
    }
  }
}
