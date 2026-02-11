// ignore_for_file: invalid_use_of_protected_member
part of 'gemini_voice_input_screen.dart';

/// Voice recording, processing, and transaction save logic
extension GeminiVoiceInputVoice on _GeminiVoiceInputScreenState {
  /// AICore 사용 가능 여부 확인
  Future<void> _checkAICore() async {
    final available = await _aicore.isAvailable();
    setState(() => _aicoreAvailable = available);

    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ AICore 사용 불가 (Android 14+ 필요)\n온라인 API로 대체됩니다',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _initializeAudio() async {
    final isSupported = await _audioRecorder.hasPermission();
    if (!isSupported && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('마이크 권한이 필요합니다')));
    }
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

  /// 거래 저장
  Future<void> _saveTransaction(Map<String, dynamic> data) async {
    try {
      final items =
          (data['items'] as List?)
              ?.map((i) => i as Map<String, dynamic>)
              .toList() ??
          [];

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
        TransactionService().addTransaction(widget.accountName, transaction),
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
      SnackBar(content: Text('❌ $message'), backgroundColor: Colors.red),
    );
  }
}
