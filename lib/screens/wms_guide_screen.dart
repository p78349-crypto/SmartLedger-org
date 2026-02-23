import 'package:flutter/material.dart';

/// WMS (Warehouse Management System) 도움말 화면
class WmsGuideScreen extends StatelessWidget {
  const WmsGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WMS 활용 가이드'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'WMS란 무엇인가요?'),
          _buildInfoCard(
            context,
            'Warehouse Management System의 약자로, 집안의 물건(식료품, 생활용품)의 위치와 수량을 체계적으로 관리하는 시스템입니다.',
            Icons.help_outline,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, '주요 특징'),
          _buildFeatureItem(
            context,
            '집/창고 탭 분리',
            '자주 쓰는 물건은 [집] 탭에서, 대량 보관은 [창고] 탭에서 따로 관리하여 복잡함을 줄였습니다.',
            Icons.tab,
          ),
          _buildFeatureItem(
            context,
            '바코드 스캔 지원',
            '하드웨어 스캐너를 연결하여 "엔터" 입력만으로 이름 조회, 입고, 출고를 빠르게 처리할 수 있습니다.',
            Icons.qr_code_scanner,
          ),
          _buildFeatureItem(
            context,
            '부족 알림',
            '설정한 기준 수량 아래로 재고가 떨어지면 장바구니에 자동으로 추가할 것을 제안합니다.',
            Icons.notifications_active,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, '사용 팁'),
          _buildTipItem(context, '1. 대형 마트에서 사온 물건은 [WMS 입고] 메뉴에서 묶음 단위로 입력하세요.'),
          _buildTipItem(context, '2. 바코드가 있는 상품은 스캐너를 사용하여 1초 만에 정보를 불러오세요.'),
          _buildTipItem(context, '3. 소모품 사용 시 [사용량 기록] 버튼을 통해 즉시 차감하세요.'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '스마트 홈 창고 관리 (WMS)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '식료품과 생활용품 재고를 한눈에 관리하고\n현명한 소비 습관을 만드세요.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String text, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }
}
