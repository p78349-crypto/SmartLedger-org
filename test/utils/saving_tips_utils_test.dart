import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/saving_tips_utils.dart';

void main() {
  group('SavingTipType', () {
    test('has expected values', () {
      expect(SavingTipType.values.length, 8);
      expect(SavingTipType.challenge, isNotNull);
      expect(SavingTipType.comparison, isNotNull);
      expect(SavingTipType.timing, isNotNull);
      expect(SavingTipType.alternative, isNotNull);
      expect(SavingTipType.habit, isNotNull);
      expect(SavingTipType.bulk, isNotNull);
      expect(SavingTipType.subscription, isNotNull);
      expect(SavingTipType.loyalty, isNotNull);
    });
  });

  group('SavingTip', () {
    test('creates with required fields', () {
      const tip = SavingTip(
        title: '테스트 팁',
        description: '설명',
        type: SavingTipType.challenge,
      );

      expect(tip.title, '테스트 팁');
      expect(tip.description, '설명');
      expect(tip.type, SavingTipType.challenge);
    });

    test('has default values for optional fields', () {
      const tip = SavingTip(
        title: '테스트',
        description: '설명',
        type: SavingTipType.habit,
      );

      expect(tip.category, isNull);
      expect(tip.estimatedMonthlySaving, isNull);
      expect(tip.actionItems, isEmpty);
      expect(tip.priority, 5);
      expect(tip.relatedItem, isNull);
    });

    test('accepts all optional fields', () {
      const tip = SavingTip(
        title: '팁',
        description: '설명',
        type: SavingTipType.bulk,
        category: '식비',
        estimatedMonthlySaving: 50000,
        actionItems: ['항목1', '항목2'],
        priority: 1,
        relatedItem: '커피',
      );

      expect(tip.category, '식비');
      expect(tip.estimatedMonthlySaving, 50000);
      expect(tip.actionItems.length, 2);
      expect(tip.priority, 1);
      expect(tip.relatedItem, '커피');
    });
  });

  group('SavingTipsDatabase', () {
    test('diningOutTips is not empty', () {
      expect(SavingTipsDatabase.diningOutTips, isNotEmpty);
    });

    test('diningOutTips have correct category', () {
      for (final tip in SavingTipsDatabase.diningOutTips) {
        expect(tip.category, '외식');
      }
    });

    test('all tips have title and description', () {
      for (final tip in SavingTipsDatabase.diningOutTips) {
        expect(tip.title, isNotEmpty);
        expect(tip.description, isNotEmpty);
      }
    });
  });
}
