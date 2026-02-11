// ignore_for_file: invalid_use_of_protected_member

part of 'floating_voice_button.dart';

/// 음성 명령 처리 및 Google NLU 분석
extension FloatingVoiceButtonCommands on _FloatingVoiceButtonState {
  /// 음성 명령 처리 - 완전한 Google Assistant 페르소나 (최종 통합)
  Future<void> _handleVoiceCommand(String text) async {
    // [중요] 다음 단계를 위해 엔진만 멈추고 UI는 유지함
    _silenceTimer?.cancel();
    _speech.stop();
    _pulseController.stop();
    _pulseController.reset();

    final lowerText = text.toLowerCase().trim();
    // 긍정/부정 응답 정밀 감지
    final isYes = _containsAny(lowerText, [
      '네',
      '응',
      '어',
      '그래',
      '좋아',
      '기록해',
      '맞아',
      '해줘',
      '저장',
      '기록',
      '확인',
    ]);
    final isNo = _containsAny(lowerText, [
      '아니',
      '됐어',
      '취소',
      '그만',
      '안 해',
      '틀려',
      '아냐',
    ]);

    // 단계별 구글 어시스턴트 로직
    switch (_currentStep) {
      case 'confirm_start':
        if (isYes) {
          _currentStep = 'ask_item';
          await _ensureQuickExpenseScreen();
          await _speak('네, 입력할 품목을 말씀해 주세요.');
          _startListening();
        } else if (isNo) {
          await _speak('알겠습니다. 더 필요하신 작업이 있으면 언제든 말씀해 주세요.');
          _currentStep = 'idle';
          _stopAndExit(); // 대화 종료 시에만 닫기
        } else {
          await _handleGoogleNlu(text);
        }
        break;

      case 'ask_open_expense':
        if (isYes) {
          await _speak('네, 지출 입력 화면을 열어 드릴게요.');
          await _ensureQuickExpenseScreen();
          _currentStep = 'ask_item';
          await _speak('이제 입력할 품목을 말씀해 주세요.');
          _startListening();
        } else if (isNo) {
          await _speak('알겠습니다. 지출 화면을 열지 않고 대화를 마칩니다.');
          _currentStep = 'idle';
          _stopAndExit();
        } else {
          await _handleGoogleNlu(text);
        }
        break;

      case 'ask_item':
        if (text.isNotEmpty) {
          _tempExpenseItem = text;
          // Skip explicit confirmation to speed up
          _currentStep = 'ask_price';
          VoiceInputBridge.instance.sendInput(_tempExpenseItem!);
          // Immediately ask for price instead of verifying item first
          await _speak('금액은 얼마인가요?');
          _startListening();
        }
        break;

      case 'ask_price':
        if (text.isNotEmpty) {
          _tempExpensePrice = text;
          _currentStep = 'confirm_all';
          final displayPrice = _tempExpensePrice!.contains('원')
              ? _tempExpensePrice!
              : '$_tempExpensePrice원';
          final combined = '$_tempExpenseItem $displayPrice';
          VoiceInputBridge.instance.sendInput(combined);
          await _speak('확인했습니다. $_tempExpenseItem, $displayPrice. 저장할까요?');
          _startListening();
        }
        break;

      case 'confirm_all':
        if (isYes) {
          await _speak('네, 지출 내역을 성공적으로 저장했습니다.');
          final finalLine = '$_tempExpenseItem $_tempExpensePrice';
          VoiceInputBridge.instance.sendInput(finalLine, submit: true);
          _currentStep = 'idle';
          _stopAndExit(); // 완료 후 닫기
        } else if (isNo) {
          await _speak('입력을 취소했습니다. 더 도와드릴 일이 있을까요?');
          _currentStep = 'idle';
          _stopAndExit();
        }
        break;

      default:
        await _handleGoogleNlu(text);
    }
  }

  /// Google NLU (자연어 이해) 스타일 분석 - 인사 및 데이터 즉시 추출
  Future<void> _handleGoogleNlu(String text) async {
    final lowerText = text.toLowerCase();

    // 1. Google 스타일의 인사 응답
    if (_containsAny(lowerText, ['안녕', '반가워', '누구니', '이름', '뭐해'])) {
      await _speak(
        '안녕하세요, 구글 어시스턴트 스타일의 가계부 비서입니다. '
        '지출을 입력하거나 통계를 확인하는 걸 도와드릴 수 있어요.',
      );
      _startListening();
      return;
    }

    // 2. Gemini Nano NLU 실행 (온디바이스 전용)
    bool nanoProcessed = false;
    if (await _aicore.isAvailable()) {
      setState(() => _isProcessing = true);
      try {
        final result = await _aicore.processVoiceInput(text);
        if (result.containsKey('items') &&
            (result['items'] as List).isNotEmpty) {
          final first = (result['items'] as List)[0] as Map<String, dynamic>;
          final item = first['name']?.toString();
          final total = first['total']?.toString();

          if (item != null || total != null) {
            _tempExpenseItem = item;
            _tempExpensePrice = total;
            nanoProcessed = true;
            debugPrint('[Nano] 파싱 성공: item=$item, price=$total');
          }
        }
      } catch (e) {
        debugPrint('[Nano] Floating Button NLU Error: $e');
      } finally {
        setState(() => _isProcessing = false);
      }
    }

    // 3. Fallback to regex (나노를 사용할 수 없거나 실패한 경우)
    if (!nanoProcessed) {
      final parsed = _parseExpense(text);
      _tempExpenseItem = parsed['item'];
      _tempExpensePrice = parsed['price'];
    }

    // 4. 지출/기록 의도 확인
    final isExpenseIntent = _containsAny(lowerText, [
      '지출',
      '기록',
      '돈',
      '썼',
      '결제',
      '구매',
      '샀',
    ]);

    if (isExpenseIntent ||
        _tempExpenseItem != null ||
        _tempExpensePrice != null) {
      // 품목이나 금액이 없이 "지출 입력할 거야" 수준의 의도만 있을 때
      if (_tempExpenseItem == null && _tempExpensePrice == null) {
        _currentStep = 'ask_open_expense';
        await _speak('지출 화면을 열어 드릴까요?');
        _startListening();
        return;
      }

      await _ensureQuickExpenseScreen();

      if (_tempExpenseItem != null && _tempExpensePrice != null) {
        _currentStep = 'confirm_all';
        // 가격에 '원'이 이미 포함되어 있는지 확인하여 중복 방지
        final displayPrice = _tempExpensePrice!.contains('원')
            ? _tempExpensePrice!
            : '$_tempExpensePrice원';
        final combined = '$_tempExpenseItem $displayPrice';
        VoiceInputBridge.instance.sendInput(combined);
        await _speak(
          '확인했습니다. $_tempExpenseItem, $displayPrice 저장할까요?',
        );
      } else if (_tempExpenseItem != null) {
        _currentStep = 'ask_price';
        VoiceInputBridge.instance.sendInput(_tempExpenseItem!);
        await _speak('네, $_tempExpenseItem(이)군요. 금액은 얼마인가요?');
      } else if (_tempExpensePrice != null) {
        _currentStep = 'ask_item';
        final displayPrice = _tempExpensePrice!.contains('원')
            ? _tempExpensePrice!
            : '$_tempExpensePrice원';
        VoiceInputBridge.instance.sendInput(displayPrice);
        await _speak('$displayPrice 확인했습니다. 어떤 상품인가요?');
      } else {
        _currentStep = 'ask_item';
        await _speak('네, 지출 내역을 기록하겠습니다. 품목은 무엇인가요?');
      }

      _startListening();
      return;
    }

    // 수입 기록 의도
    if (_containsAny(lowerText, ['수입', '입금', '월급', '받았'])) {
      await _speak('알겠습니다. 수입 기록 화면을 열겠습니다.');
      await _navigateToIncomeInput();
      _stopAndExit(); // 목적지 이동 후 닫기
      return;
    }

    // 조회 의도
    if (_containsAny(lowerText, ['얼마', '통계', '내역', '확인'])) {
      await _speak('네, 통계 화면을 열어 드릴게요.');
      await _navigateToStats();
      _stopAndExit(); // 목적지 이동 후 닫기
      return;
    }

    // 이해 못함
    await _speak(
      '죄송합니다. 잘 이해하지 못했어요. '
      '지출 기록 또는 조회를 도와드릴 수 있습니다.',
    );
    _startListening();
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
