import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/memo_suggestion_utils.dart';

void main() {
  group('MemoSuggestionUtils', () {
    Transaction tx({
      required String id,
      required DateTime date,
      required String memo,
      String? store,
      bool isRefund = false,
    }) {
      return Transaction(
        id: id,
        type: TransactionType.expense,
        description: 'd',
        amount: -100,
        date: date,
        memo: memo,
        store: store,
        isRefund: isRefund,
      );
    }

    test('suggestChips ranks frequent keywords for matching store', () {
      final now = DateTime.now();

      final transactions = <Transaction>[
        tx(id: '1', date: now.subtract(const Duration(days: 1)), memo: 'MegaMart - milk'),
        tx(id: '2', date: now.subtract(const Duration(days: 2)), memo: 'MegaMart - milk'),
        tx(id: '3', date: now.subtract(const Duration(days: 3)), memo: 'MegaMart - eggs'),
        tx(id: '4', date: now.subtract(const Duration(days: 1)), memo: 'OtherShop - milk'),
        tx(
          id: '5',
          date: now.subtract(const Duration(days: 1)),
          memo: 'MegaMart - 카드 - snack',
        ),
        tx(
          id: '6',
          date: now.subtract(const Duration(days: 1)),
          memo: 'MegaMart - milk',
          isRefund: true,
        ),
        // Outside scan window (~183d) should be ignored.
        tx(id: '7', date: now.subtract(const Duration(days: 200)), memo: 'MegaMart - old'),
      ];

      final chips = MemoSuggestionUtils.suggestChips(
        transactions: transactions,
        currentMemo: 'MegaMart / something',
      );

      expect(chips, isNotEmpty);
      expect(chips.first, 'milk');
      expect(chips, contains('eggs'));
      expect(chips, isNot(contains('카드')));
      expect(chips, isNot(contains('old')));
    });

    test('normalizeForMatch delegates to StoreMemoUtils', () {
      expect(MemoSuggestionUtils.normalizeForMatch('  A  B  '), 'a b');
    });

    test('scanStartForNow subtracts 183 days', () {
      final now = DateTime(2026);
      final start = MemoSuggestionUtils.scanStartForNow(now);
      expect(now.difference(start).inDays, 183);
    });
  });
}
