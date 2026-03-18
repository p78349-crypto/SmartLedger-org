part of 'phase2_demo_screen.dart';

extension Phase2DemoLogic on _Phase2DemoScreenState {
  Future<void> _demoAction(String action) async {
    await AuditLogService.logSuccess(
      eventType: AuditEventType.dataAccess,
      action: '데모 액션: $action',
      userLevel: PermissionUtils.getCurrentUserLevel(),
      metadata: {'demo': true, 'simple_mode': true},
    );

    if (mounted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action 기능이 실행되었습니다'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _logModeChange(bool toSimpleMode) async {
    await AuditLogService.logSuccess(
      eventType: AuditEventType.systemConfiguration,
      action: toSimpleMode ? '간단 모드로 전환' : '고급 모드로 전환',
      userLevel: PermissionUtils.getCurrentUserLevel(),
      metadata: {
        'mode_change': true,
        'new_mode': toSimpleMode ? 'simple' : 'advanced',
      },
    );
  }

  Future<void> _runIntegrationTest(int scenario) async {
    // 통합 테스트 실행 시뮬레이션
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('시나리오 $scenario 실행 중...'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('통합 테스트를 진행하고 있습니다'),
          ],
        ),
      ),
    );

    // 시뮬레이션 지연
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);

      // 결과 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('테스트 완료'),
            ],
          ),
          content: Text('시나리오 $scenario이(가) 성공적으로 완료되었습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );

      // 테스트 로깅
      await AuditLogService.logSuccess(
        eventType: AuditEventType.systemConfiguration,
        action: '통합 테스트 시나리오 $scenario 실행',
        userLevel: PermissionUtils.getCurrentUserLevel(),
        metadata: {'integration_test': true, 'scenario': scenario, 'phase': 2},
      );
    }
  }
}
