import 'package:flutter/material.dart';

import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/store_alias_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/product_name_utils.dart';
import 'package:smart_ledger/utils/store_memo_utils.dart';

class StoreProductStatsScreen extends StatefulWidget {
  const StoreProductStatsScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<StoreProductStatsScreen> createState() =>
      _StoreProductStatsScreenState();
}

class _StoreProductStatsScreenState extends State<StoreProductStatsScreen> {
  static const int _maxTxScan = 1500;

  bool _isLoading = true;

  List<Transaction> _txs = const [];
  Map<String, String> _storeAliasMap = const <String, String>{};
  String? _selectedStore;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _startOfLookback() {
    final now = DateTime.now();
    return now.subtract(const Duration(days: 183));
  }

  DateTime _startOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _load() async {
    final scanStart = _startOfLookback();

    await TransactionService().loadTransactions();
    if (!mounted) return;

    final all = List<Transaction>.from(
      TransactionService().getTransactions(widget.accountName),
    );
    all.sort((a, b) => b.date.compareTo(a.date));
    final limited = all.take(_maxTxScan);

    final txs = limited
        .where((t) => !t.date.isBefore(scanStart))
        .toList(growable: false);

    final aliasMap = await StoreAliasService.loadMap(widget.accountName);

    if (!mounted) return;

    setState(() {
      _txs = txs;
      _storeAliasMap = aliasMap;
      _selectedStore = _pickDefaultStore(txs, aliasMap);
      _isLoading = false;
    });
  }

  String? _pickDefaultStore(
    List<Transaction> txs,
    Map<String, String> aliasMap,
  ) {
    final counts = <String, int>{};
    for (final t in txs) {
      final store = _storeKeyOf(t);
      if (store == null) continue;
      final canonical = StoreAliasService.resolve(store, aliasMap);
      counts[canonical] = (counts[canonical] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final ranked = counts.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.first.key;
  }

  String? _storeKeyOf(Transaction t) {
    final store = t.store?.trim();
    if (store != null && store.isNotEmpty) return store;
    return StoreMemoUtils.extractStoreKey(t.memo);
  }

  String? _resolvedStoreKeyOf(Transaction t) {
    final raw = _storeKeyOf(t);
    if (raw == null) return null;
    return StoreAliasService.resolve(raw, _storeAliasMap);
  }

  String _formatWon(double value) => '${NumberFormats.currency.format(value)}원';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마트별 제품'),
        actions: [
          IconButton(
            tooltip: '마트명 병합/정리',
            icon: const Icon(IconCatalog.compareArrows),
            onPressed: () async {
              await Navigator.of(context).pushNamed(
                AppRoutes.storeMerge,
                arguments: AccountArgs(accountName: widget.accountName),
              );
              if (!mounted) return;
              await _load();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [_buildStoreProductStats(theme)],
              ),
      ),
    );
  }

  Widget _buildStoreProductStats(ThemeData theme) {
    final txs = _txs;
    if (txs.isEmpty) {
      return Text(
        '최근 6개월 내 거래가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final stores = <String>{};
    for (final t in txs) {
      final store = _resolvedStoreKeyOf(t);
      if (store == null) continue;
      stores.add(store);
    }
    final storeList = stores.toList(growable: false)..sort();

    if (storeList.isEmpty) {
      return Text(
        '마트명이 메모에 기록된 거래가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final selected = (_selectedStore != null && stores.contains(_selectedStore))
        ? _selectedStore!
        : storeList.first;

    final monthStart = _startOfThisMonth();
    final thisMonthStats = _buildProductStatsForStore(
      txs,
      selected,
      start: monthStart,
    );

    var thisMonthTotal = 0.0;
    var thisMonthCount = 0;
    var lookbackTotal = 0.0;
    var lookbackCount = 0;

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final storeKey = _resolvedStoreKeyOf(t);
      if (storeKey == null || storeKey != selected) continue;

      lookbackCount += 1;
      lookbackTotal += t.amount;

      if (t.date.isBefore(monthStart)) continue;

      thisMonthCount += 1;
      thisMonthTotal += t.amount;
    }

    final maxAmount = thisMonthStats
        .map((e) => e.totalAmount)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final denom = maxAmount <= 0 ? 1.0 : maxAmount;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('마트별 제품 상위20', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              '이번달 총액: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(1달) · 이번달 $thisMonthCount건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '최근 6개월: ${_formatWon(lookbackTotal)} · $lookbackCount건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(selected),
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: '마트 선택',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final s in storeList)
                  DropdownMenuItem<String>(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedStore = v;
                });
              },
            ),
            const SizedBox(height: 12),
            if (thisMonthStats.isEmpty)
              Text(
                '이번달 제품 데이터가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...thisMonthStats.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                final pct = (item.totalAmount / denom).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$rank. ${item.name}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatWon(item.totalAmount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: pct,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.count}건',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  List<_StoreProductStat> _buildProductStatsForStore(
    List<Transaction> txs,
    String store, {
    required DateTime start,
  }) {
    final byKey = <String, _StoreProductStatAccumulator>{};
    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;
      if (t.date.isBefore(start)) continue;

      final storeKey = _resolvedStoreKeyOf(t);
      if (storeKey == null || storeKey != store) continue;

      final key = ProductNameUtils.normalizeKey(t.description);
      if (key.isEmpty) continue;

      final acc = byKey.putIfAbsent(
        key,
        () => _StoreProductStatAccumulator(name: t.description.trim()),
      );
      acc.count += 1;
      acc.totalAmount += t.amount;

      final name = t.description.trim();
      if (name.isNotEmpty && acc.name.length < name.length) {
        acc.name = name;
      }
    }

    final items =
        byKey.values
            .map(
              (a) => _StoreProductStat(
                name: a.name,
                count: a.count,
                totalAmount: a.totalAmount,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return items.take(20).toList(growable: false);
  }
}

class _StoreProductStat {
  final String name;
  final int count;
  final double totalAmount;

  const _StoreProductStat({
    required this.name,
    required this.count,
    required this.totalAmount,
  });
}

class _StoreProductStatAccumulator {
  String name;
  int count = 0;
  double totalAmount = 0;

  _StoreProductStatAccumulator({required this.name});
}
