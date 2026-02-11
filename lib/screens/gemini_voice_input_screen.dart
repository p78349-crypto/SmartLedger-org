import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:smart_ledger/services/aicore_gemini_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'dart:async';

part 'gemini_voice_input_screen_voice.dart';
part 'gemini_voice_input_screen_ui.dart';

/// AICore (Gemini Nano)를 사용한 음성 영수증 입력 화면
///
/// 완전 오프라인 동작 - API 키 불필요
class GeminiVoiceInputScreen extends StatefulWidget {
  final String accountName;

  const GeminiVoiceInputScreen({super.key, required this.accountName});

  @override
  State<GeminiVoiceInputScreen> createState() => _GeminiVoiceInputScreenState();
}

class _GeminiVoiceInputScreenState extends State<GeminiVoiceInputScreen> {
  late final AICoreGeminiService _aicore;
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _aicoreAvailable = false;
  Map<String, dynamic>? _parsedData;
  List<String> _errorLogs = [];

  @override
  void initState() {
    super.initState();
    _aicore = AICoreGeminiService();
    _checkAICore();
    _initializeAudio();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎙️ AI 음성 입력'),
        actions: [
          // AICore 상태 표시
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              avatar: Icon(
                _aicoreAvailable ? Icons.offline_bolt : Icons.cloud,
                size: 16,
                color: _aicoreAvailable ? Colors.green : Colors.orange,
              ),
              label: Text(
                _aicoreAvailable ? '오프라인' : '온라인',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _aicoreAvailable
                  ? Colors.green.withAlpha(30)
                  : Colors.orange.withAlpha(30),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AICore 상태 배너
            if (!_aicoreAvailable)
              Container(
                width: double.infinity,
                color: Colors.orange.withAlpha(30),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AICore 미지원 (Android 14+ 필요) - 온라인 API 사용 중',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 녹음 상태 표시
            Container(
              color: Colors.blue.withAlpha(10),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isRecording)
                    const Text(
                      '🎙️ 음성 입력 중...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    )
                  else if (_isProcessing)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('분석 중...'),
                      ],
                    )
                  else if (_parsedData != null)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_parsedData!['store']} - ${_parsedData!['total']}원',
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
            ),

            const SizedBox(height: 32),

            // 메인 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 🎙️ 음성 입력
                FloatingActionButton.large(
                  onPressed: _isProcessing ? null : _toggleRecording,
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 32),
                ),

                // 📝 텍스트 입력
                FloatingActionButton.large(
                  onPressed: _isProcessing ? null : _showTextInputDialog,
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.edit, size: 32),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 파싱 결과
            if (_parsedData != null && !_parsedData!.containsKey('error'))
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildResultCard(),
                  ),
                ),
              ),

            // 에러 로그
            if (_errorLogs.isNotEmpty)
              Padding(
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
                        ..._errorLogs.map((log) => Text('• $log')),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
