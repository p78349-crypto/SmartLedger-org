import 'package:flutter/material.dart';

/// 사용자 권한 레벨을 시각적으로 표시하는 배지 위젯
/// Phase 1 개선: 권한 시각화 강화
class UserPermissionBadge extends StatelessWidget {
  final UserPermissionLevel level;
  final VoidCallback? onTap;
  final bool showLabel;

  const UserPermissionBadge({
    super.key,
    required this.level,
    this.onTap,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getPermissionConfig(level, theme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              size: 16,
              color: config.iconColor,
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                config.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: config.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _PermissionConfig _getPermissionConfig(UserPermissionLevel level, ThemeData theme) {
    switch (level) {
      case UserPermissionLevel.observer:
        return _PermissionConfig(
          label: '관찰자',
          icon: Icons.visibility,
          backgroundColor: theme.colorScheme.surface,
          borderColor: theme.colorScheme.outline,
          iconColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.onSurface,
        );
      case UserPermissionLevel.operator:
        return _PermissionConfig(
          label: '운영자',
          icon: Icons.engineering,
          backgroundColor: theme.colorScheme.primaryContainer,
          borderColor: theme.colorScheme.primary,
          iconColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.onPrimaryContainer,
        );
      case UserPermissionLevel.administrator:
        return _PermissionConfig(
          label: '관리자',
          icon: Icons.admin_panel_settings,
          backgroundColor: theme.colorScheme.errorContainer,
          borderColor: theme.colorScheme.error,
          iconColor: theme.colorScheme.error,
          textColor: theme.colorScheme.onErrorContainer,
        );
      case UserPermissionLevel.root:
        return _PermissionConfig(
          label: 'ROOT',
          icon: Icons.security,
          backgroundColor: Colors.amber.shade100,
          borderColor: Colors.amber.shade600,
          iconColor: Colors.amber.shade800,
          textColor: Colors.amber.shade900,
        );
    }
  }
}

/// 사용자 권한 레벨 열거형
enum UserPermissionLevel {
  observer('관찰자', 1),
  operator('운영자', 2), 
  administrator('관리자', 3),
  root('ROOT', 4);

  const UserPermissionLevel(this.displayName, this.level);
  
  final String displayName;
  final int level;

  /// 위험도 기반 권한 확인
  bool canPerformAction(ActionRiskLevel riskLevel) {
    switch (riskLevel) {
      case ActionRiskLevel.safe:
        return level >= 1; // 모든 권한 레벨 허용
      case ActionRiskLevel.warning:
        return level >= 2; // 운영자 이상
      case ActionRiskLevel.danger:
        return level >= 3; // 관리자 이상  
      case ActionRiskLevel.critical:
        return level >= 4; // ROOT만
    }
  }
}

/// 작업 위험도 레벨
enum ActionRiskLevel {
  safe('안전', Colors.green),
  warning('주의', Colors.orange),
  danger('위험', Colors.red),
  critical('치명적', Colors.deepPurple);

  const ActionRiskLevel(this.displayName, this.color);
  
  final String displayName;
  final Color color;
}

class _PermissionConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const _PermissionConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}

/// 권한 관리 유틸리티
class PermissionUtils {
  static UserPermissionLevel getCurrentUserLevel() {
    // TODO: 실제 사용자 권한 확인 로직 구현
    // 현재는 ROOT로 가정
    return UserPermissionLevel.root;
  }

  static void showPermissionInfo(BuildContext context, UserPermissionLevel level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            UserPermissionBadge(level: level, showLabel: true),
            const SizedBox(width: 8),
            const Text('권한 정보'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 권한 레벨: ${level.displayName}'),
            const SizedBox(height: 8),
            const Text('허용 작업:'),
            ...ActionRiskLevel.values.map((risk) => ListTile(
              leading: Icon(
                level.canPerformAction(risk) ? Icons.check : Icons.close,
                color: level.canPerformAction(risk) ? Colors.green : Colors.red,
                size: 16,
              ),
              title: Text(risk.displayName),
              dense: true,
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}