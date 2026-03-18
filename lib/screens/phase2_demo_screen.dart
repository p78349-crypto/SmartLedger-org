import 'package:flutter/material.dart';
import 'package:smart_ledger/services/simple_mode_service.dart';
import 'package:smart_ledger/services/role_based_access_control.dart';
import 'package:smart_ledger/widgets/operational_kpi_dashboard.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';
import 'package:smart_ledger/services/audit_log_service.dart';

part 'phase2_demo_screen_logic.dart';
part 'phase2_demo_screen_ui.dart';

/// Phase 2 개선사항 통합 데모 화면
/// 간단 모드, KPI 대시보드, 역할별 권한 관리의 종합 시연
class Phase2DemoScreen extends StatefulWidget {
  const Phase2DemoScreen({super.key});

  @override
  State<Phase2DemoScreen> createState() => _Phase2DemoScreenState();
}

class _Phase2DemoScreenState extends State<Phase2DemoScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // 간단 모드 매니저 초기화
    SimpleModeManger.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 2 개선사항 데모'),
        actions: [
          // 현재 모드 표시
          SimpleModeBuilder(
            builder: (context, isSimple) => Chip(
              avatar: Icon(
                isSimple ? Icons.lightbulb : Icons.settings,
                size: 16,
              ),
              label: Text(isSimple ? '간단 모드' : '고급 모드'),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          // 권한 배지
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

      body: Column(
        children: [
          // 탭 바
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: TabBar(
              controller: TabController(
                length: 4,
                vsync: Scaffold.of(context),
                initialIndex: _selectedTab,
              ),
              onTap: (index) => setState(() => _selectedTab = index),
              tabs: const [
                Tab(icon: Icon(Icons.toggle_on), text: '간단/고급 모드'),
                Tab(icon: Icon(Icons.analytics), text: 'KPI 대시보드'),
                Tab(icon: Icon(Icons.security), text: '권한 관리'),
                Tab(icon: Icon(Icons.integration_instructions), text: '통합 테스트'),
              ],
            ),
          ),

          // 탭 콘텐츠
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildSimpleModeDemo(),
                _buildKPIDashboardDemo(),
                _buildPermissionDemo(),
                _buildIntegrationDemo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 간단/고급 모드 데모

  /// KPI 대시보드 데모

  /// 권한 관리 데모

  /// 통합 테스트 데모
}
