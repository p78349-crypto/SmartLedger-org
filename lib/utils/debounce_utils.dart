import 'dart:async';

/// Debounce 유틸리티
/// 
/// 연속된 호출을 지연시켜 마지막 호출만 실행
/// 
/// 사용 예시:
/// ```dart
/// final debouncer = Debouncer(delay: Duration(milliseconds: 300));
/// 
/// // 연속 호출
/// debouncer.run(() => print('1')); // 취소됨
/// debouncer.run(() => print('2')); // 취소됨
/// debouncer.run(() => print('3')); // 300ms 후 실행
/// 
/// // 정리
/// debouncer.dispose();
/// ```
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// 디바운스 실행
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 대기 중인 타이머 취소
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 리소스 정리
  void dispose() {
    cancel();
  }

  /// 현재 대기 중인지
  bool get isPending => _timer?.isActive ?? false;
}

/// Throttle 유틸리티
/// 
/// 일정 시간 동안 최대 한 번만 실행
/// 
/// 사용 예시:
/// ```dart
/// final throttler = Throttler(delay: Duration(seconds: 1));
/// 
/// // 빠른 연속 호출
/// throttler.run(() => print('1')); // 즉시 실행
/// throttler.run(() => print('2')); // 무시됨
/// throttler.run(() => print('3')); // 무시됨
/// // 1초 후
/// throttler.run(() => print('4')); // 실행
/// ```
class Throttler {
  final Duration delay;
  DateTime? _lastExecuted;
  Timer? _timer;

  Throttler({required this.delay});

  /// 쓰로틀 실행 (즉시 실행 모드)
  void run(VoidCallback action) {
    final now = DateTime.now();
    
    if (_lastExecuted == null || 
        now.difference(_lastExecuted!) >= delay) {
      action();
      _lastExecuted = now;
    }
  }

  /// 쓰로틀 실행 (trailing 모드 - 마지막 호출도 실행)
  void runTrailing(VoidCallback action) {
    final now = DateTime.now();
    
    if (_lastExecuted == null || 
        now.difference(_lastExecuted!) >= delay) {
      action();
      _lastExecuted = now;
      _timer?.cancel();
      _timer = null;
    } else {
      // 아직 쿨다운 중이면 타이머 설정
      _timer?.cancel();
      _timer = Timer(delay, () {
        action();
        _lastExecuted = DateTime.now();
      });
    }
  }

  /// 리소스 정리
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// 현재 쿨다운 중인지
  bool get isCoolingDown {
    if (_lastExecuted == null) return false;
    return DateTime.now().difference(_lastExecuted!) < delay;
  }

  /// 다음 실행까지 남은 시간
  Duration? get remainingCooldown {
    if (_lastExecuted == null) return null;
    final elapsed = DateTime.now().difference(_lastExecuted!);
    if (elapsed >= delay) return null;
    return delay - elapsed;
  }
}

/// VoidCallback 타입 정의
typedef VoidCallback = void Function();
