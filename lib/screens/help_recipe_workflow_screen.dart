import 'package:flutter/material.dart';
import 'help_detail_screen.dart';

/// 레시피 → 장바구니 → 지출입력 → 일일거래 4단계 워크플로우 가이드
/// 이 프로세스는 SmartLedger의 핵심 기능으로 특별히 강조됨
class HelpRecipeWorkflowScreen extends StatelessWidget {
  const HelpRecipeWorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⭐ 4단계 완벽 가이드'),
        backgroundColor: Colors.amber[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHighlightBanner(context, colorScheme),
          const SizedBox(height: 24),
          _buildOverviewCard(context, colorScheme),
          const SizedBox(height: 24),
          _buildDetailedSections(context),
          const SizedBox(height: 24),
          _buildTipsCard(context, colorScheme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHighlightBanner(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.star, size: 48, color: Colors.white),
          SizedBox(height: 12),
          Text(
            '핵심 기능 완벽 마스터',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '레시피부터 가계부까지\n한 번에 해결하는 스마트한 방법',
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '4단계 프로세스 개요',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'SmartLedger의 가장 강력한 기능! '
              '요리 계획부터 지출 기록까지 자동으로 연결되는 워크플로우입니다.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 20),
            _buildStepOverview(
              context,
              '1️⃣',
              '레시피 관리',
              '만들고 싶은 요리와 필요한 재료 확인',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            Center(
              child: Icon(
                Icons.arrow_downward,
                color: Colors.grey[400],
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            _buildStepOverview(
              context,
              '2️⃣',
              '쇼핑 카트',
              '부족한 재료를 장바구니에 자동 추가',
              Colors.green,
            ),
            const SizedBox(height: 12),
            Center(
              child: Icon(
                Icons.arrow_downward,
                color: Colors.grey[400],
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            _buildStepOverview(
              context,
              '3️⃣',
              '지출 입력',
              '구매한 항목을 가계부에 자동 입력',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            Center(
              child: Icon(
                Icons.arrow_downward,
                color: Colors.grey[400],
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            _buildStepOverview(
              context,
              '4️⃣',
              '일일 거래',
              '오늘의 지출 내역을 바로 확인',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOverview(
    BuildContext context,
    String emoji,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSections(BuildContext context) {
    return const HelpDetailScreen(
      title: '',
      sections: [
        HelpSection(
          title: '1단계: 레시피 관리',
          icon: Icons.menu_book,
          iconColor: Colors.blue,
          content: [
            TextContent('맛있는 요리를 계획하고 필요한 재료를 확인하세요.'),
            StepContent([
              '메인 화면 → 재고 → 레시피 관리',
              '만들고 싶은 레시피 선택 (예: 김치찌개, 된장국)',
              '"필요한 재료" 탭에서 재료 목록 확인',
              '부족한 재료가 빨간색으로 표시됨',
            ]),
            TipContent(
              '레시피에 없는 요리는 "+ 레시피 추가"로 새로 등록할 수 있습니다. '
              '재료와 조리법을 입력하면 다음에 다시 사용할 수 있어요!',
            ),
          ],
        ),
        HelpSection(
          title: '2단계: 쇼핑 카트 자동 추가',
          icon: Icons.shopping_cart,
          iconColor: Colors.green,
          content: [
            TextContent('부족한 재료를 쇼핑 카트에 자동으로 추가하세요.'),
            StepContent([
              '레시피 화면에서 "장바구니에 추가" 버튼 탭',
              '부족한 재료가 쇼핑 카트에 자동으로 추가됨',
              '쇼핑 카트 화면으로 자동 이동',
              '추가된 항목 확인 및 수량 조정',
            ]),
            TextContent('🎯 **핵심 포인트**: 재고와 연동되어 정말 필요한 것만 추가됩니다!'),
            BulletListContent([
              '재고에 있는 재료는 자동으로 제외',
              '부족한 수량만큼 정확히 계산',
              '유통기한 임박 재료는 경고 표시',
            ]),
            TipContent('장보기 전에 여러 레시피를 선택해서 한 번에 장바구니에 추가하면 편리합니다!'),
          ],
        ),
        HelpSection(
          title: '3단계: 마트에서 쇼핑하기',
          icon: Icons.store,
          iconColor: Colors.orange,
          content: [
            TextContent('쇼핑 카트를 보면서 효율적으로 장을 보세요.'),
            StepContent([
              '쇼핑 카트 화면 열기',
              '물품을 장바구니에 담으면서 항목을 "탭"하여 체크',
              '체크된 항목은 자동으로 목록 하단으로 이동',
              '아직 안 산 물품이 상단에 남아 쉽게 확인',
            ]),
            WarningContent('계산대에서 반환되거나 품절된 항목은 다시 탭하여 체크 해제하세요!'),
            TextContent('💡 **프로 팁**: 마트 구역별로 정렬하면 동선이 짧아집니다!'),
          ],
        ),
        HelpSection(
          title: '4단계: 지출 자동 입력',
          icon: Icons.receipt_long,
          iconColor: Colors.orange,
          content: [
            TextContent('집에 도착하면 구매한 항목을 가계부에 한 번에 입력하세요.'),
            StepContent([
              '쇼핑 카트 화면에서 "체크 항목 지출입력" 버튼 탭',
              '체크된 각 항목에 대해 입력 화면이 순차적으로 표시',
              '결제수단, 카테고리는 마지막 값이 자동으로 채워짐',
              '실제 구매 가격 확인/수정',
              '메모 추가 (예: "이마트 · 세일 상품")',
            ]),
            TextContent('⚡ **시간 절약 기능**: 여러 항목 한 번에 입력!'),
            BulletListContent([
              '"저장" - 현재 항목만 저장하고 다음 항목으로',
              '"나머지 모두 저장" - 남은 항목 일괄 저장 (중간부터)',
              '같은 결제수단/카테고리로 자동 채워짐',
            ]),
            TipContent(
              '메모를 "마트명 · 특이사항" 형태로 입력하면, 다음 쇼핑 때 '
              '해당 마트의 결제수단이 자동으로 선택됩니다!',
              icon: Icons.auto_awesome,
            ),
          ],
        ),
        HelpSection(
          title: '5단계: 일일 거래 확인',
          icon: Icons.today,
          iconColor: Colors.purple,
          content: [
            TextContent('오늘 입력한 거래를 바로 확인하고 검증하세요.'),
            StepContent([
              '메인 화면 → 통계 → 일일 거래',
              '오늘 날짜의 거래 목록 확인',
              '방금 입력한 쇼핑 내역이 모두 표시됨',
              '잘못 입력된 항목은 바로 수정 가능',
            ]),
            TextContent('📊 **즉시 반영**: 통계도 실시간으로 업데이트됩니다!'),
            BulletListContent([
              '오늘의 총 지출 금액',
              '카테고리별 지출 분포',
              '예산 대비 사용률',
              '월간 지출 추이에 반영',
            ]),
          ],
        ),
        HelpSection(
          title: '6️⃣ 보너스: 재고 자동 업데이트',
          icon: Icons.inventory,
          iconColor: Colors.teal,
          content: [
            TextContent('구매한 식재료가 자동으로 재고에 추가됩니다!'),
            BulletListContent([
              '쇼핑 카트에서 입력한 수량이 재고에 반영',
              '유통기한 자동 설정 (카테고리별 기본값)',
              '다음 레시피 사용 시 최신 재고 기준으로 계산',
            ]),
            TipContent(
              '이제 다시 레시피를 선택하면 방금 산 재료는 제외되고, '
              '정말 부족한 것만 장바구니에 추가됩니다!',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipsCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      color: Colors.lightBlue[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text(
                  '💎 고급 활용 팁',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              '🎯 주간 식단 계획',
              '월요일에 한 주 레시피를 미리 선택하고 장바구니에 추가하세요. '
                  '주말 장보기 한 번으로 일주일치 준비 완료!',
            ),
            const Divider(height: 24),
            _buildTipItem(
              '💰 예산 관리',
              '쇼핑 카트에서 예상 총액을 확인하고, 예산을 초과하면 우선순위가 낮은 항목을 제거하세요.',
            ),
            const Divider(height: 24),
            _buildTipItem(
              '📊 소비 패턴 분석',
              '매달 식비 통계를 보면 어떤 재료를 많이 사는지, 어느 마트가 저렴한지 알 수 있습니다.',
            ),
            const Divider(height: 24),
            _buildTipItem(
              '🔄 반복 구매 활용',
              '자주 사는 항목은 "즐겨찾기"에 추가하면 다음에 빠르게 장바구니에 담을 수 있습니다.',
            ),
            const Divider(height: 24),
            _buildTipItem(
              '⏰ 유통기한 알림',
              '재고 관리와 연동되어 먼저 써야 할 재료가 있으면 알림을 받습니다. 음식물 낭비 제로!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
        ),
      ],
    );
  }
}
