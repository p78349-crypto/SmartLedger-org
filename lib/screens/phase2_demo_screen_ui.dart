part of 'phase2_demo_screen.dart';

extension Phase2DemoUI on _Phase2DemoScreenState {
  Widget _buildSimpleModeDemo() {
    return SimpleModeBuilder(
      builder: (context, isSimpleMode) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 모드 전환 컨트롤
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔄 모드 전환',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('현재 모드:'),
                          const SizedBox(width: 12),
                          Chip(
                            avatar: Icon(
                              isSimpleMode ? Icons.lightbulb : Icons.settings,
                              size: 16,
                            ),
                            label: Text(isSimpleMode ? '간단 모드' : '고급 모드'),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final confirmed =
                                  await ModeChangeConfirmDialog.show(
                                    context,
                                    !isSimpleMode,
                                  );
                              if (confirmed) {
                                await SimpleModeManger.toggleSimpleMode();
                                _logModeChange(!isSimpleMode);
                              }
                            },
                            icon: Icon(
                              isSimpleMode ? Icons.settings : Icons.lightbulb,
                            ),
                            label: Text(isSimpleMode ? '고급 모드로' : '간단 모드로'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 현재 모드 UI 미리보기
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📱 ${isSimpleMode ? '간단 모드' : '고급 모드'} UI 미리보기',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        if (isSimpleMode) ...[
                          // 간단 모드 UI
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  '✅ 간단 모드 특징',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text('• 핵심 4-5개 기능만 표시'),
                                Text('• 큰 아이콘과 명확한 설명'),
                                Text('• 복잡한 옵션 숨김'),
                                Text('• 초보자 친화적 인터페이스'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 간단 모드 액션 그리드 데모
                          Expanded(
                            child: SimpleModeActionGrid(
                              actions: {
                                CoreAction.status: () => _demoAction('상태 확인'),
                                CoreAction.logs: () => _demoAction('로그 보기'),
                                CoreAction.connect: () => _demoAction('연결'),
                                CoreAction.help: () => _demoAction('도움말'),
                              },
                            ),
                          ),
                        ] else ...[
                          // 고급 모드 UI
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  '⚙️ 고급 모드 특징',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text('• 모든 기능 접근 가능'),
                                Text('• 상세 설정 및 고급 옵션'),
                                Text('• 전문가용 도구들'),
                                Text('• 커스터마이징 가능'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 고급 기능 목록
                          Expanded(
                            child: ListView(
                              children: const [
                                ListTile(
                                  leading: Icon(Icons.analytics),
                                  title: Text('상세 분석 도구'),
                                  subtitle: Text('고급 데이터 분석 및 리포팅'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.tune),
                                  title: Text('고급 설정'),
                                  subtitle: Text('세부적인 시스템 구성'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.code),
                                  title: Text('개발자 도구'),
                                  subtitle: Text('API, 로그, 디버깅 정보'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.admin_panel_settings),
                                  title: Text('관리자 기능'),
                                  subtitle: Text('사용자 관리, 권한 설정'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPIDashboardDemo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 운영 KPI 대시보드',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('실시간 운영 지표 모니터링 및 시스템 상태 추적'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 실제 KPI 대시보드
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  OperationalKPIDashboard(),
                  SizedBox(height: 16),

                  // 추가 위젯들
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '🔄 실시간 상태',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                RealTimeStatusIndicator(),
                                SizedBox(height: 8),
                                Text('시스템 정상 가동'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '📈 트렌드',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                SimpleTrendChart(
                                  data: [10, 15, 12, 18, 20, 16, 22],
                                  color: Colors.blue,
                                  label: '일일 처리량',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDemo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔐 역할 기반 접근 제어 (RBAC)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('세분화된 권한 관리 및 기능별 접근 제어'),
                  const SizedBox(height: 16),

                  // 권한 테스트 버튼들
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPermissionTestButton(AppFeature.viewDashboard),
                      _buildPermissionTestButton(AppFeature.editTransactions),
                      _buildPermissionTestButton(AppFeature.deleteAccounts),
                      _buildPermissionTestButton(
                        AppFeature.systemConfiguration,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 권한 매트릭스
          const Expanded(child: PermissionMatrixWidget()),
        ],
      ),
    );
  }

  Widget _buildIntegrationDemo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Phase 2 통합 테스트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('모든 Phase 2 개선사항이 함께 작동하는 시나리오 테스트'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 통합 테스트 시나리오들
          Expanded(
            child: ListView(
              children: [
                _buildIntegrationTestTile(
                  '시나리오 1: 비기술 사용자 온보딩',
                  '간단 모드 → 핵심 기능 사용 → 점진적 고급 기능 학습',
                  Icons.person,
                  () => _runIntegrationTest(1),
                ),

                _buildIntegrationTestTile(
                  '시나리오 2: 운영자 일일 모니터링',
                  'KPI 대시보드 확인 → 알림 처리 → 권한 기반 조치',
                  Icons.monitor,
                  () => _runIntegrationTest(2),
                ),

                _buildIntegrationTestTile(
                  '시나리오 3: 관리자 보안 검토',
                  '감사 로그 분석 → 권한 매트릭스 점검 → 보안 조치',
                  Icons.security,
                  () => _runIntegrationTest(3),
                ),

                _buildIntegrationTestTile(
                  '시나리오 4: ROOT 시스템 관리',
                  '전체 KPI 분석 → 전체 권한으로 시스템 관리',
                  Icons.admin_panel_settings,
                  () => _runIntegrationTest(4),
                ),
              ],
            ),
          ),

          // 전체 성능 요약
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎖️ Phase 2 개선 성과',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('✅ 일반 사용자 친화성: 8.2 → 8.8 (+0.6)'),
                  const Text('✅ 운영 편의성: 9.7 → 9.8 (+0.1)'),
                  const Text('✅ 보안/통제성: 8.9 → 9.2 (+0.3)'),
                  const Text('🎯 예상 종합 점수: 9.0 → 9.3'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTestButton(AppFeature feature) {
    final hasAccess = RoleBasedAccessControl.canAccess(feature);
    return ElevatedButton.icon(
      onPressed: () async {
        await RoleBasedAccessControl.checkAccessWithAudit(feature, context);
      },
      icon: Icon(hasAccess ? Icons.check : Icons.lock),
      label: Text(feature.displayName),
      style: ElevatedButton.styleFrom(
        backgroundColor: hasAccess
            ? Colors.green.shade100
            : Colors.grey.shade200,
        foregroundColor: hasAccess
            ? Colors.green.shade800
            : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildIntegrationTestTile(
    String title,
    String description,
    IconData icon,
    VoidCallback onTest,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(description),
        trailing: ElevatedButton(onPressed: onTest, child: const Text('테스트')),
      ),
    );
  }
}
