// ignore_for_file: invalid_use_of_protected_member
part of 'quick_stock_use_screen.dart';

/// Extension: speech-to-text & voice command parsing.
extension QuickStockVoice on _QuickStockUseBodyState {
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              if (_recognizedText.isNotEmpty) {
                _processVoiceInput(_recognizedText);
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  /// 음성 입력 처리 - Gemini Nano 우선 사용, 정규식 대체
  void _processVoiceInput(String text) async {
    bool nanoProcessed = false;

    // 1. Gemini Nano 파싱 시도 (온디바이스 전용)
    try {
      if (await _aicore.isAvailable()) {
        final result = await _aicore.processVoiceInput(text);
        if (result.containsKey('items')) {
          final items = result['items'] as List;
          if (items.isNotEmpty) {
            final first = items[0] as Map<String, dynamic>;
            final name = first['name']?.toString();
            final qty =
                (first['qty'] as num?)?.toDouble() ??
                (first['total'] as num?)?.toDouble() ??
                1.0;

            if (name != null && name.isNotEmpty && mounted) {
              _applyVoiceResult(name, qty);
              nanoProcessed = true;
              debugPrint('[Nano] 재고 파싱 성공: $name $qty');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Nano] 재고 파싱 오류: $e');
    }

    if (nanoProcessed) return;

    // 2. Fallback: 기존 정규식 파싱
    final parsed = _parseVoiceCommand(text);
    if (parsed != null && mounted) {
      _applyVoiceResult(
        parsed.productName,
        parsed.amount.toDouble(),
        unit: parsed.unit,
      );
    } else if (mounted) {
      _nameController.text = text;
      _onNameChanged();
    }
  }

  void _applyVoiceResult(String name, double amount, {String? unit}) {
    _nameController.text = name;
    _onNameChanged();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _amountController.text = _formatQty(amount);
      _entButtonFocus.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎤 "$name" ${_formatQty(amount)}${unit ?? '개'} 입력됨'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  /// 음성 명령 파싱: "팽이버섯 1봉", "달걀 한판", "양파 2개"
  _VoiceParsedResult? _parseVoiceCommand(String text) {
    final cleanText = text.trim().toLowerCase();
    if (cleanText.isEmpty) return null;

    final patterns = [
      RegExp(r'(.+?)\s*(\d+)\s*(봉|개|판|팩|단|모|롤|ml|g|L)'),
      RegExp(r'(.+?)\s*(한|두|세|네|다섯)\s*(봉|개|판|팩|단|모|롤)'),
      RegExp(r'(.+?)\s*(\d+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        var productName = match.group(1)?.trim() ?? '';
        var amountStr = match.group(2) ?? '1';
        final unit = match.groupCount >= 3 ? match.group(3) : null;

        amountStr = _convertKoreanNumber(amountStr);
        final amount = int.tryParse(amountStr) ?? 1;

        productName =
            productName.replaceAll(RegExp(r'[을를이가은는]$'), '').trim();

        if (productName.isNotEmpty) {
          return _VoiceParsedResult(
            productName: productName,
            amount: amount,
            unit: unit,
          );
        }
      }
    }

    final simpleMatch = RegExp(r'^([가-힣a-zA-Z]+)$').firstMatch(cleanText);
    if (simpleMatch != null) {
      return _VoiceParsedResult(
        productName: simpleMatch.group(1) ?? cleanText,
        amount: 1,
      );
    }

    return null;
  }

  String _convertKoreanNumber(String text) {
    const koreanNumbers = {
      '한': '1', '두': '2', '세': '3', '네': '4', '다섯': '5',
      '여섯': '6', '일곱': '7', '여덟': '8', '아홉': '9', '열': '10',
    };
    return koreanNumbers[text] ?? text;
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음성 인식을 사용할 수 없습니다')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords);
      },
      localeId: 'ko_KR',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  // ── Voice input card widget (used by build) ──
  Widget _buildVoiceInputCard(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: Colors.orange),
                SizedBox(width: 8),
                Text('상품명 입력 → 사용량 입력 → ENT',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isListening ? _stopListening : _startListening,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isListening ? Icons.stop : Icons.mic,
                      color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isListening
                          ? '듣는 중... "$_recognizedText"'
                          : '🎤 음성으로 입력하기',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            if (_speechAvailable) ...[
              const SizedBox(height: 4),
              Text('예: "팽이버섯 1봉", "달걀 한판"',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSecondaryContainer
                      .withValues(alpha: 0.7))),
            ],
          ],
        ),
      ),
    );
  }
}
