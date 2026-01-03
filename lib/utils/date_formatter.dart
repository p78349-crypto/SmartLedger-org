import 'package:intl/intl.dart';

/// 날짜 포맷 관련 유틸리티 클래스
class DateFormatter {
  // Private constructor to prevent instantiation
  DateFormatter._();

  /// 기본 날짜 포맷: yyyy-MM-dd
  static final DateFormat defaultDate = DateFormat('yyyy-MM-dd');

  /// 날짜 + 시간 포맷: yyyy-MM-dd HH:mm
  static final DateFormat dateTime = DateFormat('yyyy-MM-dd HH:mm');

  /// 날짜 + 시간 + 초: yyyy-MM-dd HH:mm:ss
  static final DateFormat dateTimeSeconds = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// 월 라벨 포맷: yyyy년 M월
  static final DateFormat monthLabel = DateFormat('yyyy년 M월');

  /// 간단한 월일 포맷: M월 d일
  static final DateFormat monthDay = DateFormat('M월 d일');

  /// 짧은 월 포맷: M월
  static final DateFormat shortMonth = DateFormat('M월');

  /// 연-월 포맷: yyyy-MM
  static final DateFormat yearMonth = DateFormat('yyyy-MM');

  /// 범위 월 포맷: yyyy.MM
  static final DateFormat rangeMonth = DateFormat('yyyy.MM');

  /// 범위 날짜 포맷: yyyy.MM.dd
  static final DateFormat rangeDate = DateFormat('yyyy.MM.dd');

  /// 년(한글) 포맷: yyyy년
  static final DateFormat yearKorean = DateFormat('yyyy년');

  /// 요일 포함 포맷: yyyy-MM-dd (E)
  static final DateFormat dateWithWeekday = DateFormat(
    'yyyy-MM-dd (E)',
    'ko_KR',
  );

  /// 요일 + 시분초 포함 포맷: yyyy-MM-dd (E) HH:mm:ss
  static final DateFormat dateWithWeekdayTimeSeconds = DateFormat(
    'yyyy-MM-dd (E) HH:mm:ss',
    'ko_KR',
  );

  /// 파일명용 포맷: yyyyMMdd
  static final DateFormat fileNameDate = DateFormat('yyyyMMdd');

  /// 파일명용 포맷 (시간 포함): yyyyMMdd_HHmmss
  static final DateFormat fileNameDateTime = DateFormat('yyyyMMdd_HHmmss');

  /// MM/dd 포맷 (두자리 월/일)
  static final DateFormat mmdd = DateFormat('MM/dd');

  /// MM/dd HH:mm 포맷
  static final DateFormat mmddHHmm = DateFormat('MM/dd HH:mm');

  /// DateTime을 기본 날짜 문자열로 변환
  static String formatDate(DateTime date) {
    return defaultDate.format(date);
  }

  /// DateTime을 날짜+시간 문자열로 변환
  static String formatDateTime(DateTime date) {
    return dateTime.format(date);
  }

  /// DateTime을 월 라벨로 변환
  static String formatMonthLabel(DateTime date) {
    return monthLabel.format(date);
  }

  /// DateTime을 짧은 월로 변환 (M월)
  static String formatShortMonth(DateTime date) {
    return shortMonth.format(date);
  }

  /// DateTime을 범위 월로 변환 (yyyy.MM)
  static String formatRangeMonth(DateTime date) {
    return rangeMonth.format(date);
  }

  /// DateTime을 년월로 변환 (yyyy년 M월)
  static String formatYearMonth(DateTime date) {
    return monthLabel.format(date);
  }

  /// DateTime을 월일로 변환 (M월 d일)
  static String formatMonthDay(DateTime date) {
    return monthDay.format(date);
  }

  /// DateTime을 파일명용 문자열로 변환
  static String formatForFileName(DateTime date, {bool includeTime = false}) {
    return includeTime
        ? fileNameDateTime.format(date)
        : fileNameDate.format(date);
  }

  /// 문자열을 DateTime으로 파싱 (yyyy-MM-dd 형식)
  static DateTime? parseDate(String dateString) {
    try {
      return defaultDate.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// 문자열을 DateTime으로 파싱 (yyyy-MM-dd HH:mm 형식)
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return dateTime.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// 날짜의 월 시작일 반환
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month);
  }

  /// 날짜의 월 마지막일 반환
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 두 날짜가 같은 월인지 확인
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// 두 날짜가 같은 날인지 확인
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 날짜의 시간 부분을 제거 (자정으로 설정)
  static DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
