// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 최근 활동 카드 + 결과 타일 UI.
extension VoiceDashUiActivity on _VoiceDashboardScreenState {
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
                      Icon(Icons.mic_none, size: 48, color: colorScheme.outline),
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
                          fontSize: 12, color: colorScheme.outline,
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
}
