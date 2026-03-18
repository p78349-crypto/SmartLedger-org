import 'package:flutter/material.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';
import 'package:smart_ledger/widgets/risk_action_confirm_dialog.dart';
import 'package:smart_ledger/services/audit_log_service.dart';

/// Phase 1 개선사항 사용 예시 및 데모
/// 새로 구현된 권한 시각화, 위험 작업 확인, 감사 로그 시스템의 사용 방법
class Phase1DemoScreen extends StatelessWidget {
  const Phase1DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 1 개선사항 데모'),
        actions: [
          // 1. 권한 배지 사용 예시
          UserPermissionBadge(
            level: PermissionUtils.getCurrentUserLevel(),
            showLabel: true,
            onTap: () => PermissionUtils.showPermissionInfo(
              context,
              PermissionUtils.getCurrentUserLevel(),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 권한 레벨 표시 데모
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏷️ 권한 레벨 배지',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('다양한 권한 레벨 시각화:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: UserPermissionLevel.values
                          .map(
                            (level) => UserPermissionBadge(
                              level: level,
                              showLabel: true,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 위험 작업 확인 데모
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 위험 작업 확인 시스템',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('위험도별 작업 확인 다이얼로그:'),
                    const SizedBox(height: 12),

                    // 위험도별 버튼들
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildRiskButton(
                          context,
                          '안전 작업',
                          ActionRiskLevel.safe,
                          '사용자 프로필 조회',
                          '개인 정보를 조회합니다.',
                          null,
                        ),
                        _buildRiskButton(
                          context,
                          '주의 작업',
                          ActionRiskLevel.warning,
                          '설정 변경',
                          '앱 설정을 변경합니다.',
                          ['사용자 환경설정'],
                        ),
                        _buildRiskButton(
                          context,
                          '위험 작업',
                          ActionRiskLevel.danger,
                          '데이터 삭제',
                          '선택된 거래 데이터를 완전히 삭제합니다.',
                          ['거래 데이터베이스', '백업 파일'],
                        ),
                        _buildRiskButton(
                          context,
                          '치명적 작업',
                          ActionRiskLevel.critical,
                          '시스템 초기화',
                          '전체 앱 데이터가 삭제되고 복구할 수 없습니다.',
                          ['모든 계정', '거래 기록', '설정 정보'],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 감사 로그 데모
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 감사 로그 시스템',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _demoAuditLog(context, true),
                            icon: const Icon(Icons.check),
                            label: const Text('성공 로그 생성'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _demoAuditLog(context, false),
                            icon: const Icon(Icons.error),
                            label: const Text('실패 로그 생성'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 감사 로그 요약 표시
            const Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '📊 실시간 감사 로그 요약',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              FailedActionsCard(),
                              SizedBox(height: 12),
                              AuditLogSummaryCard(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskButton(
    BuildContext context,
    String label,
    ActionRiskLevel riskLevel,
    String actionTitle,
    String actionDescription,
    List<String>? affectedSystems,
  ) {
    return ElevatedButton(
      onPressed: () async {
        final confirmed = await RiskActionConfirmDialog.show(
          context: context,
          actionTitle: actionTitle,
          actionDescription: actionDescription,
          riskLevel: riskLevel,
          impactDescription: riskLevel == ActionRiskLevel.critical
              ? '이 작업은 되돌릴 수 없으며 모든 데이터가 영구적으로 손실됩니다.'
              : null,
          affectedSystems: affectedSystems,
        );

        if (confirmed && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$actionTitle 작업이 확인되었습니다.'),
              backgroundColor: riskLevel.color,
            ),
          );

          // 작업 실행 로그 기록
          await AuditLogService.logSuccess(
            eventType: AuditEventType.dataModification,
            action: actionTitle,
            userLevel: PermissionUtils.getCurrentUserLevel(),
            riskLevel: riskLevel,
            metadata: {'demo': true, 'affected_systems': affectedSystems ?? []},
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: riskLevel.color.withValues(alpha: 0.1),
        foregroundColor: riskLevel.color,
        side: BorderSide(color: riskLevel.color.withValues(alpha: 0.3)),
      ),
      child: Text(label),
    );
  }

  Future<void> _demoAuditLog(BuildContext context, bool success) async {
    if (success) {
      await AuditLogService.logSuccess(
        eventType: AuditEventType.dataAccess,
        action: '데모 작업 성공',
        userLevel: PermissionUtils.getCurrentUserLevel(),
        metadata: {
          'demo': true,
          'timestamp': DateTime.now().toIso8601String(),
          'user_action': 'manual_demo_trigger',
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('성공 로그가 기록되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await AuditLogService.logFailure(
        eventType: AuditEventType.dataModification,
        action: '데모 작업 실패',
        userLevel: PermissionUtils.getCurrentUserLevel(),
        errorMessage: '의도적인 데모용 실패',
        metadata: {
          'demo': true,
          'error_code': 'DEMO_FAILURE',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('실패 로그가 기록되었습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
