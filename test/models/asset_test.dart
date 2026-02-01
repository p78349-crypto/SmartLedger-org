import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/asset.dart';

void main() {
  group('AssetCategory', () {
    test('stock has correct properties', () {
      expect(AssetCategory.stock.label, '주식');
      expect(AssetCategory.stock.emoji, '📈');
    });

    test('bond has correct properties', () {
      expect(AssetCategory.bond.label, '채권');
      expect(AssetCategory.bond.emoji, '📊');
    });

    test('realEstate has correct properties', () {
      expect(AssetCategory.realEstate.label, '부동산');
      expect(AssetCategory.realEstate.emoji, '🏠');
    });

    test('deposit has correct properties', () {
      expect(AssetCategory.deposit.label, '예금/적금');
      expect(AssetCategory.deposit.emoji, '🏦');
    });

    test('crypto has correct properties', () {
      expect(AssetCategory.crypto.label, '암호화폐');
      expect(AssetCategory.crypto.emoji, '₿');
    });

    test('cash has correct properties', () {
      expect(AssetCategory.cash.label, '현금');
      expect(AssetCategory.cash.emoji, '💵');
    });

    test('other has correct properties', () {
      expect(AssetCategory.other.label, '기타');
      expect(AssetCategory.other.emoji, '📌');
    });
  });

  group('Asset', () {
    test('creates with required fields', () {
      final asset = Asset(id: 'asset-1', name: '삼성전자', amount: 1000000);

      expect(asset.id, 'asset-1');
      expect(asset.name, '삼성전자');
      expect(asset.amount, 1000000);
      expect(asset.category, AssetCategory.other);
      expect(asset.inputType, AssetInputType.simple);
      expect(asset.isInvestment, isFalse);
    });

    test('creates with all fields', () {
      final date = DateTime(2026, 1, 10);
      final asset = Asset(
        id: 'asset-2',
        name: '비트코인',
        amount: 50000000,
        category: AssetCategory.crypto,
        inputType: AssetInputType.detail,
        memo: '장기 보유',
        date: date,
        expectedAnnualRatePct: 15.0,
        targetRatio: 10.0,
        targetAmount: 100000000,
        isInvestment: true,
        costBasis: 40000000,
      );

      expect(asset.category, AssetCategory.crypto);
      expect(asset.memo, '장기 보유');
      expect(asset.date, date);
      expect(asset.expectedAnnualRatePct, 15.0);
      expect(asset.targetRatio, 10.0);
      expect(asset.targetAmount, 100000000);
      expect(asset.isInvestment, isTrue);
      expect(asset.costBasis, 40000000);
    });

    test('copyWith updates specified fields', () {
      final original = Asset(id: 'asset-1', name: '삼성전자', amount: 1000000);

      final updated = original.copyWith(name: 'SK하이닉스', amount: 2000000);

      expect(updated.id, 'asset-1'); // 변경 안됨
      expect(updated.name, 'SK하이닉스');
      expect(updated.amount, 2000000);
    });

    test('copyWith preserves unspecified fields', () {
      final original = Asset(
        id: 'asset-1',
        name: '삼성전자',
        amount: 1000000,
        memo: '장기 투자',
        category: AssetCategory.stock,
      );

      final updated = original.copyWith(amount: 1500000);

      expect(updated.name, '삼성전자');
      expect(updated.memo, '장기 투자');
      expect(updated.category, AssetCategory.stock);
    });
  });

  group('AssetInputType', () {
    test('has simple and detail values', () {
      expect(AssetInputType.values, contains(AssetInputType.simple));
      expect(AssetInputType.values, contains(AssetInputType.detail));
    });
  });
}
