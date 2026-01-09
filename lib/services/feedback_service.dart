import 'package:shared_preferences/shared_preferences.dart';

import '../utils/pref_keys.dart';

class FeedbackService {
  const FeedbackService._();

  static const String _defaultFoodExpiryTemplate = '{item} 저장 완료. 유통기한: {date}.';

  /// Returns a short, friendly message after saving an item.
  ///
  /// Note: Keep this message non-medical and non-diagnostic.
  static String getFoodExpirySavedMessage({
    required String itemName,
    required DateTime expiryDate,
  }) {
    final label = _getDateLabel(expiryDate);

    final name = itemName.trim();
    if (name.isEmpty) {
      return '$label 유통기한 항목이 저장되었습니다.';
    }

    // Lightweight, keyword-based personalization (no lab values / health claims).
    if (name.contains('사태살')) {
      return '$name 저장 완료. 유통기한: $label.';
    }
    if (name.contains('아욱') || name.contains('야채') || name.contains('채소')) {
      return '$name 저장 완료. 유통기한: $label.';
    }
    if (name.contains('카카오') || name.contains('아몬드')) {
      return '$name 저장 완료. 유통기한: $label.';
    }

    return '$name 저장 완료. 유통기한: $label.';
  }

  /// Async variant that applies a user-configured template if present.
  ///
  /// Template placeholders:
  /// - {item}
  /// - {date}
  static Future<String> getFoodExpirySavedMessageWithTemplate({
    required String itemName,
    required DateTime expiryDate,
  }) async {
    final base = getFoodExpirySavedMessage(
      itemName: itemName,
      expiryDate: expiryDate,
    );

    final template = await _loadFoodExpiryTemplate();
    if (template == null || template.trim().isEmpty) {
      return _applyTemplate(
        template: _defaultFoodExpiryTemplate,
        itemName: itemName,
        expiryDate: expiryDate,
        fallback: base,
      );
    }

    return _applyTemplate(
      template: template,
      itemName: itemName,
      expiryDate: expiryDate,
      fallback: base,
    );
  }

  static Future<String?> _loadFoodExpiryTemplate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PrefKeys.foodExpirySavedFeedbackTemplateV1);
    } catch (_) {
      return null;
    }
  }

  static String _applyTemplate({
    required String template,
    required String itemName,
    required DateTime expiryDate,
    required String fallback,
  }) {
    final name = itemName.trim().isEmpty ? '항목' : itemName.trim();
    final label = _getDateLabel(expiryDate);
    final rendered = template
        .replaceAll('{item}', name)
        .replaceAll('{date}', label)
        .trim();
    if (rendered.isEmpty) return fallback;
    return rendered;
  }

  static String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(date.year, date.month, date.day);

    final diffDays = d1.difference(d0).inDays;
    if (diffDays == 0) return '오늘';
    if (diffDays == 1) return '내일';
    if (diffDays == 2) return '모레';
    return '${date.month}월 ${date.day}일';
  }
}
