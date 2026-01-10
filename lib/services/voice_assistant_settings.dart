import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 음성비서 설정 서비스
/// 상시 대기 모드 시간 등 관리
class VoiceAssistantSettings extends ChangeNotifier {
  static final VoiceAssistantSettings _instance =
      VoiceAssistantSettings._internal();
  static VoiceAssistantSettings get instance => _instance;
  VoiceAssistantSettings._internal();

  static const String _keyActiveListenDuration = 'voice_active_listen_duration';
  static const String _keyActiveListenEndTime = 'voice_active_listen_end_time';

  /// 상시 대기 시간 옵션 (분 단위, 0 = 꺼짐)
  static const List<int> durationOptions = [0, 10, 20, 30, 40, 60];

  /// 옵션 라벨
  static String getDurationLabel(int minutes) {
    if (minutes == 0) return '꺼짐 (터치로 실행)';
    if (minutes == 60) return '1시간';
    return '$minutes분';
  }

  int _activeListenDuration = 0; // 분 단위
  DateTime? _activeListenEndTime;

  int get activeListenDuration => _activeListenDuration;
  DateTime? get activeListenEndTime => _activeListenEndTime;

  /// 상시 대기 모드가 활성화되어 있는지
  bool get isActiveListenEnabled {
    if (_activeListenDuration == 0) return false;
    if (_activeListenEndTime == null) return false;
    return DateTime.now().isBefore(_activeListenEndTime!);
  }

  /// 남은 시간 (초)
  int get remainingSeconds {
    if (!isActiveListenEnabled) return 0;
    return _activeListenEndTime!.difference(DateTime.now()).inSeconds;
  }

  /// 남은 시간 문자열
  String get remainingTimeString {
    final seconds = remainingSeconds;
    if (seconds <= 0) return '';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes분 $secs초 남음';
    }
    return '$secs초 남음';
  }

  /// 초기화
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _activeListenDuration = prefs.getInt(_keyActiveListenDuration) ?? 0;

    final endTimeMillis = prefs.getInt(_keyActiveListenEndTime);
    if (endTimeMillis != null) {
      _activeListenEndTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      // 이미 만료된 경우 초기화
      if (_activeListenEndTime!.isBefore(DateTime.now())) {
        _activeListenEndTime = null;
        await prefs.remove(_keyActiveListenEndTime);
      }
    }
    notifyListeners();
  }

  /// 상시 대기 시간 설정 (설정만, 타이머 시작 안 함)
  Future<void> setDuration(int minutes) async {
    _activeListenDuration = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyActiveListenDuration, minutes);
    notifyListeners();
  }

  /// 상시 대기 모드 시작
  Future<void> startActiveListening() async {
    if (_activeListenDuration == 0) return;

    _activeListenEndTime = DateTime.now().add(
      Duration(minutes: _activeListenDuration),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyActiveListenEndTime,
      _activeListenEndTime!.millisecondsSinceEpoch,
    );
    notifyListeners();
  }

  /// 상시 대기 모드 중지
  Future<void> stopActiveListening() async {
    _activeListenEndTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveListenEndTime);
    notifyListeners();
  }

  /// 상시 대기 모드 토글
  Future<void> toggleActiveListening() async {
    if (isActiveListenEnabled) {
      await stopActiveListening();
    } else {
      await startActiveListening();
    }
  }
}
