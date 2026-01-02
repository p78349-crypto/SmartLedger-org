import 'dart:async';

import 'package:flutter/foundation.dart';

/// Prevents accidental double-taps / repeated invocations while an action is
/// running.
///
/// This is intentionally global and lightweight; use it for UI callbacks that
/// should not be re-entered (navigation, dialogs, etc.).
class InteractionBlockers {
  InteractionBlockers._();

  static bool _busy = false;

  static bool get isBlocked => _busy;

  static Future<void> run(FutureOr<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  static Future<void> Function() gate(FutureOr<void> Function() action) {
    return () async {
      if (_busy) return;
      _busy = true;
      try {
        await action();
      } finally {
        _busy = false;
      }
    };
  }

  static ValueChanged<T> gateValue<T>(FutureOr<void> Function(T value) action) {
    return (value) async {
      if (_busy) return;
      _busy = true;
      try {
        await action(value);
      } finally {
        _busy = false;
      }
    };
  }
}

