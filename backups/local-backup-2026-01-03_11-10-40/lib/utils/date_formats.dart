import 'package:intl/intl.dart';
import 'package:smart_ledger/utils/date_formatter.dart';

/// 공용 날짜 포매터: 기존 `DateFormats` API를 유지하되 내부적으로
/// `DateFormatter`의 정의를 재사용합니다.
class DateFormats {
  DateFormats._();

  static final DateFormat yMd = DateFormatter.defaultDate;
  static final DateFormat yMLabel = DateFormatter.monthLabel;
  static final DateFormat yMdot = DateFormatter.rangeMonth;
  // yyyy.MM.dd는 DateFormatter에 정의되지 않으므로 여기서 보조 정의합니다.
  static final DateFormat yMddot = DateFormat('yyyy.MM.dd');
  static final DateFormat yMdHms = DateFormatter.dateTimeSeconds;
  static final DateFormat monthDayLabel = DateFormatter.monthDay;
  static final DateFormat shortMonth = DateFormatter.shortMonth;
}
