import 'package:flutter/material.dart';

import '../services/multi_tenant_service.dart';
import '../services/workflow_automation_engine.dart';

/// Phase 3 통합 데모 화면
/// 멀티 테넌트, 워크플로우 자동화 기능 시연
part 'phase3_demo_screen_ui.dart';

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

  // ═══ Tab 3: 워크플로우 ═══

  // ═══ Tab 4: 통합 시나리오 ═══

  Widget _buildArchitectureRow(
    String phase,
    String subtitle,
    IconData icon,
    Color color,
    String features,
  ) {
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
              Text(
                phase,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              Text(subtitle, style: const TextStyle(fontSize: 11)),
            ],
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              features,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ═══ 공통 위젯 ═══
}
