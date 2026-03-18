import 'package:flutter/material.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';
import 'package:smart_ledger/services/audit_log_service.dart';

/// Phase 2 개선: 역할 기반 접근 제어 (RBAC) 시스템
/// 세분화된 권한 관리를 위한 역할별 권한 매트릭스
class RoleBasedAccessControl {
  /// 어플리케이션 기능 목록
  static const List<AppFeature> allFeatures = [
    // 데이터 접근
    AppFeature.viewDashboard,
    AppFeature.viewTransactions,
    AppFeature.viewReports,
    AppFeature.viewAuditLogs,

    // 데이터 수정
    AppFeature.createTransactions,
    AppFeature.editTransactions,
    AppFeature.deleteTransactions,
    AppFeature.createAccounts,
    AppFeature.editAccounts,
    AppFeature.deleteAccounts,

    // 시스템 관리
    AppFeature.manageUsers,
    AppFeature.manageSettings,
    AppFeature.manageBackups,
    AppFeature.manageSecurity,

    // ROOT 전용
    AppFeature.systemConfiguration,
    AppFeature.auditLogAccess,
    AppFeature.emergencyActions,
  ];

  /// 역할별 권한 매트릭스
  static const Map<UserPermissionLevel, Set<AppFeature>> _rolePermissions = {
    UserPermissionLevel.observer: {
      AppFeature.viewDashboard,
      AppFeature.viewTransactions,
      AppFeature.viewReports,
    },
    UserPermissionLevel.operator: {
      AppFeature.viewDashboard,
      AppFeature.viewTransactions,
      AppFeature.viewReports,
      AppFeature.createTransactions,
      AppFeature.editTransactions,
      AppFeature.createAccounts,
      AppFeature.editAccounts,
    },
    UserPermissionLevel.administrator: {
      AppFeature.viewDashboard,
      AppFeature.viewTransactions,
      AppFeature.viewReports,
      AppFeature.viewAuditLogs,
      AppFeature.createTransactions,
      AppFeature.editTransactions,
      AppFeature.deleteTransactions,
      AppFeature.createAccounts,
      AppFeature.editAccounts,
      AppFeature.deleteAccounts,
      AppFeature.manageUsers,
      AppFeature.manageSettings,
      AppFeature.manageBackups,
    },
    UserPermissionLevel.root: {
      // ROOT는 모든 권한 보유
      ...allFeatures,
    },
  };

  /// 특정 역할이 기능에 접근할 수 있는지 확인
  static bool hasPermission(UserPermissionLevel role, AppFeature feature) {
    final permissions = _rolePermissions[role] ?? <AppFeature>{};
    return permissions.contains(feature);
  }

  /// 현재 사용자가 기능에 접근할 수 있는지 확인
  static bool canAccess(AppFeature feature) {
    final currentRole = PermissionUtils.getCurrentUserLevel();
    return hasPermission(currentRole, feature);
  }

  /// 권한 검사와 감사 로그 기록을 함께 수행
  static Future<bool> checkAccessWithAudit(
    AppFeature feature,
    BuildContext context, {
    bool showDeniedMessage = true,
  }) async {
    final currentRole = PermissionUtils.getCurrentUserLevel();
    final hasAccess = hasPermission(currentRole, feature);

    if (hasAccess) {
      // 성공적인 접근 로그
      await AuditLogService.logSuccess(
        eventType: AuditEventType.authorization,
        action: '기능 접근: ${feature.displayName}',
        userLevel: currentRole,
        metadata: {'feature': feature.name, 'access_granted': true},
      );
    } else {
      // 권한 거부 로그
      await AuditLogService.logPermissionDenied(
        action: '기능 접근 시도: ${feature.displayName}',
        userLevel: currentRole,
        requiredLevel: feature.minimumRole.toActionRisk(),
        metadata: {'feature': feature.name, 'access_denied': true},
      );

      // 사용자에게 권한 부족 알림
      if (showDeniedMessage && context.mounted) {
        _showPermissionDeniedDialog(context, feature, currentRole);
      }
    }

    return hasAccess;
  }

  /// 권한 부족 다이얼로그 표시
  static void _showPermissionDeniedDialog(
    BuildContext context,
    AppFeature feature,
    UserPermissionLevel currentRole,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('접근 권한 부족'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${feature.displayName} 기능에 접근할 권한이 없습니다.'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('현재 권한: '),
                UserPermissionBadge(level: currentRole, showLabel: true),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('필요 권한: '),
                UserPermissionBadge(
                  level: feature.minimumRole,
                  showLabel: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '💡 권한 상승이 필요한 경우 관리자에게 문의하세요.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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

  /// 역할별 접근 가능한 기능 목록 반환
  static List<AppFeature> getPermittedFeatures(UserPermissionLevel role) {
    final permissions = _rolePermissions[role] ?? <AppFeature>{};
    return permissions.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }
}

/// 어플리케이션 기능 열거형
enum AppFeature {
  // 데이터 보기
  viewDashboard('대시보드 보기', UserPermissionLevel.observer, Icons.dashboard),
  viewTransactions('거래 내역 보기', UserPermissionLevel.observer, Icons.list),
  viewReports('리포트 보기', UserPermissionLevel.observer, Icons.analytics),
  viewAuditLogs('감사 로그 보기', UserPermissionLevel.administrator, Icons.history),

  // 데이터 생성
  createTransactions('거래 생성', UserPermissionLevel.operator, Icons.add),
  createAccounts('계정 생성', UserPermissionLevel.operator, Icons.account_circle),

  // 데이터 수정
  editTransactions('거래 수정', UserPermissionLevel.operator, Icons.edit),
  editAccounts('계정 수정', UserPermissionLevel.operator, Icons.edit),

  // 데이터 삭제
  deleteTransactions('거래 삭제', UserPermissionLevel.administrator, Icons.delete),
  deleteAccounts('계정 삭제', UserPermissionLevel.administrator, Icons.delete),

  // 시스템 관리
  manageUsers('사용자 관리', UserPermissionLevel.administrator, Icons.people),
  manageSettings('설정 관리', UserPermissionLevel.administrator, Icons.settings),
  manageBackups('백업 관리', UserPermissionLevel.administrator, Icons.backup),
  manageSecurity('보안 관리', UserPermissionLevel.administrator, Icons.security),

  // ROOT 전용
  systemConfiguration('시스템 구성', UserPermissionLevel.root, Icons.build),
  auditLogAccess(
    '감사 로그 관리',
    UserPermissionLevel.root,
    Icons.admin_panel_settings,
  ),
  emergencyActions('비상 조치', UserPermissionLevel.root, Icons.emergency);

  const AppFeature(this.displayName, this.minimumRole, this.icon);

  final String displayName;
  final UserPermissionLevel minimumRole;
  final IconData icon;
}

/// 권한 매트릭스 시각화 위젯
class PermissionMatrixWidget extends StatelessWidget {
  const PermissionMatrixWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '권한 매트릭스',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 현재 사용자 권한 요약
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  UserPermissionBadge(
                    level: PermissionUtils.getCurrentUserLevel(),
                    showLabel: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '현재 접근 가능한 기능: ${RoleBasedAccessControl.getPermittedFeatures(PermissionUtils.getCurrentUserLevel()).length}개',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 기능별 접근 권한 표시
            Text(
              '기능별 접근 권한',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                children: AppFeature.values.map((feature) {
                  final hasAccess = RoleBasedAccessControl.canAccess(feature);
                  return ListTile(
                    leading: Icon(
                      feature.icon,
                      color: hasAccess ? Colors.green : Colors.grey,
                    ),
                    title: Text(feature.displayName),
                    subtitle: Text(
                      '최소 필요 권한: ${feature.minimumRole.displayName}',
                    ),
                    trailing: Icon(
                      hasAccess ? Icons.check_circle : Icons.cancel,
                      color: hasAccess ? Colors.green : Colors.red,
                    ),
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 보안 게이트 위젯 - 기능 접근 시 권한 검증
class SecureFeatureGate extends StatelessWidget {
  final AppFeature requiredFeature;
  final Widget child;
  final Widget? deniedWidget;
  final bool showDeniedMessage;

  const SecureFeatureGate({
    super.key,
    required this.requiredFeature,
    required this.child,
    this.deniedWidget,
    this.showDeniedMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RoleBasedAccessControl.checkAccessWithAudit(
        requiredFeature,
        context,
        showDeniedMessage: showDeniedMessage,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == true) {
          return child;
        } else {
          return deniedWidget ?? _buildDefaultDeniedWidget(context);
        }
      },
    );
  }

  Widget _buildDefaultDeniedWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            '접근 권한 필요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${requiredFeature.displayName} 기능에 접근하려면 ${requiredFeature.minimumRole.displayName} 권한이 필요합니다.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// UserPermissionLevel 확장
extension UserPermissionLevelExtension on UserPermissionLevel {
  ActionRiskLevel toActionRisk() {
    switch (this) {
      case UserPermissionLevel.observer:
        return ActionRiskLevel.safe;
      case UserPermissionLevel.operator:
        return ActionRiskLevel.warning;
      case UserPermissionLevel.administrator:
        return ActionRiskLevel.danger;
      case UserPermissionLevel.root:
        return ActionRiskLevel.critical;
    }
  }
}

/// 권한 상승 요청 시스템
class PermissionElevationRequest {
  static Future<bool> requestElevation({
    required BuildContext context,
    required AppFeature targetFeature,
    required String reason,
  }) async {
    final currentRole = PermissionUtils.getCurrentUserLevel();
    final requiredRole = targetFeature.minimumRole;

    // 임시 권한 부여 요청 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 상승 요청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${targetFeature.displayName} 기능 사용을 위해 임시 권한 상승을 요청합니다.'),
            const SizedBox(height: 16),
            Text('현재 권한: ${currentRole.displayName}'),
            Text('필요 권한: ${requiredRole.displayName}'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '요청 사유',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              controller: TextEditingController(text: reason),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('요청'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 권한 상승 요청 로깅
      await AuditLogService.log(
        eventType: AuditEventType.authorization,
        action: '권한 상승 요청: ${targetFeature.displayName}',
        userLevel: currentRole,
        metadata: {
          'target_feature': targetFeature.name,
          'current_role': currentRole.name,
          'required_role': requiredRole.name,
          'reason': reason,
          'request_time': DateTime.now().toIso8601String(),
        },
      );

      return true;
    }

    return false;
  }
}
