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
import '../services/aicore_gemini_service.dart';
import '../utils/pref_keys.dart';

part 'floating_voice_button_speech.dart';
part 'floating_voice_button_commands.dart';
part 'floating_voice_button_helpers.dart';
part 'floating_voice_button_ui.dart';

/// 버튼 위치 저장 키
const String _prefKeyX = 'floating_voice_btn_x';
const String _prefKeyY = 'floating_voice_btn_y';

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
  final AICoreGeminiService _aicore = AICoreGeminiService();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _showResult = false;
  Timer? _silenceTimer;
  String _currentText = '';
  String _tempBuffer = '';
  String _resultMessage = '';
  bool _resultSuccess = false;

  // 실시간 음성 강도 (0.0 ~ 10.0)
  double _soundLevel = 0.0;

  // 지출 데이터 임시 저장 (대화형)
  String? _tempExpenseItem;
  String? _tempExpensePrice;

  // 대화 단계 관리
  String _currentStep = 'idle';

  // 상시 대기 모드
  bool _isActiveMode = false;
  Timer? _activeModeTicker;

  // 버튼 위치 (드래그 가능, 저장됨)
  double? _buttonX;
  double? _buttonY;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_settings.isActiveListenEnabled) {
        _startActiveMode();
      }
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(_settings.speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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

        // 플로팅 버튼
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
}
