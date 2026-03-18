import 'package:flutter/material.dart';

/// 상시 대기 모드 남은 시간 배지
class ActiveModeBadge extends StatelessWidget {
  const ActiveModeBadge({super.key, required this.remainingTimeString});

  final String remainingTimeString;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
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
            remainingTimeString,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 플로팅 마이크 버튼
class FloatingMicButton extends StatelessWidget {
  const FloatingMicButton({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.isActiveMode,
    required this.isActiveListenEnabled,
    required this.pulseAnimation,
    required this.onTap,
  });

  final bool isListening;
  final bool isSpeaking;
  final bool isActiveMode;
  final bool isActiveListenEnabled;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = isActiveMode && isActiveListenEnabled;
    final shouldPulse = isListening || isSpeaking;

    final Color buttonColor;
    final IconData buttonIcon;
    final Color iconColor;

    if (isSpeaking) {
      buttonColor = theme.colorScheme.primary;
      buttonIcon = Icons.volume_up;
      iconColor = Colors.white;
    } else if (isListening) {
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
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: buttonColor,
        child: InkWell(
          onTap: onTap,
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
}

/// 음성 결과 카드
class VoiceResultCard extends StatelessWidget {
  const VoiceResultCard({
    super.key,
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 8,
      color: success
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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
