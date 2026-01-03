import 'package:flutter/material.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

/// 스낵바 관련 유틸리티 클래스
class SnackbarUtils {
  // Private constructor to prevent instantiation
  SnackbarUtils._();

  /// 기본 스낵바 표시
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration, action: action),
    );
  }

  /// 성공 스낵바 표시 (초록색)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onPrimaryContainer),
          child: Row(
            children: [
              Icon(IconCatalog.checkCircle, color: scheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        backgroundColor: scheme.primaryContainer,
        duration: duration,
      ),
    );
  }

  /// 에러 스낵바 표시 (빨간색)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onErrorContainer),
          child: Row(
            children: [
              Icon(IconCatalog.errorOutline, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        backgroundColor: scheme.errorContainer,
        duration: duration,
      ),
    );
  }

  /// 경고 스낵바 표시 (주황색)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onTertiaryContainer),
          child: Row(
            children: [
              Icon(IconCatalog.autoAwesome, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        backgroundColor: scheme.tertiaryContainer,
        duration: duration,
      ),
    );
  }

  /// 정보 스낵바 표시 (파란색)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onSecondaryContainer),
          child: Row(
            children: [
              Icon(
                IconCatalog.checkCircleOutline,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        backgroundColor: scheme.secondaryContainer,
        duration: duration,
      ),
    );
  }

  /// 실행 취소 가능한 스낵바
  static void showWithUndo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: SnackBarAction(label: '실행 취소', onPressed: onUndo),
      ),
    );
  }

  /// 현재 표시 중인 스낵바 닫기
  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// 모든 스낵바 닫기
  static void dismissAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
