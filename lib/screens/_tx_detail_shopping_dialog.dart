part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Shopping-cart picker bottom-sheet dialog builder.
extension TxDetailShoppingDialog on _TransactionAddDetailedFormState {
  Widget _buildShoppingPickerSheet(
    List<ShoppingCartItem> local,
    BuildContext sheetContext,
  ) {
    final grouped = <String, List<ShoppingCartItem>>{};
    for (var it in local) {
      final dateStr =
          '${it.createdAt.year}-${it.createdAt.month.toString().padLeft(2, '0')}-${it.createdAt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateStr, () => []).add(it);
    }
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 640),
          child: Column(
            children: [
              ListTile(
                title: const Text('재구매 예정 항목 선택'),
                trailing: IconButton(
                  icon: const Icon(IconCatalog.close),
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setSheetState) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, dateIndex) {
                        final dateStr = sortedDates[dateIndex];
                        final dateItems = grouped[dateStr]!;

                        return _buildShoppingDateGroup(
                          dateStr,
                          dateItems,
                          local,
                          setSheetState,
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(false),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(true),
                        child: const Text('지출입력 상세 입력하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingDateGroup(
    String dateStr,
    List<ShoppingCartItem> dateItems,
    List<ShoppingCartItem> local,
    StateSetter setSheetState,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${dateItems.length}개 항목',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final allChecked = dateItems.every((e) => e.isChecked);
                  setSheetState(() {
                    for (final it in dateItems) {
                      final originalIdx = local.indexWhere(
                        (element) => element.id == it.id,
                      );
                      if (originalIdx != -1) {
                        local[originalIdx] = it.copyWith(
                          isChecked: !allChecked,
                        );
                        final itemIdx = dateItems.indexWhere(
                          (e) => e.id == it.id,
                        );
                        if (itemIdx != -1) {
                          dateItems[itemIdx] = it.copyWith(
                            isChecked: !allChecked,
                          );
                        }
                      }
                    }
                  });
                },
                icon: Icon(
                  dateItems.every((e) => e.isChecked)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 20,
                ),
                label: Text(
                  dateItems.every((e) => e.isChecked) ? '선택해제' : '전체선택',
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          children: dateItems.map((it) {
            final qty = it.quantity <= 0 ? 1 : it.quantity;
            final unitPriceText = it.unitPrice <= 0
                ? '-'
                : CurrencyFormatter.formatWithDecimals(
                    it.unitPrice,
                    showUnit: false,
                  );
            return CheckboxListTile(
              value: it.isChecked,
              title: Text(it.name),
              subtitle: Text('수량: $qty    단가: $unitPriceText'),
              dense: true,
              onChanged: (v) {
                final originalIdx = local.indexWhere(
                  (element) => element.id == it.id,
                );
                if (originalIdx != -1) {
                  local[originalIdx] = it.copyWith(isChecked: v ?? false);
                  final itemIdx = dateItems.indexWhere(
                    (e) => e.id == it.id,
                  );
                  if (itemIdx != -1) {
                    dateItems[itemIdx] = it.copyWith(isChecked: v ?? false);
                  }
                }
                setSheetState(() {});
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
