import 'package:flutter/material.dart';

/// AICore 상태 칩 (AppBar용)
class AICoreStatusChip extends StatelessWidget {
  final bool aicoreAvailable;

  const AICoreStatusChip({super.key, required this.aicoreAvailable});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Chip(
        avatar: Icon(
          aicoreAvailable ? Icons.offline_bolt : Icons.cloud,
          size: 16,
          color: aicoreAvailable ? Colors.green : Colors.orange,
        ),
        label: Text(
          aicoreAvailable ? '오프라인' : '온라인',
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: aicoreAvailable
            ? Colors.green.withAlpha(30)
            : Colors.orange.withAlpha(30),
      ),
    );
  }
}

/// AICore 미지원 경고 배너
class AICoreStatusBanner extends StatelessWidget {
  const AICoreStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withAlpha(30),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AICore 미지원 (Android 14+ 필요) - 온라인 API 사용 중',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

/// 녹음 상태 표시 위젯
class RecordingStatusDisplay extends StatelessWidget {
  final bool isRecording;
  final bool isProcessing;
  final Map<String, dynamic>? parsedData;

  const RecordingStatusDisplay({
    super.key,
    required this.isRecording,
    required this.isProcessing,
    this.parsedData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.withAlpha(10),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isRecording)
            const Text(
              '🎙️ 음성 입력 중...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            )
          else if (isProcessing)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('분석 중...'),
              ],
            )
          else if (parsedData != null)
            Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 40),
                const SizedBox(height: 8),
                Text(
                  '${parsedData!['store']} - ${parsedData!['total']}원',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            const Text('마이크를 누르고 말씀해주세요'),
        ],
      ),
    );
  }
}

/// 음성/텍스트 입력 버튼
class VoiceInputActionButtons extends StatelessWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onToggleRecording;
  final VoidCallback onTextInput;

  const VoiceInputActionButtons({
    super.key,
    required this.isRecording,
    required this.isProcessing,
    required this.onToggleRecording,
    required this.onTextInput,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 🎙️ 음성 입력
        FloatingActionButton.large(
          heroTag: 'voiceRecordBtn',
          onPressed: isProcessing ? null : onToggleRecording,
          backgroundColor: isRecording ? Colors.red : Colors.blue,
          child: Icon(isRecording ? Icons.stop : Icons.mic, size: 32),
        ),
        // 📝 텍스트 입력
        FloatingActionButton.large(
          heroTag: 'textInputBtn',
          onPressed: isProcessing ? null : onTextInput,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.edit, size: 32),
        ),
      ],
    );
  }
}

/// 파싱 결과 카드
class VoiceInputResultCard extends StatelessWidget {
  final Map<String, dynamic> parsedData;

  const VoiceInputResultCard({super.key, required this.parsedData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '파싱 결과',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Text('상점: ${parsedData['store'] ?? '?'}'),
              Text('날짜: ${parsedData['date'] ?? '오늘'}'),
              const SizedBox(height: 12),
              const Text('항목:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(parsedData['items'] as List?)?.map(
                    (item) => Text(
                      '  • ${item['name']}: ${item['qty']}개 × ${item['unit_price']}원',
                    ),
                  ) ??
                  [],
              const SizedBox(height: 12),
              Text(
                '합계: ${parsedData['total']}원',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 에러 로그 카드
class ErrorLogCard extends StatelessWidget {
  final List<String> errorLogs;

  const ErrorLogCard({super.key, required this.errorLogs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.red.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '최근 오류:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...errorLogs.map((log) => Text('• $log')),
            ],
          ),
        ),
      ),
    );
  }
}
