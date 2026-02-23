import 'dart:developer' as developer;
import 'dart:io';

class AppLogger {
  const AppLogger._();

  static void info(String message, {String name = 'SmartLedger'}) {
    _log(message, level: _LogLevel.info, name: name);
  }

  static void warn(String message, {String name = 'SmartLedger'}) {
    _log(message, level: _LogLevel.warning, name: name);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'SmartLedger',
  }) {
    _log(
      message,
      level: _LogLevel.severe,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    String message, {
    required int level,
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );

    if (_supportsStdout) {
      stdout.writeln('[${name.toUpperCase()}] $message');
      if (error != null) {
        stdout.writeln('  error: $error');
      }
      if (stackTrace != null) {
        stdout.writeln(stackTrace);
      }
    }
  }

  static bool get _supportsStdout {
    try {
      return stdout.hasTerminal;
    } catch (_) {
      return false;
    }
  }
}

class _LogLevel {
  static const int info = 800;
  static const int warning = 900;
  static const int severe = 1000;
}
