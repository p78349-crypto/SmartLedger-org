import 'package:flutter/material.dart';
import 'package:smart_ledger/services/smart_app_controller.dart';

/// 통합 음성 명령 화면
///
/// "편의점 우유 3000원 입력하고 쿠팡에서 우유 검색"
/// → 가계부 입력 + 쿠팡 앱 자동 실행
class SmartVoiceCommandScreen extends StatefulWidget {
  final String accountName;

  const SmartVoiceCommandScreen({super.key, required this.accountName});

  @override
  State<SmartVoiceCommandScreen> createState() =>
      _SmartVoiceCommandScreenState();
}

class _SmartVoiceCommandScreenState extends State<SmartVoiceCommandScreen> {
  final SmartAppController _controller = SmartAppController();
  final TextEditingController _textController = TextEditingController();

  bool _isProcessing = false;
  Map<String, dynamic>? _result;

  final List<String> _quickCommands = [
    '편의점 우유 3000원 입력하고 쿠팡에서 우유 검색',
    '배민에서 치킨 주문',
    '카카오맵으로 강남역 가는 길',
    '사과 5000원 입력',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 스마트 음성 명령'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // 설명 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.withAlpha(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      '말 한마디로 모든 앱 제어',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '가계부 입력 + 쇼핑앱/배달앱 자동 실행',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // 입력 영역
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '명령을 입력하세요\n예: "편의점 우유 3000원 입력하고 쿠팡에서 우유 검색"',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isProcessing ? null : _processCommand,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processCommand,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mic),
                    label: Text(_isProcessing ? '처리 중...' : '음성 명령 실행'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 빠른 명령
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '빠른 명령',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickCommands.map((cmd) {
                    return ActionChip(
                      label: Text(cmd, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        _textController.text = cmd;
                        _processCommand();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 결과 표시
          if (_result != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result!.containsKey('error')
                      ? Colors.red.withAlpha(20)
                      : Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result!.containsKey('error')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _result!.containsKey('error')
                                ? Icons.error
                                : Icons.check_circle,
                            color: _result!.containsKey('error')
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _result!.containsKey('error') ? '실패' : '성공',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_result!.containsKey('error'))
                        Text(
                          _result!['error'],
                          style: const TextStyle(color: Colors.red),
                        )
                      else
                        ..._buildResultDetails(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildResultDetails() {
    final results = _result!['results'] as Map<String, dynamic>? ?? {};
    final widgets = <Widget>[];

    if (results.containsKey('record')) {
      widgets.add(
        _buildResultItem(
          icon: Icons.save,
          title: '가계부 입력',
          subtitle: results['record'] == true ? '✅ 저장 완료' : '❌ 저장 실패',
          color: Colors.blue,
        ),
      );
    }

    if (results.containsKey('shopping')) {
      widgets.add(
        _buildResultItem(
          icon: Icons.shopping_cart,
          title: '쇼핑앱 실행',
          subtitle: results['shopping'] == true ? '✅ 앱 실행됨' : '❌ 실행 실패',
          color: Colors.orange,
        ),
      );
    }

    if (results.containsKey('delivery')) {
      widgets.add(
        _buildResultItem(
          icon: Icons.delivery_dining,
          title: '배달앱 실행',
          subtitle: results['delivery'] == true ? '✅ 앱 실행됨' : '❌ 실행 실패',
          color: Colors.purple,
        ),
      );
    }

    if (results.containsKey('navigation')) {
      widgets.add(
        _buildResultItem(
          icon: Icons.map,
          title: '지도앱 실행',
          subtitle: results['navigation'] == true ? '✅ 앱 실행됨' : '❌ 실행 실패',
          color: Colors.green,
        ),
      );
    }

    return widgets;
  }

  Widget _buildResultItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processCommand() async {
    final command = _textController.text.trim();
    if (command.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    try {
      final result = await _controller.processCommand(
        command,
        widget.accountName,
      );

      setState(() {
        _result = result;
        _isProcessing = false;
      });

      if (!result.containsKey('error')) {
        _textController.clear();
      }
    } catch (e) {
      setState(() {
        _result = {'error': '처리 중 오류: $e'};
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
