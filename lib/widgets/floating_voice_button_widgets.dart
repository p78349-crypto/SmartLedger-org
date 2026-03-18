import 'package:flutter/material.dart';

/// Google 어시스턴트 스타일 하단 패널
class VoiceAssistantPanel extends StatelessWidget {
  const VoiceAssistantPanel({
    super.key,
    required this.currentText,
    required this.isProcessing,
    required this.isSpeaking,
    required this.isListening,
    required this.soundLevel,
    this.tempExpenseItem,
    this.tempExpensePrice,
  });

  final String currentText;
  final bool isProcessing;
  final bool isSpeaking;
  final bool isListening;
  final double soundLevel;
  final String? tempExpenseItem;
  final String? tempExpensePrice;

  @override
  Widget build(BuildContext context) {
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
          ColorfulWaveIndicator(
            isListening: isListening,
            isSpeaking: isSpeaking,
            isProcessing: isProcessing,
            soundLevel: soundLevel,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              currentText,
              key: ValueKey(currentText),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isProcessing ? '생각 중...' : (isSpeaking ? '알려드려요' : '듣고 있어요'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (tempExpenseItem != null || tempExpensePrice != null) ...[
            const SizedBox(height: 20),
            ExtractedDataChips(
              tempExpenseItem: tempExpenseItem,
              tempExpensePrice: tempExpensePrice,
            ),
          ],
        ],
      ),
    );
  }
}

/// 4색 구글 시그니처 웨이브 인디케이터
class ColorfulWaveIndicator extends StatelessWidget {
  const ColorfulWaveIndicator({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.isProcessing,
    required this.soundLevel,
  });

  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final double soundLevel;

  @override
  Widget build(BuildContext context) {
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
          if (isListening) {
            level = (soundLevel * (1.0 - (index * 0.1))).clamp(2.0, 10.0) * 2.5;
          } else if (isSpeaking || isProcessing) {
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
}

/// 추출된 지출 데이터 칩
class ExtractedDataChips extends StatelessWidget {
  const ExtractedDataChips({
    super.key,
    this.tempExpenseItem,
    this.tempExpensePrice,
  });

  final String? tempExpenseItem;
  final String? tempExpensePrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      children: [
        if (tempExpenseItem != null)
          Chip(
            avatar: const Icon(Icons.shopping_bag, size: 16),
            label: Text(tempExpenseItem!),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
        if (tempExpensePrice != null)
          Chip(
            avatar: const Icon(Icons.payments, size: 16),
            label: Text(tempExpensePrice!),
            backgroundColor: theme.colorScheme.tertiaryContainer,
          ),
      ],
    );
  }
}
