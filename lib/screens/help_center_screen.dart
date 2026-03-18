import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';

/// 도움말 센터 메인 화면 - 카테고리별 도움말 진입점
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('도움말 센터'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(context, colorScheme),
          const SizedBox(height: 24),
          _buildFeaturedWorkflowCard(context),
          const SizedBox(height: 24),
          _buildSectionTitle('시작하기'),
          _buildHelpCard(
            context,
            icon: Icons.rocket_launch,
            title: '빠른 시작 가이드',
            description: '앱을 처음 시작하시나요? 기본 사용법을 알아보세요',
            route: AppRoutes.helpQuickStart,
            color: Colors.blue,
          ),
          _buildHelpCard(
            context,
            icon: Icons.book,
            title: '완전한 사용설명서',
            description: '모든 기능에 대한 상세한 설명서',
            route: AppRoutes.helpUserManual,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('기능별 도움말'),
          _buildHelpCard(
            context,
            icon: Icons.account_balance_wallet,
            title: '거래 입력 가이드',
            description: '지출/수입 입력, OCR 스캔, 반품 처리 방법',
            route: AppRoutes.helpTransactions,
            color: Colors.orange,
          ),
          _buildHelpCard(
            context,
            icon: Icons.show_chart,
            title: '통계 보는 법',
            description: '월별, 카테고리별 통계 분석 방법',
            route: AppRoutes.helpStatistics,
            color: Colors.purple,
          ),
          _buildHelpCard(
            context,
            icon: Icons.business_center,
            title: '자산 관리 가이드',
            description: '자산 추가, 평가액 업데이트, 수익률 확인',
            route: AppRoutes.helpAssets,
            color: Colors.teal,
          ),
          _buildHelpCard(
            context,
            icon: Icons.shopping_cart,
            title: '쇼핑 카트 사용법',
            description: '장보기 리스트 작성 및 가계부 자동 입력',
            route: AppRoutes.helpShopping,
            color: Colors.pink,
          ),
          _buildHelpCard(
            context,
            icon: Icons.inventory_2,
            title: '재고 관리 가이드',
            description: '식품 유통기한 추적 및 생필품 관리',
            route: AppRoutes.helpInventory,
            color: Colors.brown,
          ),
          _buildHelpCard(
            context,
            icon: Icons.backup,
            title: '백업 및 복원',
            description: '데이터 백업하기와 복원하는 방법',
            route: AppRoutes.helpBackup,
            color: Colors.indigo,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('추가 도움말'),
          _buildHelpCard(
            context,
            icon: Icons.question_answer,
            title: '자주 묻는 질문 (FAQ)',
            description: '사용자들이 자주 묻는 질문과 답변',
            route: AppRoutes.helpFaq,
            color: Colors.deepOrange,
          ),
          _buildHelpCard(
            context,
            icon: Icons.tips_and_updates,
            title: '팁과 트릭',
            description: '앱을 더 효율적으로 사용하는 방법',
            route: AppRoutes.helpTips,
            color: Colors.amber,
          ),
          _buildHelpCard(
            context,
            icon: Icons.update,
            title: '업데이트 노트',
            description: '최근 업데이트 내용 및 새 기능',
            route: AppRoutes.helpChangelog,
            color: Colors.cyan,
          ),
          const SizedBox(height: 24),
          _buildContactCard(context, colorScheme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_center, size: 32, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SmartLedger 도움말',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '원하는 카테고리를 선택하여 상세한 도움말을 확인하세요. '
              '처음 사용하시는 경우 "빠른 시작 가이드"를 추천합니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ 4단계 워크플로우 특별 강조 카드
  Widget _buildFeaturedWorkflowCard(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.helpRecipeWorkflow),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade100, Colors.orange.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with star icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('⭐ ', style: TextStyle(fontSize: 16)),
                              Text(
                                '추천',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            '4단계 완전 가이드',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.amber.shade700,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'SmartLedger의 핵심 기능을 활용한 완벽한 워크플로우',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Workflow steps preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStep('1️⃣', '레시피', Colors.blue.shade400),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      _buildMiniStep('2️⃣', '장바구니', Colors.green.shade400),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      _buildMiniStep('3️⃣', '지출입력', Colors.orange.shade400),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      _buildMiniStep('4️⃣', '일일거래', Colors.purple.shade400),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Call to action
                Center(
                  child: Text(
                    '👆 탭하여 상세 가이드 보기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStep(String emoji, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String route,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '추가 도움이 필요하신가요?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '설정 → 도움말 → 문의하기를 통해 개발팀에 직접 연락하실 수 있습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
