import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'voice_dashboard_screen.dart';

/// 음성 어시스턴트 단축어 설정 및 안내 화면
class VoiceShortcutsScreen extends StatelessWidget {
  const VoiceShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;

    return Scaffold(
      appBar: AppBar(title: const Text('음성 단축어'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 헤더 설명
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.mic, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    '음성으로 가계부를 관리하세요',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '음성 어시스턴트를 통해 빠르게 지출을 기록하고\n가계부 기능을 사용할 수 있습니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // 음성 대시보드 바로가기 버튼
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VoiceDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard),
                    label: const Text('🎙️ 음성 제어 대시보드 열기'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 플랫폼별 어시스턴트
          if (isAndroid) ...[
            _buildAssistantSection(
              context,
              title: 'Samsung Bixby',
              icon: Icons.record_voice_over,
              color: Colors.purple,
              shortcuts: _bixbyShortcuts,
              onSetup: () => _openBixbySettings(context),
              setupLabel: 'Bixby 설정 열기',
            ),
            const SizedBox(height: 16),
            _buildAssistantSection(
              context,
              title: 'Google Assistant',
              icon: Icons.assistant,
              color: Colors.blue,
              shortcuts: _googleShortcuts,
              onSetup: () => _openGoogleAssistant(context),
              setupLabel: 'Assistant 설정 열기',
            ),
          ],

          if (isIOS) ...[
            _buildAssistantSection(
              context,
              title: 'Siri',
              icon: Icons.mic,
              color: Colors.orange,
              shortcuts: _siriShortcuts,
              onSetup: () => _openSiriSettings(context),
              setupLabel: 'Siri 설정 열기',
            ),
          ],

          const SizedBox(height: 24),

          // 사용 가능한 명령어 전체 목록
          _buildAllCommandsSection(context),
        ],
      ),
    );
  }

  Widget _buildAssistantSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<VoiceShortcut> shortcuts,
    required VoidCallback onSetup,
    required String setupLabel,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                FilledButton.tonal(onPressed: onSetup, child: Text(setupLabel)),
              ],
            ),
          ),

          // 단축어 목록
          ...shortcuts.map(
            (shortcut) =>
                _buildShortcutTile(context, shortcut: shortcut, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutTile(
    BuildContext context, {
    required VoiceShortcut shortcut,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(shortcut.icon, color: color, size: 20),
      ),
      title: Text(
        shortcut.phrase,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        shortcut.description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 20),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: shortcut.phrase));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${shortcut.phrase}" 복사됨'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        tooltip: '명령어 복사',
      ),
    );
  }

  Widget _buildAllCommandsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.list_alt, color: theme.colorScheme.primary),
        title: const Text('모든 음성 명령어'),
        subtitle: const Text('사용 가능한 전체 명령어 목록'),
        children: [
          const Divider(height: 1),
          ..._allCommands.map(
            (cmd) => ListTile(
              dense: true,
              leading: Icon(cmd.icon, size: 20),
              title: Text(cmd.command),
              subtitle: Text(cmd.action),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _openBixbySettings(BuildContext context) {
    _showSetupDialog(
      context,
      title: 'Bixby 단축어 설정',
      content: '''삼성 기기에서 Bixby 단축어를 설정하세요.

📱 Quick Commands 설정:
1. Bixby 앱 열기
2. 메뉴 > Quick commands
3. + 버튼으로 새 명령어 추가
4. 명령어: "가계부 지출"
5. 동작: 앱 열기 > SmartLedger

🗣️ Bixby Routines 설정:
1. 설정 > 유용한 기능 > Bixby Routines
2. + 루틴 추가
3. 조건: 음성 명령
4. 동작: 앱 열기 > SmartLedger''',
    );
  }

  void _openGoogleAssistant(BuildContext context) {
    _showSetupDialog(
      context,
      title: 'Google Assistant 설정',
      content: '''Google Assistant로 SmartLedger를 제어하세요.

🎤 바로 사용하기:
"Hey Google, SmartLedger에서 지출 기록해"
"Hey Google, SmartLedger 열어"

⚙️ Routines 설정:
1. Google 앱 열기
2. 프로필 > 설정 > Google Assistant
3. Routines 선택
4. + 새 루틴 추가
5. 음성 명령과 SmartLedger 앱 열기 설정

💡 팁:
자주 사용하면 Google이 자동으로 추천해줍니다.''',
    );
  }

  void _openSiriSettings(BuildContext context) {
    _showSetupDialog(
      context,
      title: 'Siri 단축어 설정',
      content: '''iPhone에서 Siri 단축어를 설정하세요.

📱 설정 방법:
1. 설정 앱 열기
2. Siri 및 검색 선택
3. SmartLedger 앱 찾기
4. 단축어 확인 및 활성화

🗣️ 바로 사용하기:
"시리야, SmartLedger 지출 기록"
"시리야, SmartLedger 열어"
"시리야, SmartLedger 가계부 확인"

💡 팁:
앱을 한 번 실행하면 Siri가 자동으로 단축어를 학습합니다.''',
    );
  }

  void _showSetupDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

// 단축어 데이터 모델
class VoiceShortcut {
  final String phrase;
  final String description;
  final IconData icon;

  const VoiceShortcut({
    required this.phrase,
    required this.description,
    required this.icon,
  });
}

// 전체 명령어 모델
class VoiceCommand {
  final String command;
  final String action;
  final IconData icon;

  const VoiceCommand({
    required this.command,
    required this.action,
    required this.icon,
  });
}

// Bixby 단축어
const _bixbyShortcuts = [
  VoiceShortcut(
    phrase: '빅스비, 지출 기록해',
    description: '지출 입력 화면 열기',
    icon: Icons.remove_circle_outline,
  ),
  VoiceShortcut(
    phrase: '빅스비, 가계부 열어',
    description: '대시보드 열기',
    icon: Icons.dashboard,
  ),
  VoiceShortcut(
    phrase: '빅스비, 이번달 지출 확인',
    description: '지출 현황 보기',
    icon: Icons.pie_chart,
  ),
];

// Google Assistant 단축어
const _googleShortcuts = [
  VoiceShortcut(
    phrase: 'Hey Google, SmartLedger 지출 기록',
    description: '지출 입력 화면 열기',
    icon: Icons.remove_circle_outline,
  ),
  VoiceShortcut(
    phrase: 'Hey Google, SmartLedger 열어',
    description: '대시보드 열기',
    icon: Icons.dashboard,
  ),
  VoiceShortcut(
    phrase: 'Hey Google, SmartLedger 유통기한',
    description: '식재료 관리 열기',
    icon: Icons.kitchen,
  ),
];

// Siri 단축어
const _siriShortcuts = [
  VoiceShortcut(
    phrase: '시리야, SmartLedger 지출 기록',
    description: '지출 입력 화면 열기',
    icon: Icons.remove_circle_outline,
  ),
  VoiceShortcut(
    phrase: '시리야, SmartLedger 열어',
    description: '대시보드 열기',
    icon: Icons.dashboard,
  ),
  VoiceShortcut(
    phrase: '시리야, SmartLedger 가계부 확인',
    description: '지출 현황 보기',
    icon: Icons.pie_chart,
  ),
];

// 전체 명령어 목록
const _allCommands = [
  VoiceCommand(
    command: '지출 기록해 / 지출 입력',
    action: '지출 입력 화면 열기',
    icon: Icons.remove_circle_outline,
  ),
  VoiceCommand(
    command: '수입 기록해 / 월급 기록',
    action: '수입 입력 화면 열기',
    icon: Icons.add_circle_outline,
  ),
  VoiceCommand(
    command: '가계부 열어 / 대시보드',
    action: '메인 대시보드 열기',
    icon: Icons.dashboard,
  ),
  VoiceCommand(
    command: '이번달 지출 / 지출 현황',
    action: '지출 통계 보기',
    icon: Icons.pie_chart,
  ),
  VoiceCommand(
    command: '유통기한 확인 / 냉장고',
    action: '식재료 관리 열기',
    icon: Icons.kitchen,
  ),
  VoiceCommand(
    command: '장바구니 열어',
    action: '쇼핑 목록 열기',
    icon: Icons.shopping_cart,
  ),
  VoiceCommand(
    command: '레시피 추천 / 뭐 해먹지',
    action: '레시피 추천 열기',
    icon: Icons.restaurant_menu,
  ),
  VoiceCommand(
    command: '자산 현황 / 통장 확인',
    action: '자산 대시보드 열기',
    icon: Icons.account_balance,
  ),
  VoiceCommand(
    command: '저축 기록 / 적금',
    action: '저축 입력 화면 열기',
    icon: Icons.savings,
  ),
];
