// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_cart_screen.dart';

/// Extension: recent purchase picker dialog & navigation.
extension ShoppingCartPurchasePicker on _ShoppingCartScreenState {
  void _navigateToDetailedInput() {
    Navigator.of(context).pushNamed(
      AppRoutes.transactionAddDetailed,
      arguments: TransactionAddArgs(accountName: widget.accountName),
    );
  }

  Future<void> _openRecentPurchasePicker() async {
    final history = await UserPrefService.getShoppingCartHistory(
      accountName: widget.accountName,
      limit: 500,
    );

    if (!mounted) return;

    final cutoff = DateTime.now().subtract(const Duration(days: 10));
    final recent = history.where((e) => e.at.isAfter(cutoff)).toList();
    if (recent.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최근 10일 구매 내역이 없습니다.')),
      );
      return;
    }

    recent.sort((a, b) => b.at.compareTo(a.at));
    final selected = <String, bool>{};

    final grouped = <String, List<ShoppingCartHistoryEntry>>{};
    for (final entry in recent) {
      final dateKey = _formatDateLabel(entry.at);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final picked = await showModalBottomSheet<List<ShoppingCartHistoryEntry>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, controller) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final selectedCount =
                    selected.values.where((v) => v).length;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Text('최근 10일 구매 리스트',
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('$selectedCount개 선택'),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: sortedDates.length,
                        itemBuilder: (ctx, dateIndex) {
                          final dateStr = sortedDates[dateIndex];
                          final dateItems = grouped[dateStr]!;
                          final allChecked = dateItems.every(
                            (e) => selected[e.id] == true);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(dateStr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                        Text('${dateItems.length}개 항목',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setSheetState(() {
                                        for (final entry in dateItems) {
                                          selected[entry.id] = !allChecked;
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      allChecked
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 20),
                                    label: Text(
                                      allChecked ? '선택해제' : '전체선택'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact),
                                  ),
                                ],
                              ),
                              children: dateItems.map((entry) {
                                final isChecked =
                                    selected[entry.id] ?? false;
                                final qtyLabel = '${entry.quantity}개';
                                final priceLabel =
                                    CurrencyFormatter.format(entry.unitPrice);
                                return CheckboxListTile(
                                  value: isChecked,
                                  onChanged: (v) {
                                    setSheetState(() {
                                      selected[entry.id] = v ?? false;
                                    });
                                  },
                                  title: Text(entry.name),
                                  subtitle: Text('$qtyLabel · $priceLabel'),
                                  dense: true,
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('취소')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: selectedCount == 0
                                  ? null
                                  : () {
                                      final picked = recent
                                          .where(
                                            (e) => selected[e.id] == true)
                                          .toList();
                                      Navigator.pop(ctx, picked);
                                    },
                              child: const Text('장바구니 추가')),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (picked == null || picked.isEmpty) return;

    final now = DateTime.now();
    final nextItems = List<ShoppingCartItem>.from(_items);

    for (var i = 0; i < picked.length; i++) {
      final entry = picked[i];
      final item = ShoppingCartItem(
        id: 'shop_${now.microsecondsSinceEpoch}_$i',
        name: entry.name,
        quantity: entry.quantity <= 0 ? 1 : entry.quantity,
        unitPrice: entry.unitPrice,
        createdAt: now,
        updatedAt: now,
      );
      nextItems.insert(0, item);
    }

    await _save(nextItems);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${picked.length}개 항목을 장바구니에 추가했습니다.')),
    );
  }
}
