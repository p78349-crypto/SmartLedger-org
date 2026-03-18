import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../models/trash_entry.dart';
import '../utils/utils.dart';

/// Filter chips for trash entity types.
class TrashFilterChips extends StatelessWidget {
  const TrashFilterChips({
    super.key,
    required this.filterType,
    required this.onChanged,
  });

  final TrashEntityType? filterType;
  final ValueChanged<TrashEntityType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('전체'),
          selected: filterType == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final type in TrashEntityType.values)
          FilterChip(
            label: Text(labelForType(type)),
            selected: filterType == type,
            onSelected: (_) => onChanged(type),
          ),
      ],
    );
  }
}

/// Returns a human label for [TrashEntityType].
String labelForType(TrashEntityType type) {
  switch (type) {
    case TrashEntityType.transaction:
      return '거래';
    case TrashEntityType.asset:
      return '자산';
    case TrashEntityType.account:
      return '계정';
  }
}

/// Returns an icon for [TrashEntityType].
IconData iconForType(TrashEntityType type) {
  switch (type) {
    case TrashEntityType.transaction:
      return Icons.receipt_long;
    case TrashEntityType.asset:
      return Icons.account_balance_wallet;
    case TrashEntityType.account:
      return Icons.admin_panel_settings;
  }
}

/// Returns a display title for a [TrashEntry].
String titleForEntry(TrashEntry entry) {
  switch (entry.entityType) {
    case TrashEntityType.transaction:
      final tx = Transaction.fromJson(entry.payload);
      final amount = CurrencyFormatter.format(tx.amount, showUnit: false);
      return '${tx.description} (${tx.type.sign}$amount원)';
    case TrashEntityType.asset:
      final asset = Asset.fromJson(entry.payload);
      return '${asset.name}'
          ' (${CurrencyFormatter.format(asset.amount)})';
    case TrashEntityType.account:
      return '${entry.accountName} 계정 백업';
  }
}

/// Landscape header row for trash list.
class TrashLandscapeHeader extends StatelessWidget {
  const TrashLandscapeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 24),
          SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              '항목',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              '계정',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              '삭제 시각',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
            ),
          ),
          SizedBox(width: 80),
        ],
      ),
    );
  }
}
