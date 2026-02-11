// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 가이드 섹션/아이템 빌더 + 빠른 명령 + 마이크 버튼 + 도움말 UI.
extension VoiceDashUiBottom on _VoiceDashboardScreenState {
  Widget _buildGuideSection({
    required String title,
    required Color color,
    required List<VoiceGuideItem> items,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildGuideItemTile(item, color, colorScheme)),
      ],
    );
  }

  Widget _buildGuideItemTile(
    VoiceGuideItem item, Color color, ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _processVoiceCommand(item.command);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.mic, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${item.command}"',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.category,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCommandsCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, size: 20, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                const Text(
                  '⚡ 빠른 명령',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _buildCommandChip('💰 예산 확인', colorScheme),
                _buildCommandChip('🍳 메뉴 추천', colorScheme),
                _buildCommandChip('🥬 재고 확인', colorScheme),
                _buildCommandChip('📊 오늘 지출', colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandChip(String text, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        String command;
        if (text.contains('예산')) {
          command = '예산 얼마 남았어?';
        } else if (text.contains('메뉴')) {
          command = '오늘 뭐 먹지?';
        } else if (text.contains('재고')) {
          command = '냉장고에 뭐 있어?';
        } else if (text.contains('지출')) {
          command = '오늘 얼마 썼어?';
        } else {
          command = text;
        }
        _processVoiceCommand(command);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: colorScheme.onTertiaryContainer),
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton(ColorScheme colorScheme, Size size) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              onLongPress: _startListening,
              onLongPressUp: _stopListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red : colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : colorScheme.primary)
                                .withValues(alpha: 0.4),
                            blurRadius: _isListening ? 20 : 10,
                            spreadRadius: _isListening ? 5 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 36, color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? '탭하여 중지' : '탭하여 말하기',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('음성 제어 도움말'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💰 지출 기록', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "팽이버섯 2천원 지출"'),
              Text('• "점심 만원 기록해"'),
              SizedBox(height: 12),
              Text('🔍 재료 조회', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "남은 양파 얼마야?"'),
              Text('• "달걀 있어?"'),
              SizedBox(height: 12),
              Text('📊 예산 확인', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "예산 얼마 남았어?"'),
              Text('• "오늘 얼마 썼어?"'),
              SizedBox(height: 12),
              Text('🍳 메뉴 추천', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "오늘 뭐 먹지?"'),
              Text('• "메뉴 추천해줘"'),
              SizedBox(height: 12),
              Text('🛒 장바구니', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "우유 장바구니 추가"'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
