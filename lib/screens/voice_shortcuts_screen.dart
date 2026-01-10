import 'package:flutter/material.dart';

import 'voice_dashboard_screen.dart';

/// 음성 안내 화면 - 간소화 버전
/// 음성 대시보드로 바로 이동하는 진입점
class VoiceShortcutsScreen extends StatelessWidget {
  const VoiceShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('음성 제어'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 마이크 아이콘
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // 제목
              Text(
                '음성으로 가계부 관리',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 설명
              Text(
                '화면의 🎤 버튼을 터치하고 말하세요\n숫자 없이 말하면 1개로 기록됩니다',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 예시 명령어
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💬 이렇게 말해보세요',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExample('"사과 10000원" → 사과 10,000원 기록'),
                      _buildExample('"커피" → 커피 1개 기록'),
                      _buildExample('"점심 5천원"'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const VoiceDashboardScreen(
                          autoStartListening: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mic),
                  label: const Text(
                    '음성 제어 시작',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExample(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
