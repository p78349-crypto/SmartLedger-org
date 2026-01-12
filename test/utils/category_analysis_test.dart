import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/category_analysis.dart';

void main() {
  final now = DateTime(2026, 1, 11);

  Transaction createTx({
    required String id,
    required double amount,
    String mainCategory = '식비',
    String? subCategory,
    bool isRefund = false,
  }) {
    return Transaction(
      id: id,
      type: TransactionType.expense,
      description: 'test',
      amount: amount,
      date: now,
      mainCategory: mainCategory,
      subCategory: subCategory,
      isRefund: isRefund,
    );
  }

  group('CategoryAnalysis', () {
    late CategoryAnalysis analysis;

    setUp(() {
      analysis = CategoryAnalysis();
    });

    test('handles empty list', () {
      analysis.ingest([]);
      expect(analysis.result(), isEmpty);
    });

    test('aggregates single category', () {
      final txs = [
        createTx(id: '1', amount: 10000),
        createTx(id: '2', amount: 20000),
      ];

      analysis.ingest(txs);
      final result = analysis.result();

      expect(result.length, 1);
      expect(result['식비']!.count, 2);
      expect(result['식비']!.totalAmount, 30000);
    });

    test('separates different main categories', () {
      final txs = [
        createTx(id: '1', amount: 10000),
        createTx(id: '2', amount: 5000, mainCategory: '교통'),
      ];

      analysis.ingest(txs);
      final result = analysis.result();

      expect(result.length, 2);
      expect(result['식비']!.totalAmount, 10000);
      expect(result['교통']!.totalAmount, 5000);
    });

    test('separates sub categories with dot notation', () {
      final txs = [
        createTx(
          id: '1',
          amount: 10000,
          subCategory: '외식',
        ),
        createTx(
          id: '2',
          amount: 5000,
          subCategory: '장보기',
        ),
      ];

      analysis.ingest(txs);
      final result = analysis.result();

      expect(result.length, 2);
      expect(result['식비·외식']!.totalAmount, 10000);
      expect(result['식비·장보기']!.totalAmount, 5000);
    });

    test('tracks refund separately', () {
      final txs = [
        createTx(id: '1', amount: 10000, mainCategory: '쇼핑'),
        createTx(id: '2', amount: -3000, mainCategory: '쇼핑', isRefund: true),
      ];

      analysis.ingest(txs);
      final result = analysis.result();

      expect(result['쇼핑']!.count, 2);
      expect(result['쇼핑']!.refundCount, 1);
      expect(result['쇼핑']!.refundAmount, -3000);
    });

    test('uses default category for empty main category', () {
      final tx = Transaction(
        id: '1',
        type: TransactionType.expense,
        description: 'test',
        amount: 5000,
        date: now,
        mainCategory: '',
      );

      analysis.ingest([tx]);
      final result = analysis.result();

      expect(result.containsKey('미분류'), isTrue);
    });

    test('clears previous data on new ingest', () {
      analysis.ingest([createTx(id: '1', amount: 10000)]);
      analysis.ingest([createTx(id: '2', amount: 5000, mainCategory: '교통')]);

      final result = analysis.result();

      expect(result.length, 1);
      expect(result.containsKey('교통'), isTrue);
      expect(result.containsKey('식비'), isFalse);
    });
  });

  group('CategoryStats', () {
    test('creates with all fields', () {
      final stats = CategoryStats(
        mainCategory: '식비',
        subCategory: '외식',
        count: 5,
        totalAmount: 50000,
        refundCount: 1,
        refundAmount: -5000,
      );

      expect(stats.mainCategory, '식비');
      expect(stats.subCategory, '외식');
      expect(stats.count, 5);
      expect(stats.totalAmount, 50000);
      expect(stats.refundCount, 1);
      expect(stats.refundAmount, -5000);
    });
  });
}
