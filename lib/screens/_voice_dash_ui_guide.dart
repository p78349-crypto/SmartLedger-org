// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 보이스 가이드 데이터 + 가이드 카드 + 가이드 콘텐츠 UI.
extension VoiceDashUiGuide on _VoiceDashboardScreenState {
  static const List<VoiceGuideData> _voiceGuidePages = [
    VoiceGuideData(
      level: '초급', levelEmoji: '🌱', levelColorValue: 0xFF4CAF50,
      title: '기본 지출 입력', description: '간단한 금액부터 시작해보세요!',
      examples: ['"지출 3,000원 입력해줘"', '"5천원 썼어"', '"점심 만원"'],
      tip: '금액만 말해도 자동으로 저장됩니다',
    ),
    VoiceGuideData(
      level: '중급', levelEmoji: '🌿', levelColorValue: 0xFFFF9800,
      title: '재료와 함께 입력', description: '무엇을 샀는지도 말해보세요!',
      examples: ['"팽이버섯 1봉 썼어"', '"달걀 한판 6천원"', '"양파 2개 천원"'],
      tip: '재료 이름을 말하면 식비로 자동 분류!',
    ),
    VoiceGuideData(
      level: '고급', levelEmoji: '🌳', levelColorValue: 0xFF9C27B0,
      title: '스마트 메뉴 추천', description: '남은 재료와 예산으로 메뉴 추천!',
      examples: ['"오늘 남은 재료로 메뉴 추천해줘"', '"3천원으로 뭐 만들지?"', '"냉장고에 뭐 있어?"'],
      tip: '유통기한 임박 재료를 우선 추천해요',
    ),
    VoiceGuideData(
      level: '마스터', levelEmoji: '👑', levelColorValue: 0xFFFFA000,
      title: '복합 명령', description: '여러 작업을 한 번에!',
      examples: ['"두부 천원 쓰고 장바구니에서 빼줘"', '"예산 확인하고 메뉴 추천해줘"', '"오늘 뭐 썼는지 알려줘"'],
      tip: '자연스럽게 대화하듯 말해보세요',
    ),
  ];

  Widget _buildVoiceGuideCard(ColorScheme colorScheme) {
    final currentGuide = _voiceGuidePages[_selectedGuideIndex];
    final levelColor = Color(currentGuide.levelColorValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '🎓 보이스 가이드',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showFullVoiceGuide,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('전체보기'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_voiceGuidePages.length, (index) {
                final guide = _voiceGuidePages[index];
                final color = Color(guide.levelColorValue);
                final isSelected = _selectedGuideIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGuideIndex = index),
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(alpha: isSelected ? 1.0 : 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(guide.levelEmoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            guide.level,
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildGuideContent(
                key: ValueKey(_selectedGuideIndex),
                guide: currentGuide,
                levelColor: levelColor,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideContent({
    required Key key,
    required VoiceGuideData guide,
    required Color levelColor,
    required ColorScheme colorScheme,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            levelColor.withValues(alpha: 0.12),
            levelColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide.title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: levelColor),
          ),
          const SizedBox(height: 2),
          Text(guide.description, style: TextStyle(fontSize: 12, color: colorScheme.outline)),
          const SizedBox(height: 10),
          ...guide.examples.map(
            (example) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () {
                  final command = example.replaceAll('"', '');
                  _processVoiceCommand(command);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: levelColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_outline, size: 16, color: levelColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(example,
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: levelColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  guide.tip,
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: levelColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
