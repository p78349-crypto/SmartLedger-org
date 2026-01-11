import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/quick_stock_use_utils.dart';

void main() {
  test('extractChosung converts Hangul to initial consonants', () {
    expect(QuickStockUseUtils.extractChosung('가나다'), 'ㄱㄴㄷ');
    expect(QuickStockUseUtils.extractChosung('기상청'), 'ㄱㅅㅊ');
  });

  test('searchItems returns empty list for empty query', () {
    expect(QuickStockUseUtils.searchItems(''), isEmpty);
    expect(QuickStockUseUtils.searchItems('   '), isEmpty);
  });
}
