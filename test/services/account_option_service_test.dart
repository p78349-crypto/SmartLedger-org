import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/account_option_service.dart';

void main() {
  group('AccountOptionService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('getOption', () {
      test('returns defaultValue when not set', () async {
        final result = await AccountOptionService.getOption(
          'test_account',
          'show_chart',
          defaultValue: true,
        );
        expect(result, isTrue);
      });

      test('returns stored value', () async {
        SharedPreferences.setMockInitialValues({
          'opt_test_account_show_chart': false,
        });

        final result = await AccountOptionService.getOption(
          'test_account',
          'show_chart',
        );
        expect(result, isFalse);
      });
    });

    group('setOption', () {
      test('stores value correctly', () async {
        await AccountOptionService.setOption('my_account', 'dark_mode', true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('opt_my_account_dark_mode'), isTrue);
      });

      test('overwrites existing value', () async {
        SharedPreferences.setMockInitialValues({
          'opt_account1_option1': true,
        });

        await AccountOptionService.setOption('account1', 'option1', false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('opt_account1_option1'), isFalse);
      });
    });

    group('exportOptions', () {
      test('returns empty map when no options exist', () async {
        final result = await AccountOptionService.exportOptions('empty_account');
        expect(result, isEmpty);
      });

      test('exports all options for account', () async {
        SharedPreferences.setMockInitialValues({
          'opt_export_test_opt1': true,
          'opt_export_test_opt2': false,
          'opt_other_account_opt1': true, // 다른 계좌는 포함되면 안됨
        });

        final result = await AccountOptionService.exportOptions('export_test');

        expect(result.length, 2);
        expect(result['opt1'], isTrue);
        expect(result['opt2'], isFalse);
        expect(result.containsKey('opt_other_account_opt1'), isFalse);
      });
    });

    group('importOptions', () {
      test('clears existing and imports new options', () async {
        SharedPreferences.setMockInitialValues({
          'opt_import_test_old_option': true,
        });

        await AccountOptionService.importOptions('import_test', {
          'new_option1': true,
          'new_option2': false,
        });

        final prefs = await SharedPreferences.getInstance();
        
        // 이전 옵션은 삭제됨
        expect(prefs.getBool('opt_import_test_old_option'), isNull);
        
        // 새 옵션 저장됨
        expect(prefs.getBool('opt_import_test_new_option1'), isTrue);
        expect(prefs.getBool('opt_import_test_new_option2'), isFalse);
      });

      test('ignores non-boolean values', () async {
        await AccountOptionService.importOptions('test', {
          'bool_option': true,
          'string_option': 'hello', // non-boolean
          'int_option': 42, // non-boolean
        });

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('opt_test_bool_option'), isTrue);
        expect(prefs.containsKey('opt_test_string_option'), isFalse);
        expect(prefs.containsKey('opt_test_int_option'), isFalse);
      });
    });

    test('different accounts have isolated options', () async {
      await AccountOptionService.setOption('account_a', 'shared_opt', true);
      await AccountOptionService.setOption('account_b', 'shared_opt', false);

      final resultA = await AccountOptionService.getOption('account_a', 'shared_opt');
      final resultB = await AccountOptionService.getOption('account_b', 'shared_opt');

      expect(resultA, isTrue);
      expect(resultB, isFalse);
    });
  });
}
