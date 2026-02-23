import 'package:flutter/material.dart';

import '../services/multi_tenant_service.dart';
import '../services/workflow_automation_engine.dart';

/// Phase 3 통합 데모 화면
/// 멀티 테넌트, 워크플로우 자동화 기능 시연
class Phase3DemoScreen extends StatefulWidget {
  const Phase3DemoScreen({super.key});

  @override
  State<Phase3DemoScreen> createState() => _Phase3DemoScreenState();
}

class _Phase3DemoScreenState extends State<Phase3DemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tenantService = MultiTenantService();
  final _workflowEngine = WorkflowAutomationEngine();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDemo();
  }

  Future<void> _initializeDemo() async {
    // 멀티 테넌트 초기화
    await _tenantService.initialize();

    // 워크플로우 초기화
    await _workflowEngine.initialize();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 3 데모: 지능형 자동화'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: '멀티 테넌트'),
            Tab(icon: Icon(Icons.account_tree), text: '워크플로우'),
            Tab(icon: Icon(Icons.integration_instructions), text: '통합 시나리오'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMultiTenantTab(),
          _buildWorkflowTab(),
          _buildIntegrationTab(),
        ],
      ),
    );
  }

  // ═══ Tab 1: 멀티 테넌트 ═══
  Widget _buildMultiTenantTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('🏢 멀티 테넌트 관리', '조직별 분리 환경 및 데이터 격리'),

          // 현재 테넌트 정보
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('현재 테넌트',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _tenantService.currentTenant.plan.color,
                      child: const Icon(Icons.business, color: Colors.white),
                    ),
                    title: Text(_tenantService.currentTenant.name),
                    subtitle: Text(_tenantService.currentTenant.organizationName),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _tenantService.currentTenant.plan.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _tenantService.currentTenant.plan.label,
                        style: TextStyle(
                          color: _tenantService.currentTenant.plan.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 테넌트 전환 데모
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('테넌트 전환 위젯',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const TenantSwitcher(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _tenantService.createTenant(
                        name: '테스트 환경',
                        organizationName: '(주)스마트레저',
                        plan: TenantPlan.standard,
                      );
                      if (mounted) setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('새 테넌트가 생성되었습니다')),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('테넌트 추가 (데모)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 데이터 격리 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('데이터 격리 설정',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildIsolationTile(
                    '격리 수준',
                    _tenantService.currentTenant.settings.isolationLevel.label,
                    _tenantService.currentTenant.settings.isolationLevel.color,
                  ),
                  _buildIsolationTile(
                    '암호화',
                    _tenantService.currentTenant.settings.encryptionEnabled ? '활성' : '비활성',
                    _tenantService.currentTenant.settings.encryptionEnabled ? Colors.green : Colors.red,
                  ),
                  _buildIsolationTile(
                    '감사 로그',
                    _tenantService.currentTenant.settings.auditLogEnabled ? '활성' : '비활성',
                    _tenantService.currentTenant.settings.auditLogEnabled ? Colors.green : Colors.red,
                  ),
                  _buildIsolationTile(
                    '교차 테넌트 읽기',
                    _tenantService.currentTenant.settings.allowCrossTenantRead ? '허용' : '차단',
                    _tenantService.currentTenant.settings.allowCrossTenantRead ? Colors.orange : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 사용량 (데모)
          TenantUsageDashboard(
            stats: TenantUsageStats(
              tenantId: _tenantService.currentTenant.id,
              memberCount: 1,
              maxMembers: _tenantService.currentTenant.plan.maxMembers,
              usedStorageMb: 125.3,
              quotaMb: _tenantService.currentTenant.dataQuotaMb,
              storageUsagePercent: 25.1,
              plan: _tenantService.currentTenant.plan,
              isOverQuota: false,
            ),
          ),

          // 플랜 비교
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('플랜 비교',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...TenantPlan.values.map((plan) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: plan.color.withValues(alpha: 0.2),
                      child: Text(plan.label[0], style: TextStyle(color: plan.color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(plan.label),
                    subtitle: Text('최대 ${plan.maxMembers}명 • ${plan.quotaMb}MB'),
                    trailing: _tenantService.currentTenant.plan == plan
                        ? const Chip(label: Text('현재', style: TextStyle(fontSize: 10)))
                        : null,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsolationTile(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  // ═══ Tab 3: 워크플로우 ═══
  Widget _buildWorkflowTab() {
    final stats = _workflowEngine.getStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('⚙️ 워크플로우 자동화', '승인 체계 + 자동화 룰 엔진'),

          // 통계
          WorkflowDashboardCard(stats: stats),
          const SizedBox(height: 12),

          // 워크플로우 목록
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('등록된 워크플로우',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._workflowEngine.workflows.map((wf) => ExpansionTile(
                    leading: Icon(
                      Icons.account_tree,
                      color: wf.isActive ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                    title: Text(wf.name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(wf.triggerCondition, style: const TextStyle(fontSize: 12)),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      Text(wf.description),
                      const SizedBox(height: 8),
                      Text('승인 단계:', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ...wf.steps.asMap().entries.map((e) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10)),
                        ),
                        title: Text(e.value.name, style: const TextStyle(fontSize: 13)),
                        subtitle: Text('필요 역할: ${e.value.requiredRole}', style: const TextStyle(fontSize: 11)),
                      )),
                      const SizedBox(height: 4),
                      Text('자동 실행: ${wf.autoActions.join(", ")}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 승인 요청 데모
          ElevatedButton.icon(
            onPressed: () async {
              await _workflowEngine.createApprovalRequest(
                workflowId: 'wf_large_transaction',
                requesterId: 'user_demo',
                title: '대금 거래 승인 요청',
                description: '1,500,000원 송금 - 테스트 거래',
                data: {'amount': 1500000},
                urgency: ApprovalUrgency.high,
              );
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.add_task),
            label: const Text('승인 요청 생성 (데모)'),
          ),
          const SizedBox(height: 12),

          // 대기 중인 승인
          if (_workflowEngine.pendingApprovals.isNotEmpty) ...[
            Text('대기 중인 승인',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._workflowEngine.pendingApprovals
                .where((r) => r.status == ApprovalStatus.pending)
                .map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ApprovalRequestCard(
                    request: r,
                    onApprove: () async {
                      await _workflowEngine.processApproval(
                        requestId: r.id, approverId: 'root', approved: true,
                      );
                      if (mounted) setState(() {});
                    },
                    onReject: () async {
                      await _workflowEngine.processApproval(
                        requestId: r.id, approverId: 'root', approved: false,
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                )),
          ],
          const SizedBox(height: 12),

          // 자동화 룰
          Text('자동화 룰',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._workflowEngine.rules.map((rule) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AutomationRuleCard(
              rule: rule,
              onToggle: (_) {
                _workflowEngine.toggleRule(rule.id);
                setState(() {});
              },
            ),
          )),
        ],
      ),
    );
  }

  // ═══ Tab 4: 통합 시나리오 ═══
  Widget _buildIntegrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('🔗 통합 시나리오', 'Phase 1+2+3 기능이 연동된 실전 시나리오'),

          // 시나리오 1: 신입사원 온보딩
          _buildScenarioCard(
            title: '시나리오 1: 신입사원 온보딩',
            icon: Icons.person_add,
            color: Colors.blue,
            steps: [
              '1️⃣ AI가 사용자 숙련도를 "초보자"로 분류',
              '2️⃣ 간단 모드 자동 활성화 (Phase 2)',
              '3️⃣ Observer 권한 자동 할당 (RBAC)',
              '4️⃣ 가이드 투어 + 맞춤 추천 표시',
              '5️⃣ 새 테넌트 환경에 멤버로 추가',
              '6️⃣ 감사 로그에 온보딩 활동 기록',
            ],
          ),
          const SizedBox(height: 12),

          // 시나리오 2: 고액 거래 처리
          _buildScenarioCard(
            title: '시나리오 2: 고액 거래 승인',
            icon: Icons.account_balance,
            color: Colors.orange,
            steps: [
              '1️⃣ 100만원 이상 거래 입력 감지',
              '2️⃣ 위험 작업 확인 다이얼로그 표시 (Phase 1)',
              '3️⃣ 승인 워크플로우 자동 트리거 (Phase 3)',
              '4️⃣ 관리자 → ROOT 2단계 승인 진행',
              '5️⃣ 승인 완료 후 거래 자동 처리',
              '6️⃣ 감사 로그 + KPI 대시보드 업데이트',
            ],
          ),
          const SizedBox(height: 12),

          // 시나리오 3: 보안 침해 대응
          _buildScenarioCard(
            title: '시나리오 3: 보안 이상 감지 대응',
            icon: Icons.security,
            color: Colors.red,
            steps: [
              '1️⃣ 비정상 접근 3회 이상 감지 (자동화 룰)',
              '2️⃣ 보안 알림 자동 발송',
              '3️⃣ 계정 자동 잠금 (30분)',
              '4️⃣ 감사 로그에 보안 위반 기록 (Phase 1)',
              '5️⃣ KPI 대시보드 보안 위반 카운터 증가 (Phase 2)',
              '6️⃣ ROOT에게 상세 보고서 알림',
            ],
          ),
          const SizedBox(height: 12),

          // 시나리오 4: 멀티 테넌트 운영
          _buildScenarioCard(
            title: '시나리오 4: 조직별 분리 운영',
            icon: Icons.business,
            color: Colors.purple,
            steps: [
              '1️⃣ 본사/지사별 테넌트 생성 (Phase 3)',
              '2️⃣ 테넌트별 독립 데이터 환경 구축',
              '3️⃣ 역할별 권한 매트릭스 적용 (Phase 2)',
              '4️⃣ 테넌트별 사용 패턴 분석 (Phase 3)',
              '5️⃣ 테넌트별 KPI 모니터링 (Phase 2)',
              '6️⃣ 통합 감사 로그로 전체 관리 (Phase 1)',
            ],
          ),
          const SizedBox(height: 24),

          // Phase 1+2+3 통합 아키텍처
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '🏗️ Phase 1+2+3 통합 아키텍처',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildArchitectureRow('Phase 1', '보안 기반', Icons.lock, Colors.red,
                    '권한 배지 / 위험 확인 / 감사 로그'),
                  const Icon(Icons.arrow_downward, color: Colors.grey),
                  _buildArchitectureRow('Phase 2', '적응형 UX', Icons.tune, Colors.blue,
                    '간단/고급 모드 / KPI / RBAC'),
                  const Icon(Icons.arrow_downward, color: Colors.grey),
                  _buildArchitectureRow('Phase 3', '지능형 자동화', Icons.psychology, Colors.purple,
                    '멀티 테넌트 / 워크플로우'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      '✅ 결과: 엔터프라이즈급 지능형 금융 관리 플랫폼 완성',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureRow(
      String phase, String subtitle, IconData icon, Color color, String features) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phase, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 11)),
            ],
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(features, style: const TextStyle(fontSize: 11), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ═══ 공통 위젯 ═══

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> steps,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: steps.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(s, style: const TextStyle(fontSize: 13)),
        )).toList(),
      ),
    );
  }
}
