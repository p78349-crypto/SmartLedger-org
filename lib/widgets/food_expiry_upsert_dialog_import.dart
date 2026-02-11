part of 'food_expiry_upsert_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member

extension FoodExpiryUpsertImport on _FoodExpiryUpsertDialogState {
  String _historySubtitle(ShoppingCartHistoryEntry item) {
    final timeLabel = DateFormat('HH:mm').format(item.at);
    return '${item.quantity}개 / $timeLabel';
  }

  Future<void> _showHistoryPicker() async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) return;

    final history = await UserPrefService.getShoppingCartHistory(
      accountName: accountName,
    );

    if (!mounted) return;

    // Group by date
    final grouped = <String, List<ShoppingCartHistoryEntry>>{};
    for (final entry in history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.at);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '쇼핑 기록에서 가져오기',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: sortedKeys.length,
                    itemBuilder: (ctx, i) {
                      final dateKey = sortedKeys[i];
                      final items = grouped[dateKey]!;
                      return ExpansionTile(
                        title: Text('$dateKey (${items.length}개)'),
                        children: [
                          ...items.map((item) {
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(_historySubtitle(item)),
                              trailing: IconButton(
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _startImport(
                                    items,
                                    startIndex: items.indexOf(item),
                                  );
                                },
                              ),
                            );
                          }),
                          ListTile(
                            title: const Text(
                              '이 날짜의 모든 항목 가져오기',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            leading: const Icon(Icons.playlist_play),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _startImport(items);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startImport(
    List<ShoppingCartHistoryEntry> items, {
    int startIndex = 0,
  }) {
    if (items.isEmpty) return;
    setState(() {
      _importQueue = items.sublist(startIndex);
      _importTotal = _importQueue.length;
    });
    _loadNextFromQueue();
  }

  void _loadNextFromQueue() {
    if (_importQueue.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모든 항목을 가져왔습니다.')));
      }
      return;
    }

    final item = _importQueue.removeAt(0);
    setState(() {
      _nameController.text = item.name;
      _purchaseDate = item.at;
      _pickedExpiryDate = null; // Reset expiry for new item
      _memoController.clear();
      _quantityController.text = item.quantity.toString();
      _unitController.text = '개'; // Default unit for imported items
    });
  }

  void _skipCurrentImport() {
    _loadNextFromQueue();
  }

  void _stopImport() {
    setState(() {
      _importQueue.clear();
      _importTotal = 0;
    });
  }
}
