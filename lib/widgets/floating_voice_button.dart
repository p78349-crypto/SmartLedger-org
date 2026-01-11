import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../navigation/app_routes.dart';
import '../navigation/global_navigator_key.dart';
import '../services/account_service.dart';
import '../services/voice_assistant_settings.dart';
import '../services/voice_input_bridge.dart';
import '../utils/pref_keys.dart';

/// 플로팅 음성 버튼 - 화면 가리지 않고 항상 떠있음
/// 터치하면 음성 인식 시작, 완료 후 자동 처리
/// 상시 대기 모드: 설정된 시간 동안 자동으로 계속 듣기
class FloatingVoiceButton extends StatefulWidget {
  final Widget child;
  final String accountName;

  const FloatingVoiceButton({
    super.key,
    required this.child,
    this.accountName = 'default',
  });

  @override
  State<FloatingVoiceButton> createState() => _FloatingVoiceButtonState();
}

class _FloatingVoiceButtonState extends State<FloatingVoiceButton>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final VoiceAssistantSettings _settings = VoiceAssistantSettings.instance;

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _showResult = false;
  Timer? _silenceTimer; // 명시적 침묵 감지 타이머
  String _currentText = '';
  String _tempBuffer = ''; // 엔진 재시작 시 텍스트 보관용
  String _resultMessage = '';
  bool _resultSuccess = false;

  // 실시간 음성 강도 (0.0 ~ 10.0)
  double _soundLevel = 0.0;

  // 지출 데이터 임시 저장 (대화형)
  String? _tempExpenseItem;
  String? _tempExpensePrice;

  // 대화 단계 관리
  String _currentStep =
      'idle'; // idle, confirm_start, ask_item, confirm_item, ask_price, confirm_all

  // 상시 대기 모드
  bool _isActiveMode = false;
  Timer? _activeModeTicker;

  // 버튼 위치 (드래그 가능, 저장됨)
  // 초기값: 화면 오른쪽 중간 - 첫 실행 후 사용자가 이동하면 저장
  double? _buttonX;
  double? _buttonY;
  static const String _prefKeyX = 'floating_voice_btn_x';
  static const String _prefKeyY = 'floating_voice_btn_y';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadButtonPosition();
    _settings.addListener(_onSettingsChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 상시 대기 모드가 이미 활성화되어 있으면 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_settings.isActiveListenEnabled) {
        _startActiveMode();
      }
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(_settings.speechRate); // 설정값 사용
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // 말하기 끝날 때까지 기다리도록 설정
    await _tts.awaitSpeakCompletion(true);
  }

  /// 음성으로 텍스트 읽어주기 (끝날 때까지 기다림)
  Future<void> _speak(String text) async {
    if (mounted) {
      setState(() {
        _isSpeaking = true;
      });
    }
    await _tts.speak(text);
    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoHideTimer?.cancel();
    _activeModeTicker?.cancel();
    _speech.stop();
    _tts.stop();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      if (_settings.isActiveListenEnabled && !_isActiveMode) {
        _startActiveMode();
      } else if (!_settings.isActiveListenEnabled && _isActiveMode) {
        _stopActiveMode();
      }

      // Update TTS rate dynamically if changed
      _tts.setSpeechRate(_settings.speechRate);

      setState(() {});
    }
  }

  Future<void> _loadButtonPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_prefKeyX);
    final y = prefs.getDouble(_prefKeyY);
    if (mounted) {
      setState(() {
        _buttonX = x;
        _buttonY = y;
      });
    }
  }

  Future<void> _saveButtonPosition() async {
    if (_buttonX == null || _buttonY == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKeyX, _buttonX!);
    await prefs.setDouble(_prefKeyY, _buttonY!);
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
          final displayScore = _tempBuffer.isEmpty
              ? text
              : '$_tempBuffer $text';

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

  /// 구글 어시스턴트 전용 지출 화면 열기 보장
  Future<void> _ensureQuickExpenseScreen() async {
    // 앱 전체의 Navigator 상태(appNavigatorKey)를 사용하여 현재 경로 확인
    bool alreadyOnScreen = false;
    final navState = appNavigatorKey.currentState;

    if (navState != null) {
      navState.popUntil((route) {
        if (route.settings.name == AppRoutes.quickSimpleExpenseInput) {
          alreadyOnScreen = true;
        }
        return true; // 실제로 팝(pop)하지 않음
      });
    }

    if (!alreadyOnScreen) {
      await _goToQuickExpenseAndListen();
      // 화면이 열릴 때까지 충분한 시간 대기
      await Future.delayed(const Duration(milliseconds: 700));
    }
  }

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
          await _speak('네, 기록할 품목을 말씀해 주세요.');
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
          await _speak('이제 기록할 품목을 말씀해 주세요.');
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
          // Skip explicit confirmation to speed up and reduce "chat history" in input field
          _currentStep = 'ask_price';
          VoiceInputBridge.instance.sendInput(_tempExpenseItem!);
          // Immediately ask for price instead of verifying item first
          await _speak('금액은 얼마인가요?');
          _startListening();
        }
        break;

      /* 
      // Skipped step
      case 'confirm_item':
        ...
      */

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
          await _speak('네, 지출 내역을 성공적으로 기록했습니다.');
          final finalLine = '$_tempExpenseItem $_tempExpensePrice';
          VoiceInputBridge.instance.sendInput(finalLine, submit: true);
          _currentStep = 'idle';
          _stopAndExit(); // 완료 후 닫기
        } else if (isNo) {
          await _speak('기록을 취소했습니다. 더 도와드릴 일이 있을까요?');
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
        '안녕하세요, 구글 어시스턴트 스타일의 가계부 비서입니다. 지출을 기록하거나 통계를 확인하는 걸 도와드릴 수 있어요.',
      );
      _startListening();
      return;
    }

    // 2. 전체 문장에서 데이터 추출 시도 (슬롯 필링 방식)
    final parsed = _parseExpense(text);
    _tempExpenseItem = parsed['item'];
    _tempExpensePrice = parsed['price'];

    // 3. 지출/기록 의도 확인
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
        await _speak('확인했습니다. $_tempExpenseItem, $displayPrice 저장할까요?');
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
    await _speak('죄송합니다. 잘 이해하지 못했어요. 지출 기록 또는 조회를 도와드릴 수 있습니다.');
    _startListening();
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  /// 간단한 한글 지출 텍스트 파서 - 정확도 향상 및 복합 명사 처리
  Map<String, String?> _parseExpense(String text) {
    // 1. 의도와 상관없는 불필요한 단어 제거
    final cleanText = text
        .replaceAll(RegExp(r'(지출|기록|입력|저장|해줘|해|줘|좀|요|은|는|이|가|을|를)$'), '')
        .trim();

    // 2. 가격 패턴 추출 (단위: 십, 백, 천, 만 포함)
    // 3천5백원, 1만5000원 등의 복합 형태 대응
    final priceRegex = RegExp(r'(\d+[만천백십\d]*원?|[만천백십]+원?)');
    final matches = priceRegex.allMatches(cleanText).toList();

    String? price;
    String? item;

    if (matches.isNotEmpty) {
      // 기본적으로 마지막 매치를 가격으로 보되,
      // '원' 단위나 '만/천' 단위가 포함된 것을 우선적으로 찾음 (수량 '1개' 등과 구분)
      final bestMatch = matches.reversed.firstWhere((m) {
        final mText = m.group(0) ?? '';
        return mText.contains(RegExp(r'[원만천백십]')) ||
            (int.tryParse(mText.replaceAll(',', '')) ?? 0) >= 100;
      }, orElse: () => matches.last);

      price = bestMatch.group(0);
      // 복합 명사(사과만원) 처리를 위해 replaceFirst 사용
      item = cleanText
          .replaceFirst(price!, '')
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');

      if (item.isEmpty) item = null;
    } else {
      // 숫자가 없으면 전체를 품목 후보로 (단, 의도어만 있는 경우는 제외)
      final intentWords = ['지출', '기록', '돈', '썼', '결제', '구매', '샀'];
      final isOnlyIntent = intentWords.any((w) => cleanText == w);
      if (!isOnlyIntent && cleanText.isNotEmpty) {
        item = cleanText;
      }
    }

    return {'item': item, 'price': price};
  }

  /// 통계 화면으로 이동
  Future<void> _navigateToStats() async {
    final prefs = await SharedPreferences.getInstance();
    final accountName =
        prefs.getString(PrefKeys.selectedAccount)?.trim() ??
        AccountService().accounts.firstOrNull?.name ??
        '';
    if (mounted && accountName.isNotEmpty) {
      appNavigatorKey.currentState?.pushNamed(
        AppRoutes.periodStatsMonth,
        arguments: AccountArgs(accountName: accountName),
      );
    }
  }

  /// 수입 입력 화면으로 이동
  Future<void> _navigateToIncomeInput() async {
    final prefs = await SharedPreferences.getInstance();
    final accountName =
        prefs.getString(PrefKeys.selectedAccount)?.trim() ??
        AccountService().accounts.firstOrNull?.name ??
        '';

    if (mounted && accountName.isNotEmpty) {
      appNavigatorKey.currentState?.pushNamed(
        AppRoutes.transactionAddIncome,
        arguments: TransactionAddArgs(accountName: accountName),
      );
    }
  }

  /// 간편지출 화면 열고 음성 입력 대기 (대화형)
  Future<void> _goToQuickExpenseAndListen() async {
    // 계정 가져오기
    final prefs = await SharedPreferences.getInstance();
    final accountName =
        prefs.getString(PrefKeys.selectedAccount)?.trim() ??
        AccountService().accounts.firstOrNull?.name;

    if (accountName == null || accountName.isEmpty) {
      await _speak('계정을 먼저 생성해주세요');
      return;
    }

    // 간편지출 화면으로 이동 (빈 상태)
    if (mounted) {
      appNavigatorKey.currentState?.pushNamed(
        AppRoutes.quickSimpleExpenseInput,
        arguments: QuickSimpleExpenseInputArgs(
          accountName: accountName,
          initialDate: DateTime.now(),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 초기 위치: 화면 오른쪽 중간 (처음 실행 시)
    final buttonX = _buttonX ?? (screenSize.width - 56);
    final buttonY = _buttonY ?? (screenSize.height / 2 - 28);

    final isAssistantActive = _isListening || _isProcessing || _isSpeaking;

    return Stack(
      children: [
        widget.child,

        // 배경 어둡게 (어시스턴트 활성 시)
        if (isAssistantActive)
          GestureDetector(
            onTap: _stopAndExit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withValues(alpha: 0.4),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        // 결과 메시지 (하단)
        if (_showResult)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 80,
            child: _buildResultCard(),
          ),

        // 듣는 중 UI (하단 - 시스템 어시스턴트 스타일)
        if (isAssistantActive)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildGoogleStyleAssistantUI(),
          ),

        // 상시 대기 모드 남은 시간 표시
        if (_isActiveMode && _settings.isActiveListenEnabled)
          Positioned(
            left: buttonX - 10,
            top: buttonY + 50,
            child: _buildActiveModeBadge(),
          ),

        // 플로팅 버튼 (어시스턴트가 비활성화일 때만 표시하거나, 투명도 조절)
        Positioned(
          left: buttonX,
          top: buttonY,
          child: Opacity(
            opacity: isAssistantActive ? 0.2 : 1.0,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _buttonX = (buttonX + details.delta.dx).clamp(
                    0.0,
                    screenSize.width - 56,
                  );
                  _buttonY = (buttonY + details.delta.dy).clamp(
                    0.0,
                    screenSize.height - 56 - bottomPadding,
                  );
                });
              },
              onPanEnd: (_) => _saveButtonPosition(),
              onLongPress: _isActiveMode ? _onLongPressStopActive : null,
              child: _buildFloatingButton(),
            ),
          ),
        ),
      ],
    );
  }

  /// 구글 어시스턴트 스타일의 하단 UI
  Widget _buildGoogleStyleAssistantUI() {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 구글 컬러 웨이브/바
          _buildColorfulWaves(),
          const SizedBox(height: 20),

          // 현재 텍스트 (사용자 입력 또는 비서 질문)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _currentText,
              key: ValueKey(_currentText),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // 진행 상태 안내
          Text(
            _isProcessing ? '생각 중...' : (_isSpeaking ? '알려드려요' : '듣고 있어요'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (_tempExpenseItem != null || _tempExpensePrice != null) ...[
            const SizedBox(height: 20),
            _buildExtractedDataChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildColorfulWaves() {
    // 4가지 구글 시그니처 컬러
    final colors = [
      Colors.blue[400]!,
      Colors.red[400]!,
      Colors.yellow[600]!,
      Colors.green[400]!,
    ];

    return SizedBox(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          double level = 8.0;
          if (_isListening) {
            level =
                (_soundLevel * (1.0 - (index * 0.1))).clamp(2.0, 10.0) * 2.5;
          } else if (_isSpeaking || _isProcessing) {
            // 말하거나 처리 중일 때는 일정한 속도로 물결침
            level = 8.0 + (5.0 * (1.0 + (index * 0.2)));
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 8,
            height: level,
            decoration: BoxDecoration(
              color: colors[index],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExtractedDataChips() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      children: [
        if (_tempExpenseItem != null)
          Chip(
            avatar: const Icon(Icons.shopping_bag, size: 16),
            label: Text(_tempExpenseItem!),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
        if (_tempExpensePrice != null)
          Chip(
            avatar: const Icon(Icons.payments, size: 16),
            label: Text(_tempExpensePrice!),
            backgroundColor: theme.colorScheme.tertiaryContainer,
          ),
      ],
    );
  }

  /// 상시 대기 모드 중지 (길게 누르기)
  void _onLongPressStopActive() {
    HapticFeedback.heavyImpact();
    _settings.stopActiveListening();
    _showResultMessage(true, '상시 대기 모드 종료');
  }

  Widget _buildActiveModeBadge() {
    final theme = Theme.of(context);
    final remaining = _settings.remainingTimeString;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 12,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            remaining,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    final theme = Theme.of(context);
    final isActive = _isActiveMode && _settings.isActiveListenEnabled;

    // 상태별 디자인 설정
    final Color buttonColor;
    final IconData buttonIcon;
    final Color iconColor;
    final shouldPulse = _isListening || _isSpeaking;

    if (_isSpeaking) {
      // 1. 비서가 말하는 중
      buttonColor = theme.colorScheme.primary;
      buttonIcon = Icons.volume_up;
      iconColor = Colors.white;
    } else if (_isListening) {
      // 2. 사용자가 말하는 중 (리스닝)
      buttonColor = theme.colorScheme.error;
      buttonIcon = Icons.mic;
      iconColor = Colors.white;
    } else if (isActive) {
      // 3. 상시 대기 모드 활성
      buttonColor = theme.colorScheme.tertiary;
      buttonIcon = Icons.mic;
      iconColor = Colors.white;
    } else {
      // 4. 대기 상태 (Idle)
      buttonColor = theme.colorScheme.primaryContainer;
      buttonIcon = Icons.mic_none;
      iconColor = theme.colorScheme.primary;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: buttonColor,
        child: InkWell(
          onTap: _onButtonTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44, // 약간 크기 키움
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: shouldPulse
                    ? buttonColor
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(buttonIcon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      color: _resultSuccess
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _resultSuccess ? Icons.check_circle : Icons.error,
              color: _resultSuccess
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _resultMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
