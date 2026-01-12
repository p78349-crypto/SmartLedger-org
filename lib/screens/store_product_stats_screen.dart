library store_product_stats_screen;

import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../services/store_alias_service.dart';
import '../services/transaction_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/store_memo_utils.dart';
import '../utils/product_name_utils.dart';

part 'store_product_stats_screen_ui.dart';

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

  String _formatWon(double value) {
    return '${NumberFormats.currency.format(value)}원';
  }

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
  }
