part of 'voice_dashboard_screen.dart';

extension VoiceDashboardUI on _VoiceDashboardScreenState {
  Widget _buildVoiceGuideCard(ColorScheme colorScheme) {
    final currentGuide =
        _VoiceDashboardScreenState._voiceGuidePages[_selectedGuideIndex];
    final levelColor = Color(currentGuide.levelColorValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
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
            // 레벨 선택 탭 버튼
            Row(
              children: List.generate(
                _VoiceDashboardScreenState._voiceGuidePages.length,
                (index) {
                  final guide =
                      _VoiceDashboardScreenState._voiceGuidePages[index];
                  final color = Color(guide.levelColorValue);
                  final isSelected = _selectedGuideIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGuideIndex = index),
                      child: Container(
                        margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withValues(
                              alpha: isSelected ? 1.0 : 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              guide.levelEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              guide.level,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 선택된 가이드 콘텐츠
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
    required _VoiceGuideData guide,
    required Color levelColor,
    required ColorScheme colorScheme,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          // 제목
          Text(
            guide.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: levelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            guide.description,
            style: TextStyle(fontSize: 12, color: colorScheme.outline),
          ),
          const SizedBox(height: 10),
          // 예시 문장들
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: levelColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: levelColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          example,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 팁
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: levelColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  guide.tip,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection({
    required String title,
    required Color color,
    required List<_GuideItem> items,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildGuideItemTile(item, color, colorScheme)),
      ],
    );
  }

  Widget _buildGuideItemTile(
    _GuideItem item,
    Color color,
    ColorScheme colorScheme,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(VoiceCommandResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final isException =
        result.data != null && result.data!['isException'] == true;

    final icon = isException
        ? Icons.shield
        : (result.success ? Icons.check_circle : Icons.error);
    final color = isException
        ? Colors.amber.shade700
        : (result.success ? Colors.green : colorScheme.error);

    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        final isLatest =
            _recentResults.isNotEmpty && _recentResults.first == result;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLatest
                ? color.withValues(alpha: 0.1 * _feedbackAnimation.value)
                : (isException
                      ? Colors.amber.withValues(alpha: 0.05)
                      : colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(8),
            border: isException
                ? Border.all(color: Colors.amber, width: 1.5)
                : (isLatest
                      ? Border.all(color: color.withValues(alpha: 0.5))
                      : null),
            boxShadow: (isException && isLatest)
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: isException ? 24 : 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.message,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (result.data != null && result.data!['amount'] != null)
                      Text(
                        '${result.data!['description']} '
                        '• ${result.data!['category']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetCard(ColorScheme colorScheme) {
    final remaining = _todayBudget - _todaySpent;
    final isOver = remaining < 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1단계: 현재 예산
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '현재 한 끼 예산',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  CurrencyFormatter.format(remaining.abs()),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isOver ? colorScheme.error : colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (isOver)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠️ 예산 초과!',
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // 2단계: 비용 분류
            Row(
              children: [
                Expanded(
                  child: _buildCostChip('🥬 식재료비', _foodExpense, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCostChip('📦 고정비', _fixedCost, Colors.orange),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3단계: 진행 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_todaySpent / _todayBudget).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  isOver ? colorScheme.error : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '사용: ${CurrencyFormatter.format(_todaySpent)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
                Text(
                  '예산: ${CurrencyFormatter.format(_todayBudget)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(ColorScheme colorScheme) {
    final isActive = _isListening || _isProcessing;
    final statusColor = isActive ? Colors.green : colorScheme.outline;
    final statusText = _isListening
        ? '🟢 듣고 있어요...'
        : _isProcessing
        ? '⏳ 처리 중...'
        : '⚪ 대기 중';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isListening)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (!_speechAvailable)
                Chip(
                  label: const Text('음성 인식 불가'),
                  backgroundColor: colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (_currentText.isNotEmpty || _lastRecognizedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentText.isNotEmpty
                          ? _currentText
                          : _lastRecognizedText,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '최근 음성 입력',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentResults.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mic_none,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '아래 마이크 버튼을 눌러 말해보세요',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recentResults.take(3).map(_buildResultTile),
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
              spacing: 8,
              runSpacing: 8,
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
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onTertiaryContainer,
          ),
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
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red : colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isListening
                                        ? Colors.red
                                        : colorScheme.primary)
                                    .withValues(alpha: 0.4),
                            blurRadius: _isListening ? 20 : 10,
                            spreadRadius: _isListening ? 5 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? '탭하여 중지' : '탭하여 말하기',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
