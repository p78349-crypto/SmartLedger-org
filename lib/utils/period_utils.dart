/// 기간 타입 enum
enum PeriodType { week, month, quarter, halfYear, year, decade }

/// 기간 계산 관련 유틸리티 클래스
class PeriodUtils {
  PeriodUtils._();

  /// 기간별 날짜 범위 계산
  static DateTimeRange getPeriodRange(PeriodType period, {DateTime? baseDate}) {
    final now = baseDate ?? DateTime.now();

    switch (period) {
      case PeriodType.week:
        final end = now;
        final start = end.subtract(const Duration(days: 6));
        return DateTimeRange(start: start, end: end);

      case PeriodType.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(start: start, end: end);

      case PeriodType.quarter:
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        final start = DateTime(now.year, quarterStart, 1);
        final end = DateTime(now.year, quarterStart + 3, 0);
        return DateTimeRange(start: start, end: end);

      case PeriodType.halfYear:
        final halfYearStart = now.month <= 6 ? 1 : 7;
        final start = DateTime(now.year, halfYearStart, 1);
        final end = DateTime(now.year, halfYearStart + 6, 0);
        return DateTimeRange(start: start, end: end);

      case PeriodType.year:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year + 1, 1, 0);
        return DateTimeRange(start: start, end: end);

      case PeriodType.decade:
        final decadeStart = (now.year ~/ 10) * 10;
        final start = DateTime(decadeStart, 1, 1);
        final end = DateTime(decadeStart + 10, 1, 0);
        return DateTimeRange(start: start, end: end);
    }
  }

  /// 기간 레이블 반환
  static String getPeriodLabel(PeriodType period) {
    switch (period) {
      case PeriodType.week:
        return '주간 리포트';
      case PeriodType.month:
        return '월간 리포트';
      case PeriodType.quarter:
        return '분기 리포트';
      case PeriodType.halfYear:
        return '반기 리포트';
      case PeriodType.year:
        return '연간 리포트';
      case PeriodType.decade:
        return '10년';
    }
  }

  /// 기간이 범위 뷰인지 확인
  static bool isRangeView(PeriodType period) {
    return true; // 모든 기간 타입이 범위 뷰
  }
}

/// 날짜 범위 클래스
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});

  /// 기간 내에 포함되는지 확인
  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  /// 기간 일수 계산
  int get days => end.difference(start).inDays;
}
