import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/asset_move.dart';
import 'package:smart_ledger/utils/asset_flow_stats.dart';

void main() {
  group('AssetFlowStats', () {
    test('directionOf maps types to buckets', () {
      expect(
        AssetFlowStats.directionOf(AssetMoveType.sale),
        AssetFlowDirection.inflow,
      );
      expect(
        AssetFlowStats.directionOf(AssetMoveType.purchase),
        AssetFlowDirection.outflow,
      );
      expect(
        AssetFlowStats.directionOf(AssetMoveType.deposit),
        AssetFlowDirection.outflow,
      );
      expect(
        AssetFlowStats.directionOf(AssetMoveType.transfer),
        AssetFlowDirection.neutral,
      );
      expect(
        AssetFlowStats.directionOf(AssetMoveType.exchange),
        AssetFlowDirection.neutral,
      );
    });

    test('compute sums inflow/outflow and ignores neutral types', () {
      final moves = <AssetMove>[
        AssetMove(
          id: '1',
          accountName: 'A',
          fromAssetId: 'cash',
          amount: 100,
          type: AssetMoveType.purchase,
          memo: 'buy',
          date: DateTime(2025, 12, 1),
        ),
        AssetMove(
          id: '2',
          accountName: 'A',
          fromAssetId: 'stock',
          amount: 40,
          type: AssetMoveType.sale,
          memo: 'sell',
          date: DateTime(2025, 12, 2),
        ),
        AssetMove(
          id: '3',
          accountName: 'A',
          fromAssetId: 'cash',
          amount: 10,
          type: AssetMoveType.deposit,
          memo: 'deposit',
          date: DateTime(2025, 12, 3),
        ),
        AssetMove(
          id: '4',
          accountName: 'A',
          fromAssetId: 'cash',
          toAssetId: 'savings',
          amount: 999,
          type: AssetMoveType.transfer,
          memo: 'internal move',
          date: DateTime(2025, 12, 4),
        ),
      ];

      final stats = AssetFlowStats.compute(moves);

      expect(stats.totalInflow, 40);
      expect(stats.totalOutflow, 110);
      expect(stats.netFlow, -70);

      // Totals by type are still tracked.
      expect(stats.amountByType[AssetMoveType.transfer], 999);

      // Outflow breakdown only includes outflow types.
      final outflow = stats.outflowBreakdown();
      expect(outflow.keys.toSet(), {
        AssetMoveType.purchase,
        AssetMoveType.deposit,
      });
      expect(outflow[AssetMoveType.purchase], 100);
      expect(outflow[AssetMoveType.deposit], 10);
    });

    test('compute respects start/end filter (inclusive boundaries)', () {
      final moves = <AssetMove>[
        AssetMove(
          id: '1',
          accountName: 'A',
          fromAssetId: 'cash',
          amount: 100,
          type: AssetMoveType.purchase,
          date: DateTime(2025, 12, 1),
        ),
        AssetMove(
          id: '2',
          accountName: 'A',
          fromAssetId: 'stock',
          amount: 40,
          type: AssetMoveType.sale,
          date: DateTime(2025, 12, 10),
        ),
      ];

      final stats = AssetFlowStats.compute(
        moves,
        start: DateTime(2025, 12, 10),
        end: DateTime(2025, 12, 10),
      );

      expect(stats.totalInflow, 40);
      expect(stats.totalOutflow, 0);
      expect(stats.netFlow, 40);
    });
  });
}
