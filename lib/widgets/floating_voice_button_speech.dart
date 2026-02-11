// ignore_for_file: invalid_use_of_protected_member

part of 'floating_voice_button.dart';

/// 음성 인식, 듣기, 상시 대기 모드 관련 메서드
extension FloatingVoiceButtonSpeech on _FloatingVoiceButtonState {
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (mounted) {
            String userMsg = '음성 인식 오류가 발생했습니다';
            // 오프라인 음성 팩 관련 구체적 안내
            if (error.errorMsg.contains('error_network') ||
                error.errorMsg.contains('7')) {
              userMsg = '오프라인 언어 팩(한국어)이 설치되어 있는지 확인해주세요.';
            } else if (error.errorMsg.contains('error_no_match')) {
              userMsg = '잘 듣지 못했어요. 다시 말씀해주세요.';
            }

            setState(() {
              _isListening = false;
              _isProcessing = false;
              _soundLevel = 0;
            });
            _pulseController.stop();

            if (_isActiveMode) {
              // 상시 대기 모드라면 잠시 후 다시 시도하게 함 (무한 루프 방지)
            } else {
              _showResultMessage(false, userMsg);
            }
          }
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'notListening' || status == 'done') {
            if (mounted) {
              setState(() {
                _soundLevel = 0;
              });
              _pulseController.stop();

              // [핵심 로직] 엔진이 멈췄는데 아직 3.5초 침묵 타이머가 작동 중이라면,
              // 이는 시스템이 성급하게 종료한 것이므로 즉시 재시작하여 말을 끝까지 듣습니다.
              if (_isListening && _silenceTimer?.isActive == true) {
                debugPrint('[FloatingVoice] 시스템 성급 종료 감지: 다시 듣기 시작');
                _startListening(isRestart: true);
              }
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _startListening({bool isRestart = false}) async {
    if (!_speechAvailable) {
      _showResultMessage(false, '음성 인식을 사용할 수 없어요');
      return;
    }

    setState(() {
      _isListening = true;
      if (!isRestart) {
        _currentText = '말씀해 주세요...';
        _tempBuffer = '';
      }
      _showResult = false;
      _soundLevel = 0;
    });

    _pulseController.repeat(reverse: true);

    try {
      if (_speech.isListening) {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          final text = result.recognizedWords;
          // 재시작된 경우 이전 텍스트와 합쳐서 표시
          final displayScore =
              _tempBuffer.isEmpty ? text : '$_tempBuffer $text';

          setState(() {
            if (displayScore.isNotEmpty) {
              _currentText = displayScore;
              // 햅틱 피드백으로 생동감 부여
              HapticFeedback.selectionClick();
            }
          });

          // 핵심: 시스템의 finalResult와 별개로,
          // 텍스트가 들어오면 타이머를 리셋하여 '진짜 침묵'을 감지합니다.
          _silenceTimer?.cancel();

          if (text.isNotEmpty) {
            // 사용자가 말을 멈추고 3.5초가 지나면 "진짜 끝"으로 간주하고 처리 시작
            _silenceTimer = Timer(const Duration(milliseconds: 3500), () {
              if (mounted && _currentText.isNotEmpty) {
                debugPrint('[FloatingVoice] 3.5초 침묵 감지: 최종 처리 시작');
                _handleVoiceCommand(_currentText);
              }
            });
          }

          // 시스템이 명확하게 말이 끝났다고 판단했을 때 (시스템 endpoint)
          if (result.finalResult && text.isNotEmpty) {
            _silenceTimer?.cancel(); // 타이머 중복 방지
            debugPrint('[FloatingVoice] 시스템 최종 감지 완료: "$displayScore"');

            // 시스템이 끝났다고 판단하면, 일단 버퍼에 저장해둡니다 (재시작 가능성 대비)
            _tempBuffer = displayScore;

            // 1.5초 후에도 추가 입력(재시작에 의한)이 없다면 처리 시작
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && _currentText == displayScore) {
                _handleVoiceCommand(displayScore);
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() {
              _soundLevel = level;
            });
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 15),
        localeId: 'ko_KR',
        listenOptions: stt.SpeechListenOptions(
          onDevice: true, // 오프라인 인식 우선 사용
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('Listening error: $e');
      _showResultMessage(false, '음성 인식에 실패했어요');
    }
  }

  void _startActiveMode() {
    _isActiveMode = true;
    // 1초마다 남은 시간 체크
    _activeModeTicker?.cancel();
    _activeModeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_settings.isActiveListenEnabled) {
        _stopActiveMode();
        return;
      }
      setState(() {}); // 남은 시간 표시 갱신
      // 듣고 있지 않고 처리 중도 아니면 자동 시작
      if (!_isListening && !_isProcessing) {
        _startListening();
      }
    });
    // 즉시 듣기 시작
    if (!_isListening && !_isProcessing) {
      _startListening();
    }
    setState(() {});
  }

  void _stopActiveMode() {
    _isActiveMode = false;
    _activeModeTicker?.cancel();
    _activeModeTicker = null;
    if (_isListening) {
      _speech.stop();
    }
    setState(() {});
  }

  void _onButtonTap() {
    if (_isProcessing) return;

    HapticFeedback.mediumImpact();

    // 임시 데이터 초기화
    _tempExpenseItem = null;
    _tempExpensePrice = null;
    _currentStep = 'idle';

    // 듣는 중이면 수동 종료
    if (_isListening) {
      _stopAndExit();
      return;
    }

    // 대화 시작: 먼저 인사
    _startConversation();
  }

  /// 대화 시작 - Google Assistant 스타일
  Future<void> _startConversation() async {
    setState(() {
      _isProcessing = true;
      _currentStep = 'confirm_start';
      _currentText = '무엇을 도와드릴까요?';
    });

    await _speak('네, 무엇을 도와드릴까요?');

    // TTS 종료 후 오디오 세션 전환을 위한 미세한 지연
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      _isProcessing = false;
    });

    _startListening();
  }

  /// 완전 종료
  void _stopAndExit() {
    _silenceTimer?.cancel();
    _speech.stop();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isListening = false;
      _currentText = '';
    });
  }

  void _showResultMessage(bool success, String message) {
    setState(() {
      _isProcessing = false;
      _showResult = true;
      _resultSuccess = success;
      _resultMessage = message;
    });

    // 3초 후 자동 숨김
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showResult = false;
        });
      }
    });
  }
}
