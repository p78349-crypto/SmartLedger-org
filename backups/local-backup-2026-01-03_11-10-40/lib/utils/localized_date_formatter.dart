import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class LocalizedDateFormatter {
  LocalizedDateFormatter._();

  static String _localeTag(BuildContext context) {
    final locale = Localizations.localeOf(context);
    // Intl locale names are typically underscore-based (e.g., en_US, ko_KR).
    // Localizations gives BCP-47 tags (e.g., en-US). Normalize for Intl.
    return locale.toLanguageTag().replaceAll('-', '_');
  }

  static String yM(BuildContext context, DateTime date) {
    return DateFormat.yM(_localeTag(context)).format(date);
  }

  static String yMd(BuildContext context, DateTime date) {
    return DateFormat.yMd(_localeTag(context)).format(date);
  }

  static String md(BuildContext context, DateTime date) {
    return DateFormat.Md(_localeTag(context)).format(date);
  }

  static String y(BuildContext context, int year) {
    return DateFormat.y(_localeTag(context)).format(DateTime(year, 1, 1));
  }
}
