class DateParser {
  const DateParser._();

  /// Parses a human-friendly date input into a local [DateTime] (date-only).
  ///
  /// Supported examples (Korean):
  /// - "오늘", "내일", "모레"
  /// - "3일 뒤", "10일뒤"
  /// - "1월 20일"
  /// - ISO: "2026-01-20" (and any `DateTime.parse`-compatible forms)
  ///
  /// If parsing fails, returns today's date (local, date-only).
  static DateTime parse(String? dateInput, {DateTime? now}) {
    final nowLocal = (now ?? DateTime.now()).toLocal();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    final raw = (dateInput ?? '').trim();
    if (raw.isEmpty) return today;

    // 1) Relative keywords
    if (raw.contains('오늘')) return today;
    if (raw.contains('내일')) return today.add(const Duration(days: 1));
    if (raw.contains('모레')) return today.add(const Duration(days: 2));

    // 2) "N일 뒤" pattern
    final dayAfterMatch = RegExp(r'(\d+)\s*일\s*뒤').firstMatch(raw);
    if (dayAfterMatch != null) {
      final days = int.tryParse(dayAfterMatch.group(1) ?? '');
      if (days != null) {
        return today.add(Duration(days: days));
      }
    }

    // 3) "M월 D일" pattern (year defaults to current year)
    final monthDayMatch = RegExp(r'(\d+)\s*월\s*(\d+)\s*일').firstMatch(raw);
    if (monthDayMatch != null) {
      final month = int.tryParse(monthDayMatch.group(1) ?? '');
      final day = int.tryParse(monthDayMatch.group(2) ?? '');
      if (month != null && day != null) {
        return DateTime(today.year, month, day);
      }
    }

    // 4) ISO / default DateTime.parse
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final local = parsed.toLocal();
      return DateTime(local.year, local.month, local.day);
    }

    return today;
  }
}
