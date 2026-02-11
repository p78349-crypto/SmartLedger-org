// ignore_for_file: invalid_use_of_protected_member

part of 'floating_voice_button.dart';

/// UI 위젯 빌더 메서드
extension FloatingVoiceButtonUI on _FloatingVoiceButtonState {
  /// 구글 어시스턴트 스타일의 하단 UI
  Widget _buildGoogleStyleAssistantUI() {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 구글 컬러 웨이브/바
          _buildColorfulWaves(),
          const SizedBox(height: 20),

          // 현재 텍스트 (사용자 입력 또는 비서 질문)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _currentText,
              key: ValueKey(_currentText),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // 진행 상태 안내
          Text(
            _isProcessing
                ? '생각 중...'
                : (_isSpeaking ? '알려드려요' : '듣고 있어요'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (_tempExpenseItem != null || _tempExpensePrice != null) ...[
            const SizedBox(height: 20),
            _buildExtractedDataChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildColorfulWaves() {
    // 4가지 구글 시그니처 컬러
    final colors = [
      Colors.blue[400]!,
      Colors.red[400]!,
      Colors.yellow[600]!,
      Colors.green[400]!,
    ];

    return SizedBox(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          double level = 8.0;
          if (_isListening) {
            level =
                (_soundLevel * (1.0 - (index * 0.1))).clamp(2.0, 10.0) * 2.5;
          } else if (_isSpeaking || _isProcessing) {
            // 말하거나 처리 중일 때는 일정한 속도로 물결침
            level = 8.0 + (5.0 * (1.0 + (index * 0.2)));
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 8,
            height: level,
            decoration: BoxDecoration(
              color: colors[index],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExtractedDataChips() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      children: [
        if (_tempExpenseItem != null)
          Chip(
            avatar: const Icon(Icons.shopping_bag, size: 16),
            label: Text(_tempExpenseItem!),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
        if (_tempExpensePrice != null)
          Chip(
            avatar: const Icon(Icons.payments, size: 16),
            label: Text(_tempExpensePrice!),
            backgroundColor: theme.colorScheme.tertiaryContainer,
          ),
      ],
    );
  }

  /// 상시 대기 모드 중지 (길게 누르기)
  void _onLongPressStopActive() {
    HapticFeedback.heavyImpact();
    _settings.stopActiveListening();
    _showResultMessage(true, '상시 대기 모드 종료');
  }

  Widget _buildActiveModeBadge() {
    final theme = Theme.of(context);
    final remaining = _settings.remainingTimeString;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 12,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            remaining,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    final theme = Theme.of(context);
    final isActive = _isActiveMode && _settings.isActiveListenEnabled;

    // 상태별 디자인 설정
    final Color buttonColor;
    final IconData buttonIcon;
    final Color iconColor;
    final shouldPulse = _isListening || _isSpeaking;

    if (_isSpeaking) {
      buttonColor = theme.colorScheme.primary;
      buttonIcon = Icons.volume_up;
      iconColor = Colors.white;
    } else if (_isListening) {
      buttonColor = theme.colorScheme.error;
      buttonIcon = Icons.mic;
      iconColor = Colors.white;
    } else if (isActive) {
      buttonColor = theme.colorScheme.tertiary;
      buttonIcon = Icons.mic;
      iconColor = Colors.white;
    } else {
      buttonColor = theme.colorScheme.primaryContainer;
      buttonIcon = Icons.mic_none;
      iconColor = theme.colorScheme.primary;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: buttonColor,
        child: InkWell(
          onTap: _onButtonTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: shouldPulse
                    ? buttonColor
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(buttonIcon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      color: _resultSuccess
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _resultSuccess ? Icons.check_circle : Icons.error,
              color: _resultSuccess
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _resultMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
