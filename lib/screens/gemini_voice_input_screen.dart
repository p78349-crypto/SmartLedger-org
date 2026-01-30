import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:smart_ledger/services/aicore_gemini_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'dart:async';

/// AICore (Gemini Nano)를 사용한 음성 영수증 입력 화면
/// 
/// 완전 오프라인 동작 - API 키 불필요
class GeminiVoiceInputScreen extends StatefulWidget {
  final String accountName;
  
  const GeminiVoiceInputScreen({
    super.key,
    required this.accountName,
  });

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
  
  /// AICore 사용 가능 여부 확인
  Future<void> _checkAICore() async {
    final available = await _aicore.isAvailable();
    setState(() => _aicoreAvailable = available);
    
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ AICore 사용 불가 (Android 14+ 필요)\n온라인 API로 대체됩니다'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _initializeAudio() async {
    final isSupported = await _audioRecorder.hasPermission();
    if (!isSupported && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다')),
      );
    }
  }
  
  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
  
  /// 음성 녹음 시작/중지
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // 녹음 중지
        final recordPath = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        
        // 자동 처리
        if (recordPath != null && recordPath.isNotEmpty) {
          await _processVoiceInput(recordPath);
        }
      } else {
        // 녹음 시작
        final isPermitted = await _audioRecorder.hasPermission();
        if (!isPermitted) {
          _showError('마이크 권한이 없습니다');
          return;
        }
        
        // 임시 파일 경로 생성
        final path = '${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _parsedData = null;
          _errorLogs = [];
        });
      }
    } catch (e) {
      _showError('녹음 오류: $e');
    }
  }
  
  /// 음성 입력 처리 (AICore Gemini Nano)
  Future<void> _processVoiceInput(String audioPath) async {
    setState(() => _isProcessing = true);
    
    try {
      // ⚡ AICore로 음성 처리 (완전 오프라인)
      // TODO: 실제 STT는 speech_to_text 패키지 사용
      // 여기서는 데모용 텍스트 사용
      const demoText = '마트에서 사과 2개 5000원 샀어';
      
      // 🌏 사용자 선호 언어로 자동 번역 (AICore Gemini Nano)
      // 한국에서 사용: 영어 → 한국어
      // 일본에서 사용: 한국어 → 일본어 / 영어 → 일본어
      final preferredLang = await AICoreGeminiService.getPreferredLanguage();
      final result = await _aicore.translateAndParse(
        demoText,
        targetLang: preferredLang,
      );
      
      setState(() {
        _parsedData = result;
        _isProcessing = false;
      });
      
      if (result.containsKey('error')) {
        _showError(result['error']);
      } else {
        _showConfirmDialog(result);
      }
    } catch (e) {
      _showError('처리 오류: $e');
      setState(() => _isProcessing = false);
    }
  }
  
  /// OCR 텍스트 입력
  void _showTextInputDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OCR 텍스트 입력'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '영수증 OCR 텍스트를 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _processTextInput(controller.text);
            },
            child: const Text('분석'),
          ),
        ],
      ),
    );
  }
  
  /// 텍스트 입력 처리 (AICore)
  Future<void> _processTextInput(String text) async {
    setState(() => _isProcessing = true);
    
    try {
      // ⚡ AICore로 OCR 텍스트 파싱 (완전 오프라인)
      final result = await _aicore.parseReceiptText(text);
      
      setState(() {
        _parsedData = result;
        _isProcessing = false;
      });
      
      if (result.containsKey('error')) {
        _showError(result['error']);
      } else {
        _showConfirmDialog(result);
      }
    } catch (e) {
      _showError('처리 오류: $e');
      setState(() => _isProcessing = false);
    }
  }
  
  /// 확인 다이얼로그
  void _showConfirmDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) {
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.8;
        final confidenceColor = confidence > 0.9
            ? Colors.green
            : confidence > 0.7
                ? Colors.orange
                : Colors.red;
        
        return AlertDialog(
          title: const Text('거래 기록 확인'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 신뢰도 표시
                Row(
                  children: [
                    const Text('신뢰도: '),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: confidenceColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 상점명
                Text(
                  '상점: ${data['store'] ?? '?'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // 날짜
                Text('날짜: ${data['date'] ?? '오늘'}'),
                const SizedBox(height: 12),
                
                // 항목 목록
                const Text('항목:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(data['items'] as List?)?.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    '• ${item['name']}: ${item['qty']}개 × ${item['unit_price']}원 = ${item['total']}원',
                  ),
                )) ?? [const Text('항목 없음')],
                
                const SizedBox(height: 12),
                
                // 합계
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('합계:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${data['total']}원',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('수정'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveTransaction(data);
              },
              child: const Text('✅ 저장'),
            ),
          ],
        );
      },
    );
  }
  
  /// 거래 저장
  Future<void> _saveTransaction(Map<String, dynamic> data) async {
    try {
      final items = (data['items'] as List?)?.map((i) => 
        i as Map<String, dynamic>
      ).toList() ?? [];
      
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.expense,
        description: data['store'] ?? '영수증',
        amount: (data['total'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        quantity: items.length,
        memo: 'Gemini Nano 자동 입력',
      );
      
      unawaited(
        TransactionService().addTransaction(
          widget.accountName,
          transaction,
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${data['store']} - ${data['total']}원 저장됨'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // 화면 초기화
      setState(() {
        _parsedData = null;
      });
    } catch (e) {
      _showError('저장 오류: $e');
    }
  }
  
  void _showError(String message) {
    setState(() => _errorLogs.add(message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
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
                        const Icon(Icons.check_circle, color: Colors.green, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          '${_parsedData!['store']} - ${_parsedData!['total']}원',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 32,
                  ),
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
                        const Text('최근 오류:', style: TextStyle(fontWeight: FontWeight.bold)),
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
  
  Widget _buildResultCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '파싱 결과',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        Text('상점: ${_parsedData!['store'] ?? '?'}'),
        Text('날짜: ${_parsedData!['date'] ?? '오늘'}'),
        const SizedBox(height: 12),
        const Text('항목:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...(_parsedData!['items'] as List?)?.map((item) =>
          Text('  • ${item['name']}: ${item['qty']}개 × ${item['unit_price']}원')
        ) ?? [],
        const SizedBox(height: 12),
        Text(
          '합계: ${_parsedData!['total']}원',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }
}
