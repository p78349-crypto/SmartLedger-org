import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/voice_assistant_settings.dart';
import 'floating_voice_button_widgets.dart';
import 'floating_voice_mic_widgets.dart';
import 'floating_voice_speech_handler.dart';
import 'voice_command_handler.dart';

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
    with SingleTickerProviderStateMixin
    implements VoiceCommandDelegate {
  final VoiceAssistantSettings _settings = VoiceAssistantSettings.instance;
  late final VoiceSpeechHandler _speech;
  late final VoiceCommandHandler _cmd;

  bool _isProcessing = false;
  bool _showResult = false;
  String _resultMessage = '';
  bool _resultSuccess = false;

  // 버튼 위치 (드래그 가능, 저장됨)
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

    _speech = VoiceSpeechHandler();
    _speech.isMounted = () => mounted;
    _speech.onStateChanged = () {
      if (mounted) setState(() {});
    };
    _speech.onVoiceCommand = _onVoiceCommandReady;
    _speech.onShowResult = _showResultMessage;
    _speech.onPulseStop = () => _pulseController.stop();
    _speech.onNeedRestart = () => _startListeningWithPulse(isRestart: true);
    _speech.onSpeechErrorReset = () {
      _pulseController.stop();
      if (mounted) setState(() => _isProcessing = false);
    };

    _cmd = VoiceCommandHandler(delegate: this);

    _speech.initSpeech();
    _speech.initTts(_settings.speechRate);
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

  @override
  void dispose() {
    _pulseController.dispose();
    _autoHideTimer?.cancel();
    _speech.dispose();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    if (_settings.isActiveListenEnabled && !_speech.isActiveMode) {
      _startActiveMode();
    } else if (!_settings.isActiveListenEnabled && _speech.isActiveMode) {
      _speech.stopActiveMode();
    }
    _speech.tts.setSpeechRate(_settings.speechRate);
    setState(() {});
  }

  // ── Button position persistence ──

  Future<void> _loadButtonPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_prefKeyX);
    final y = prefs.getDouble(_prefKeyY);
    if (mounted) setState(() { _buttonX = x; _buttonY = y; });
  }

  Future<void> _saveButtonPosition() async {
    if (_buttonX == null || _buttonY == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKeyX, _buttonX!);
    await prefs.setDouble(_prefKeyY, _buttonY!);
  }

  // ── Active-listen mode ──

  void _startActiveMode() {
    _speech.startActiveMode(
      isActiveListenEnabled: () => _settings.isActiveListenEnabled,
      isProcessing: () => _isProcessing,
    );
  }

  // ── Interaction entry points ──

  void _onButtonTap() {
    if (_isProcessing) return;
    HapticFeedback.mediumImpact();
    _cmd.reset();
    if (_speech.isListening) { _stopAndExitFull(); return; }
    _startConversation();
  }

  Future<void> _startConversation() async {
    setState(() {
      _isProcessing = true;
      _cmd.currentStep = 'confirm_start';
      _speech.currentText = '무엇을 도와드릴까요?';
    });
    await _speech.speak('네, 무엇을 도와드릴까요?');
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _isProcessing = false);
    _startListeningWithPulse();
  }

  void _stopAndExitFull() {
    _speech.stopAndExit();
    _pulseController.stop();
    _pulseController.reset();
  }

  void _startListeningWithPulse({bool isRestart = false}) {
    setState(() => _showResult = false);
    _pulseController.repeat(reverse: true);
    _speech.startListening(isRestart: isRestart);
  }

  void _onVoiceCommandReady(String text) {
    _speech.prepareForCommand();
    _pulseController.stop();
    _pulseController.reset();
    _cmd.handleVoiceCommand(text);
  }

  void _onLongPressStopActive() {
    HapticFeedback.heavyImpact();
    _settings.stopActiveListening();
    _showResultMessage(true, '상시 대기 모드 종료');
  }

  void _showResultMessage(bool success, String message) {
    setState(() {
      _isProcessing = false;
      _showResult = true;
      _resultSuccess = success;
      _resultMessage = message;
    });
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showResult = false);
    });
  }

  // ── VoiceCommandDelegate ──

  @override
  Future<void> speak(String text) => _speech.speak(text);

  @override
  void startListening() => _startListeningWithPulse();

  @override
  void stopAndExit() => _stopAndExitFull();

  @override
  void setProcessing(bool processing) {
    if (mounted) setState(() => _isProcessing = processing);
  }

  @override
  void showResultMessage(bool success, String message) =>
      _showResultMessage(success, message);

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final buttonX = _buttonX ?? (screenSize.width - 56);
    final buttonY = _buttonY ?? (screenSize.height / 2 - 28);
    final isActive =
        _speech.isListening || _isProcessing || _speech.isSpeaking;

    return Stack(
      children: [
        widget.child,
        if (isActive)
          GestureDetector(
            onTap: _stopAndExitFull,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withValues(alpha: 0.4),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        if (_showResult)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 80,
            child: VoiceResultCard(
              success: _resultSuccess,
              message: _resultMessage,
            ),
          ),
        if (isActive)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VoiceAssistantPanel(
              currentText: _speech.currentText,
              isProcessing: _isProcessing,
              isSpeaking: _speech.isSpeaking,
              isListening: _speech.isListening,
              soundLevel: _speech.soundLevel,
              tempExpenseItem: _cmd.tempExpenseItem,
              tempExpensePrice: _cmd.tempExpensePrice,
            ),
          ),
        if (_speech.isActiveMode && _settings.isActiveListenEnabled)
          Positioned(
            left: buttonX - 10,
            top: buttonY + 50,
            child: ActiveModeBadge(
              remainingTimeString: _settings.remainingTimeString,
            ),
          ),
        Positioned(
          left: buttonX,
          top: buttonY,
          child: Opacity(
            opacity: isActive ? 0.2 : 1.0,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _buttonX = (buttonX + details.delta.dx)
                      .clamp(0.0, screenSize.width - 56);
                  _buttonY = (buttonY + details.delta.dy)
                      .clamp(0.0, screenSize.height - 56 - bottomPadding);
                });
              },
              onPanEnd: (_) => _saveButtonPosition(),
              onLongPress:
                  _speech.isActiveMode ? _onLongPressStopActive : null,
              child: FloatingMicButton(
                isListening: _speech.isListening,
                isSpeaking: _speech.isSpeaking,
                isActiveMode: _speech.isActiveMode,
                isActiveListenEnabled: _settings.isActiveListenEnabled,
                pulseAnimation: _pulseAnimation,
                onTap: _onButtonTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
