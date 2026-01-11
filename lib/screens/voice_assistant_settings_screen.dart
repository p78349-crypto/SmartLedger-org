import 'package:flutter/material.dart';

import '../services/voice_assistant_settings.dart';

/// 음성비서 설정 화면
/// 상시 대기 모드 시간 설정
class VoiceAssistantSettingsScreen extends StatefulWidget {
  const VoiceAssistantSettingsScreen({super.key});

  @override
  State<VoiceAssistantSettingsScreen> createState() =>
      _VoiceAssistantSettingsScreenState();
}

class _VoiceAssistantSettingsScreenState
    extends State<VoiceAssistantSettingsScreen> {
  final VoiceAssistantSettings _settings = VoiceAssistantSettings.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('음성비서 설정'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 설명 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mic, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '상시 대기 모드',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '요리 등으로 손을 쓸 수 없을 때 유용합니다.\n'
                    '설정한 시간 동안 터치 없이 음성만으로 지출을 기록할 수 있습니다.\n'
                    '시간이 지나면 자동으로 터치 모드로 돌아갑니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 현재 상태
          if (_settings.isActiveListenEnabled) ...[
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '상시 대기 중',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                          Text(
                            _settings.remainingTimeString,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: _settings.stopActiveListening,
                      child: const Text('중지'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 시간 선택
          Text(
            '대기 시간 설정',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '선택한 시간 동안 음성비서가 자동으로 듣습니다',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // 시간 옵션 그리드
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: VoiceAssistantSettings.durationOptions.map((minutes) {
              final isSelected = _settings.activeListenDuration == minutes;
              return _buildDurationOption(
                context,
                minutes: minutes,
                isSelected: isSelected,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 시작 버튼
          if (_settings.activeListenDuration > 0 &&
              !_settings.isActiveListenEnabled)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  _settings.startActiveListening();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${VoiceAssistantSettings.getDurationLabel(_settings.activeListenDuration)} 동안 상시 대기 시작',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  '${VoiceAssistantSettings.getDurationLabel(_settings.activeListenDuration)} 상시 대기 시작',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

          const SizedBox(height: 32),

          // 안내 사항
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '사용 팁',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 🎤 버튼이 보라색으로 변하면 상시 대기 중\n'
                    '• 버튼 아래에 남은 시간이 표시됩니다\n'
                    '• 버튼을 길게 누르면 즉시 중지됩니다\n'
                    '• 배터리 소모가 증가할 수 있습니다',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(
    BuildContext context, {
    required int minutes,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final label = VoiceAssistantSettings.getDurationLabel(minutes);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _settings.setDuration(minutes),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
