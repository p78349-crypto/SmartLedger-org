import '../models/asset_move.dart';

/// Asset flow statistics for the "내 자산 흐름" feature.
///
/// This utility is intentionally UI-agnostic and can be reused by screens,
/// services, and reports.
class AssetFlowStats {
  final DateTime? start;
  final DateTime? end;

  /// Sum of money flowing into cash-like bucket (e.g. sales).
  final double totalInflow;

  /// Sum of money flowing out from cash-like bucket (e.g. purchases/deposits).
  final double totalOutflow;

  /// Net cash flow: inflow - outflow.
  double get netFlow => totalInflow - totalOutflow;

  final Map<AssetMoveType, double> amountByType;
  final Map<AssetMoveType, int> countByType;

  const AssetFlowStats({
    required this.start,
    required this.end,
    required this.totalInflow,
    required this.totalOutflow,
    required this.amountByType,
    required this.countByType,
  });

  /// Computes asset flow statistics from moves.
  ///
  /// Notes:
  /// - This treats [AssetMoveType.purchase] and [AssetMoveType.deposit] as
  ///   outflows.
  /// - This treats [AssetMoveType.sale] as inflow.
  /// - [AssetMoveType.transfer]/[AssetMoveType.exchange] are treated as neutral
  ///   (internal moves) and excluded from inflow/outflow totals.
  static AssetFlowStats compute(
    Iterable<AssetMove> moves, {
    DateTime? start,
    DateTime? end,
  }) {
    final filtered = _filterByDate(moves, start: start, end: end);

    final amountByType = <AssetMoveType, double>{
      for (final t in AssetMoveType.values) t: 0,
    };
    final countByType = <AssetMoveType, int>{
      for (final t in AssetMoveType.values) t: 0,
    };

    double inflow = 0;
    double outflow = 0;

    for (final m in filtered) {
      amountByType[m.type] = (amountByType[m.type] ?? 0) + m.amount;
      countByType[m.type] = (countByType[m.type] ?? 0) + 1;

      switch (directionOf(m.type)) {
        case AssetFlowDirection.inflow:
          inflow += m.amount;
          break;
        case AssetFlowDirection.outflow:
          outflow += m.amount;
          break;
        case AssetFlowDirection.neutral:
          break;
      }
    }

    return AssetFlowStats(
      start: start,
      end: end,
      totalInflow: inflow,
      totalOutflow: outflow,
      amountByType: Map.unmodifiable(amountByType),
      countByType: Map.unmodifiable(countByType),
    );
  }

  static List<AssetMove> _filterByDate(
    Iterable<AssetMove> moves, {
    required DateTime? start,
    required DateTime? end,
  }) {
    if (start == null && end == null) {
      return List<AssetMove>.from(moves);
    }

    return moves.where((m) {
      final d = m.date;
      if (start != null && d.isBefore(start)) return false;
      if (end != null && d.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// Classifies a move type into cash-flow direction buckets.
  static AssetFlowDirection directionOf(AssetMoveType type) {
    switch (type) {
      case AssetMoveType.sale:
        return AssetFlowDirection.inflow;
      case AssetMoveType.purchase:
      case AssetMoveType.deposit:
        return AssetFlowDirection.outflow;
      case AssetMoveType.transfer:
      case AssetMoveType.exchange:
        return AssetFlowDirection.neutral;
    }
  }

  /// Convenience: outflow-only breakdown ("지출 분리").
  ///
  /// Returns a map that contains only outflow types with non-zero totals.
  Map<AssetMoveType, double> outflowBreakdown() {
    final out = <AssetMoveType, double>{};
    for (final e in amountByType.entries) {
      if (directionOf(e.key) != AssetFlowDirection.outflow) continue;
      if (e.value == 0) continue;
      out[e.key] = e.value;
    }
    return Map.unmodifiable(out);
  }
}

enum AssetFlowDirection { inflow, outflow, neutral }
