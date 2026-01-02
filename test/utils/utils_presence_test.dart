import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Utils file guard', () {
    const expectedUtilsFiles = <String>[
      'account_utils.dart',
      'asset_dashboard_utils.dart',
      'chart_display_utils.dart',
      'chart_utils.dart',
      'collapsible_section.dart',
      'color_utils.dart',
      'constants.dart',
      'currency_formatter.dart',
      'currency_input_formatter.dart',
      'date_formats.dart',
      'date_formatter.dart',
      'dialog_utils.dart',
      'form_field_helpers.dart',
      'localization.dart',
      'number_formats.dart',
      'period_utils.dart',
      'pref_keys.dart',
      'profit_loss_calculator.dart',
      'README.md',
      'REFACTORING_GUIDE.md',
      'snackbar_utils.dart',
      'stats_labels.dart',
      'stats_view_utils.dart',
      'thousands_input_formatter.dart',
      'transaction_button_utils.dart',
      'transaction_utils.dart',
      'type_converters.dart',
      'utils.dart',
      'utils_example.dart',
      'validators.dart',
    ];

    test('all expected utils files remain present', () {
      final missing = <String>[];

      for (final relativeName in expectedUtilsFiles) {
        final file = File('lib/utils/$relativeName');
        if (!file.existsSync()) {
          missing.add(relativeName);
        }
      }

      expect(
        missing,
        isEmpty,
        reason: 'Required util files are missing: ${missing.join(', ')}',
      );
    });
  });
}

