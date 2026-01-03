import 'package:flutter/material.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

/// 다이얼로그 관련 유틸리티 클래스
class DialogUtils {
  // Private constructor to prevent instantiation
  DialogUtils._();

  /// 확인 다이얼로그 표시
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 삭제 확인 다이얼로그
  static Future<bool> showDeleteConfirmDialog(
    BuildContext context, {
    String? itemName,
    String? customMessage,
  }) async {
    final message =
        customMessage ??
        (itemName != null ? '"$itemName"을(를) 삭제하시겠습니까?' : '삭제하시겠습니까?');

    return showConfirmDialog(
      context,
      title: '삭제 확인',
      message: message,
      confirmText: '삭제',
      cancelText: '취소',
      isDangerous: true,
    );
  }

  /// 정보 다이얼로그 표시
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = '확인',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// 에러 다이얼로그 표시
  static Future<void> showErrorDialog(
    BuildContext context, {
    String title = '오류',
    required String message,
    String buttonText = '확인',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              IconCatalog.errorOutline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// 성공 다이얼로그 표시
  static Future<void> showSuccessDialog(
    BuildContext context, {
    String title = '완료',
    required String message,
    String buttonText = '확인',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              IconCatalog.checkCircleOutline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// 텍스트 입력 다이얼로그
  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    String? hint,
    String? initialValue,
    String confirmText = '확인',
    String cancelText = '취소',
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            maxLength: maxLength,
            keyboardType: keyboardType,
            validator: validator,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  /// 선택 다이얼로그 (단일 선택)
  static Future<T?> showChoiceDialog<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T) itemLabel,
    T? initialValue,
  }) async {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              final isSelected = item == initialValue;
              final theme = Theme.of(context);
              return ListTile(
                leading: Icon(
                  isSelected
                      ? IconCatalog.radioButtonChecked
                      : IconCatalog.radioButtonOff,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(itemLabel(item)),
                onTap: () => Navigator.of(context).pop(item),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 로딩 다이얼로그 표시
  static void showLoadingDialog(
    BuildContext context, {
    String message = '처리 중...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  /// 로딩 다이얼로그 닫기
  static void dismissLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
