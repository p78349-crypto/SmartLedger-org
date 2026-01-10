import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'voice_dashboard_screen.dart';
import '../services/deep_link_diagnostics.dart';
import '../services/assistant_launcher.dart';

/// 음성 어시스턴트 단축어 설정 및 안내 화면
class VoiceShortcutsScreen extends StatefulWidget {
  const VoiceShortcutsScreen({super.key});

  @override
  State<VoiceShortcutsScreen> createState() => _VoiceShortcutsScreenState();
}

class _VoiceShortcutsScreenState extends State<VoiceShortcutsScreen> {
  late Future<DeepLinkDiagnosticsEntry?> _lastDeepLinkFuture;

  @override
  void initState() {
    super.initState();
    _refreshLastDeepLink();
  }

  void _refreshLastDeepLink() {
    _lastDeepLinkFuture = DeepLinkDiagnostics.getLast();
  }

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
                    '앱 안에서 음성으로 빠르게 화면을 열고\n입력까지 이어갈 수 있습니다.',
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
                          builder: (_) => const VoiceDashboardScreen(
                            autoStartListening: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard),
                    label: const Text('🎙️ 음성 제어 대시보드 열기(자동 시작)'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '※ 외부 어시스턴트(Bixby/Google/Siri)는 기기/설정에 따라\n앱 실행까지만 되고 화면 제어가 안 될 수 있어요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 사용 가능한 명령어 전체 목록
          _buildAllCommandsSection(context),

          const SizedBox(height: 16),

          // 고급(외부 어시스턴트/딥링크 진단) - 기본은 숨김
          _buildAdvancedSection(context, isAndroid: isAndroid, isIOS: isIOS),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(
    BuildContext context, {
    required bool isAndroid,
    required bool isIOS,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.build, color: theme.colorScheme.primary),
        title: const Text('고급/진단(선택)'),
        subtitle: const Text('외부 어시스턴트/딥링크 테스트 (필요할 때만)'),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              '외부 어시스턴트는 앱 내부 화면 제어가 제한적일 수 있습니다.\n'
              '필요한 경우에만 아래 설정/진단을 사용하세요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          if (isAndroid) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAssistantSection(
                context,
                title: 'Samsung Bixby(선택)',
                icon: Icons.record_voice_over,
                color: Colors.purple,
                shortcuts: _bixbyShortcuts,
                onSetup: () => _openBixbySettings(context),
                setupLabel: '설정 안내',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _openBixbyApp(context),
                      icon: const Icon(Icons.mic_external_on),
                      label: const Text('Bixby 열기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _openSystemAssistant(context),
                      icon: const Icon(Icons.assistant),
                      label: const Text('기본 어시스턴트'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isIOS) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAssistantSection(
                context,
                title: 'Siri(선택)',
                icon: Icons.mic,
                color: Colors.orange,
                shortcuts: _siriShortcuts,
                onSetup: () => _openSiriSettings(context),
                setupLabel: '설정 안내',
              ),
            ),
          ],

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDeepLinkTestCard(context),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildDeepLinkRecentCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDeepLinkTestCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '딥링크 테스트',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'OS 인텐트로 smartledger://... 딥링크를 실행합니다.\n'
              '외부 어시스턴트가 URL을 제대로 전달하는지 확인할 때 사용하세요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _runDeepLinkTest(
                    context,
                    'smartledger://transaction/add?type=expense&amount=5000&description=딥링크테스트',
                  ),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('거래추가'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _runDeepLinkTest(
                    context,
                    'smartledger://nav/open?route=/settings',
                  ),
                  icon: const Icon(Icons.settings),
                  label: const Text('설정 열기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepLinkRecentCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '최근 딥링크 수신',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: () {
                    setState(_refreshLastDeepLink);
                  },
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: '기록 지우기',
                  onPressed: () async {
                    await DeepLinkDiagnostics.clear();
                    if (!mounted) return;
                    setState(_refreshLastDeepLink);
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<DeepLinkDiagnosticsEntry?>(
              future: _lastDeepLinkFuture,
              builder: (context, snapshot) {
                final entry = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }
                if (entry == null) {
                  return Text(
                    '아직 수신 기록이 없습니다.\n외부에서 URL을 실행한 뒤 새로고침하세요.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '시간: ${entry.receivedAt}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          entry.parsed
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 18,
                          color:
                              entry.parsed ? Colors.green : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.parsed
                                ? (entry.actionSummary ?? '파싱 성공')
                                : '파싱 실패: ${entry.failureReason ?? "unknown"}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(entry.uri, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: entry.uri));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('최근 딥링크 URI 복사됨'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('URI 복사'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
5. 동작: URL 열기
   - 예시(지출 입력 화면): smartledger://transaction/add?type=expense
   - 예시(지출 입력+미리채움): smartledger://transaction/add?type=expense&amount=5000&description=커피
   - 예시(특정 화면 열기): smartledger://nav/open?route=/settings

※ "앱 열기"만 선택하면 앱은 켜지지만, 화면 이동/입력폼 진입은 안 될 수 있습니다.

🗣️ Bixby Routines 설정:
1. 설정 > 유용한 기능 > Bixby Routines
2. + 루틴 추가
3. 조건: 음성 명령
4. 동작: URL 열기 (위 예시 중 하나 입력)''',
    );
  }

  Future<void> _openSystemAssistant(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final ok = await AssistantLauncher.openSystemAssistant();
      if (ok != true && context.mounted) {
        _showSetupDialog(
          context,
          title: '어시스턴트 실행 실패',
          content:
              '기기에서 기본 어시스턴트를 실행할 수 없습니다.\n\n설정에서 기본 어시스턴트를 확인해주세요.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        _showSetupDialog(
          context,
          title: '어시스턴트 실행 실패',
          content:
              '어시스턴트를 여는 중 오류가 발생했습니다.\n\n설정에서 기본 어시스턴트를 확인해주세요.',
        );
      }
    }
  }

  Future<void> _openBixbyApp(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final ok = await AssistantLauncher.openBixby();
    if (ok) return;

    if (context.mounted) {
      _showSetupDialog(
        context,
        title: 'Bixby 실행 실패',
        content:
            '이 기기에서 Bixby 앱을 자동으로 찾지 못했습니다.\n\nBixby가 설치/활성화되어 있는지 확인해주세요.',
      );
    }
  }

  Future<void> _runDeepLinkTest(BuildContext context, String uri) async {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return;

    try {
      final ok = await launchUrl(
        parsed,
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '딥링크 실행됨 → 아래 “최근 딥링크 수신”에서 확인하세요'
                : '딥링크 실행 실패(이 기기에서 처리 앱 없음)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(_refreshLastDeepLink);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('딥링크 실행 중 오류 발생'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
