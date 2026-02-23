import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_tts/flutter_tts.dart';  // 🔒 AI 규제 준수로 제외
// import 'package:speech_to_text/speech_to_text.dart' as stt;  // 🔒 AI 규제 준수로 제외

/// Callback for handling completed voice input.
typedef VoiceResultCallback = void Function(String text);

/// Handles SpeechToText and FlutterTts lifecycle, isolating raw speech
/// operations from widget state.
class VoiceSpeechHandler {
  // 🔒 AI 규제 준수로 비활성화
  // final stt.SpeechToText speech = stt.SpeechToText();
  // final FlutterTts tts = FlutterTts();
  final _SealedSpeechEngine speech = const _SealedSpeechEngine();
  final _SealedTtsEngine tts = const _SealedTtsEngine();

  bool speechAvailable = false;
  bool isListening = false;
  bool isSpeaking = false;
  double soundLevel = 0.0;
  String currentText = '';
  String _tempBuffer = '';
  bool isActiveMode = false;

  Timer? _silenceTimer;
  Timer? _activeModeTicker;

  // ── Callbacks (set by the owning State) ──

  /// Triggers setState in the owner.
  VoidCallback? onStateChanged;

  /// Called when final voice text is ready for command processing.
  VoiceResultCallback? onVoiceCommand;

  /// Shows a result message banner.
  void Function(bool success, String message)? onShowResult;

  /// Returns whether the owning widget is still mounted.
  bool Function()? isMounted;

  /// Called to stop the pulse animation.
  VoidCallback? onPulseStop;

  /// Called when automatic restart is needed (system premature stop).
  VoidCallback? onNeedRestart;

  /// Called on speech error to reset processing state.
  VoidCallback? onSpeechErrorReset;

  // ── TTS ──

  Future<void> initTts(double speechRate) async {
    await tts.setLanguage('ko-KR');
    await tts.setSpeechRate(speechRate);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    await tts.awaitSpeakCompletion(true);
  }

  /// 음성으로 텍스트 읽어주기 (끝날 때까지 기다림)
  Future<void> speak(String text) async {
    isSpeaking = true;
    onStateChanged?.call();
    await tts.speak(text);
    isSpeaking = false;
    onStateChanged?.call();
  }

  // ── STT ──

  Future<void> initSpeech() async {
    try {
      speechAvailable = await speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (isMounted?.call() != true) return;

          String userMsg = '음성 인식 오류가 발생했습니다';
          if (error.errorMsg.contains('error_network') ||
              error.errorMsg.contains('7')) {
            userMsg = '오프라인 언어 팩(한국어)이 설치되어 있는지 확인해주세요.';
          } else if (error.errorMsg.contains('error_no_match')) {
            userMsg = '잘 듣지 못했어요. 다시 말씀해주세요.';
          }

          isListening = false;
          soundLevel = 0;
          onSpeechErrorReset?.call();
          onStateChanged?.call();

          if (!isActiveMode) {
            onShowResult?.call(false, userMsg);
          }
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'notListening' || status == 'done') {
            if (isMounted?.call() != true) return;
            soundLevel = 0;
            onPulseStop?.call();
            onStateChanged?.call();

            // 시스템이 성급하게 종료한 경우 재시작하여 말을 끝까지 듣습니다.
            if (isListening && _silenceTimer?.isActive == true) {
              debugPrint('[FloatingVoice] 시스템 성급 종료 감지: 다시 듣기 시작');
              onNeedRestart?.call();
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> startListening({bool isRestart = false}) async {
    if (!speechAvailable) {
      onShowResult?.call(false, '음성 인식을 사용할 수 없어요');
      return;
    }

    isListening = true;
    if (!isRestart) {
      currentText = '말씀해 주세요...';
      _tempBuffer = '';
    }
    soundLevel = 0;
    onStateChanged?.call();

    try {
      if (speech.isListening) {
        await speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await speech.listen(
        onResult: (result) {
          if (isMounted?.call() != true) return;

          final text = result.recognizedWords;
          final displayScore =
              _tempBuffer.isEmpty ? text : '$_tempBuffer $text';

          if (displayScore.isNotEmpty) {
            currentText = displayScore;
            HapticFeedback.selectionClick();
          }
          onStateChanged?.call();

          _silenceTimer?.cancel();

          if (text.isNotEmpty) {
            // 3.5초 침묵 시 최종 처리
            _silenceTimer = Timer(const Duration(milliseconds: 3500), () {
              if (isMounted?.call() == true && currentText.isNotEmpty) {
                debugPrint('[FloatingVoice] 3.5초 침묵 감지: 최종 처리 시작');
                onVoiceCommand?.call(currentText);
              }
            });
          }

          if (result.finalResult && text.isNotEmpty) {
            _silenceTimer?.cancel();
            debugPrint('[FloatingVoice] 시스템 최종 감지 완료: "$displayScore"');
            _tempBuffer = displayScore;

            Future.delayed(const Duration(milliseconds: 1500), () {
              if (isMounted?.call() == true &&
                  currentText == displayScore) {
                onVoiceCommand?.call(displayScore);
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          if (isMounted?.call() == true) {
            soundLevel = level;
            onStateChanged?.call();
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 15),
        localeId: 'ko_KR',
        listenOptions: null,
      );
    } catch (e) {
      debugPrint('Listening error: $e');
      onShowResult?.call(false, '음성 인식에 실패했어요');
    }
  }

  /// 엔진만 멈추고 UI 상태는 유지 (명령 처리 준비)
  void prepareForCommand() {
    _silenceTimer?.cancel();
    speech.stop();
  }

  /// 완전 종료
  void stopAndExit() {
    _silenceTimer?.cancel();
    speech.stop();
    isListening = false;
    currentText = '';
    soundLevel = 0;
    onStateChanged?.call();
  }

  // ── Active-mode helpers ──

  void startActiveMode({
    required bool Function() isActiveListenEnabled,
    required bool Function() isProcessing,
  }) {
    isActiveMode = true;
    _activeModeTicker?.cancel();
    _activeModeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isMounted?.call() != true) return;
      if (!isActiveListenEnabled()) {
        stopActiveMode();
        return;
      }
      onStateChanged?.call();
      if (!isListening && !isProcessing()) {
        startListening();
      }
    });
    if (!isListening && !isProcessing()) {
      startListening();
    }
    onStateChanged?.call();
  }

  void stopActiveMode() {
    isActiveMode = false;
    _activeModeTicker?.cancel();
    _activeModeTicker = null;
    if (isListening) speech.stop();
    onStateChanged?.call();
  }

  void dispose() {
    _silenceTimer?.cancel();
    _activeModeTicker?.cancel();
    speech.stop();
    tts.stop();
  }
}

class _SealedSpeechEngine {
  const _SealedSpeechEngine();

  bool get isListening => false;

  Future<bool> initialize({dynamic onError, dynamic onStatus}) async => false;

  Future<void> listen({
    dynamic onResult,
    dynamic onSoundLevelChange,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    dynamic listenOptions,
  }) async {}

  Future<void> stop() async {}
}

class _SealedTtsEngine {
  const _SealedTtsEngine();

  Future<void> setLanguage(String language) async {}
  Future<void> setSpeechRate(double rate) async {}
  Future<void> setVolume(double volume) async {}
  Future<void> setPitch(double pitch) async {}
  Future<void> awaitSpeakCompletion(bool enabled) async {}
  Future<void> speak(String text) async {}
  Future<void> stop() async {}
}
