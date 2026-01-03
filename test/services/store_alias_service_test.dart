import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/services/store_alias_service.dart';

void main() {
  group('StoreAliasService.resolve', () {
    test('returns original when map is empty', () {
      expect(StoreAliasService.resolve('이마트', const {}), equals('이마트'));
    });

    test('resolves direct alias', () {
      final map = <String, String>{'이마트24': '이마트'};
      expect(StoreAliasService.resolve('이마트24', map), equals('이마트'));
    });

    test('resolves transitively', () {
      final map = <String, String>{'A': 'B', 'B': 'C'};
      expect(StoreAliasService.resolve('A', map), equals('C'));
    });

    test('treats self mapping as no-op', () {
      final map = <String, String>{'A': 'A'};
      expect(StoreAliasService.resolve('A', map), equals('A'));
    });

    test('protects against cycles', () {
      final map = <String, String>{'A': 'B', 'B': 'A'};
      expect(StoreAliasService.resolve('A', map), equals('A'));
    });

    test('normalizes store key input', () {
      final map = <String, String>{'이마트': '이마트(대표)'};
      expect(StoreAliasService.resolve('이마트 / 기타', map), equals('이마트(대표)'));
    });
  });
}
