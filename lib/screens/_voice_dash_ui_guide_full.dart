// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 전체 보이스 가이드 다이얼로그.
extension VoiceDashUiGuideFull on _VoiceDashboardScreenState {
  void _showFullVoiceGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        '🎓 보이스 가이드 - 완전 정복!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGuideSection(
                        title: '🌱 초급 - 첫 걸음', color: Colors.green,
                        items: const [
                          VoiceGuideItem(command: '지출 3,000원 입력해줘', description: '가장 기본적인 지출 입력', category: '기타'),
                          VoiceGuideItem(command: '5천원 썼어', description: '간단하게 금액만 말하기', category: '기타'),
                          VoiceGuideItem(command: '예산 얼마 남았어?', description: '오늘 남은 예산 확인', category: '조회'),
                          VoiceGuideItem(command: '오늘 얼마 썼어?', description: '오늘 지출 총액 확인', category: '조회'),
                        ],
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        title: '🌿 중급 - 스마트 기록', color: Colors.orange,
                        items: const [
                          VoiceGuideItem(command: '팽이버섯 1봉 썼어', description: '재료명 + 수량으로 기록', category: '식비 자동분류'),
                          VoiceGuideItem(command: '달걀 한판 6천원', description: '재료 + 금액 함께 기록', category: '식재료 자동분류'),
                          VoiceGuideItem(command: '남은 양파 얼마야?', description: '냉장고 재고 확인', category: '재료 조회'),
                          VoiceGuideItem(command: '우유 장바구니 추가', description: '장볼 목록에 추가', category: '장바구니'),
                        ],
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        title: '🌳 고급 - AI 활용', color: Colors.purple,
                        items: const [
                          VoiceGuideItem(command: '오늘 남은 재료로 메뉴 추천해줘', description: '유통기한 임박 재료 기반 추천', category: '메뉴 추천'),
                          VoiceGuideItem(command: '3천원으로 뭐 만들지?', description: '예산 맞춤 메뉴 추천', category: '메뉴 추천'),
                          VoiceGuideItem(command: '냉장고에 뭐 있어?', description: '전체 재료 현황 파악', category: '재고 조회'),
                          VoiceGuideItem(command: '이번 주 뭐 많이 썼어?', description: '지출 분석 요청', category: '분석'),
                        ],
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        title: '👑 마스터 - 복합 명령', color: Colors.amber.shade700,
                        items: const [
                          VoiceGuideItem(command: '두부 천원 쓰고 장바구니에서 빼줘', description: '지출 기록 + 장바구니 삭제', category: '복합'),
                          VoiceGuideItem(command: '예산 확인하고 메뉴 추천해줘', description: '조회 + 추천 한 번에', category: '복합'),
                          VoiceGuideItem(command: '어제 점심에 뭐 먹었지?', description: '과거 기록 조회', category: '이력 조회'),
                          VoiceGuideItem(command: '이번 달 식비 정리해줘', description: '월간 식비 분석', category: '분석'),
                        ],
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tips_and_updates, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                const Text('💡 꿀팁!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('• 마이크 버튼을 길게 누르면 계속 듣기 모드!'),
                            const SizedBox(height: 4),
                            const Text('• 예시 문장을 탭하면 바로 실행됩니다'),
                            const SizedBox(height: 4),
                            const Text('• 숫자는 "천원", "만원"처럼 자연스럽게 말해도 OK'),
                            const SizedBox(height: 4),
                            const Text('• 빅스비/시리에서도 같은 문장 사용 가능!'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
