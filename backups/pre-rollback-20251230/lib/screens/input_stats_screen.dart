import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/quick_simple_expense_input_history_service.dart';
import 'package:smart_ledger/services/store_alias_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/benefit_memo_utils.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/memo_stats_utils.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/product_name_utils.dart';
import 'package:smart_ledger/utils/store_memo_utils.dart';

class InputStatsScreen extends StatefulWidget {
  const InputStatsScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<InputStatsScreen> createState() => _InputStatsScreenState();
}

class _InputStatsScreenState extends State<InputStatsScreen> {
  static const int _maxTxScan = 1500;
  static const int _topEmphasisRank = 20;

  bool _isLoading = true;
  MemoStatsResult? _memoThisMonth;
  MemoStatsResult? _memoLookback;
  List<QuickSimpleExpenseInputEntry> _entries = const [];

  List<Transaction> _txs = const [];
  Map<String, String> _storeAliasMap = const <String, String>{};
  String? _selectedStore;
  String? _selectedBenefitStore;

  final _currencyFormat = NumberFormats.currency;

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
    return DateTime(now.year, now.month, 1);
  }

  Future<void> _load() async {
    final scanStart = _startOfLookback();
    final monthStart = _startOfThisMonth();

    await TransactionService().loadTransactions();
    if (!mounted) return;

    final all = List<Transaction>.from(
      TransactionService().getTransactions(widget.accountName),
    );
    all.sort((a, b) => b.date.compareTo(a.date));
    final limited = all.take(_maxTxScan);

    final txs = limited.where((t) => !t.date.isBefore(scanStart)).toList(
          growable: false,
        );

    final aliasMap = await StoreAliasService.loadMap(widget.accountName);

    final memoLookback = MemoStatsUtils.memoStats(txs, topN: 10);
    final txsThisMonth = txs
      .where((t) => !t.date.isBefore(monthStart))
      .toList(growable: false);
    final memoThisMonth = MemoStatsUtils.memoStats(txsThisMonth, topN: 10);

    final allEntries =
        await QuickSimpleExpenseInputHistoryService().loadEntries(
      widget.accountName,
    );

    final entries = allEntries.where((e) {
      return !e.createdAt.isBefore(scanStart);
    }).toList(growable: false);

    if (!mounted) return;

    setState(() {
      _memoThisMonth = memoThisMonth;
      _memoLookback = memoLookback;
      _entries = entries;
      _txs = txs;
      _storeAliasMap = aliasMap;
      _selectedStore = _pickDefaultStore(txs, aliasMap);
      _selectedBenefitStore = _pickDefaultStore(txs, aliasMap);
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

  String _formatWon(double value) => '${_currencyFormat.format(value)}원';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('입력 통계(1달)'),
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
            : _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final memoThisMonth =
        _memoThisMonth ??
        const MemoStatsResult(
          totalMemoAmount: 0,
          memoTransactionCount: 0,
          top10: <MemoStatEntry>[],
          topCategoryInsight: null,
        );

    final memoLookback =
        _memoLookback ??
        const MemoStatsResult(
          totalMemoAmount: 0,
          memoTransactionCount: 0,
          top10: <MemoStatEntry>[],
          topCategoryInsight: null,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('메모', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이번달 메모 지출', style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  _formatWon(memoThisMonth.totalMemoAmount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '(1달) · ${memoThisMonth.memoTransactionCount}건',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '최근 6개월: ${_formatWon(memoLookback.totalMemoAmount)}'
                  ' · ${memoLookback.memoTransactionCount}건',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('간편 지출(1줄)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildQuickInputSummary(theme),
        const SizedBox(height: 20),
        Text('혜택(제시-실결제)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildStoreBenefitStats(theme),
        const SizedBox(height: 12),
        _buildBenefitTypeStats(theme),
        const SizedBox(height: 12),
        _buildBenefitTypeByStoreStats(theme),
        const SizedBox(height: 20),
        Text('마트별 제품', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildStoreProductStats(theme),
      ],
    );
  }

  Widget _buildBenefitTypeByStoreStats(ThemeData theme) {
    final txs = _txs;
    if (txs.isEmpty) {
      return Text(
        '최근 6개월 내 거래가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final monthStart = _startOfThisMonth();

    Map<String, double> mapFor(Transaction t) {
      final structured = BenefitMemoUtils.decodeBenefitJson(t.benefitJson);
      if (structured.isNotEmpty) return structured;

      final memo = BenefitMemoUtils.parseBenefitByType(t.memo);
      if (memo.isNotEmpty) return memo;

      final charged = t.cardChargedAmount;
      if (charged != null && charged > 0) {
        final diff = t.amount - charged;
        if (diff > 0) {
          return <String, double>{'제시-실결제': diff};
        }
      }

      return const <String, double>{};
    }

    final storeSet = <String>{};
    final lookback = <String, Map<String, _AggAcc>>{};
    final thisMonth = <String, Map<String, _AggAcc>>{};

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final store = _resolvedStoreKeyOf(t);
      if (store == null || store.trim().isEmpty) continue;

      final byType = mapFor(t);
      if (byType.isEmpty) continue;

      storeSet.add(store);

      final storeLook = lookback.putIfAbsent(store, () => <String, _AggAcc>{});
      final storeMonth = thisMonth.putIfAbsent(store, () => <String, _AggAcc>{});

      for (final e in byType.entries) {
        final key = e.key.trim();
        final value = e.value;
        if (key.isEmpty) continue;
        if (value <= 0) continue;

        final acc = storeLook.putIfAbsent(key, () => _AggAcc(name: key));
        acc.total += value;
        acc.count += 1;

        if (!t.date.isBefore(monthStart)) {
          final accM = storeMonth.putIfAbsent(key, () => _AggAcc(name: key));
          accM.total += value;
          accM.count += 1;
        }
      }
    }

    if (storeSet.isEmpty) {
      return Text(
        '표시할 혜택 데이터가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final storeList = storeSet.toList(growable: false)..sort();
    final selected = (_selectedBenefitStore != null && storeSet.contains(_selectedBenefitStore))
        ? _selectedBenefitStore!
        : storeList.first;

    final lookMap = lookback[selected] ?? const <String, _AggAcc>{};
    final monthMap = thisMonth[selected] ?? const <String, _AggAcc>{};

    final lookItems = lookMap.values
        .map((a) => _AggStat(name: a.name, count: a.count, totalAmount: a.total))
        .toList(growable: false)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final monthItems = monthMap.values
        .map((a) => _AggStat(name: a.name, count: a.count, totalAmount: a.total))
        .toList(growable: false)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final thisMonthTotal = monthItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );
    final lookbackTotal = lookItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );

    final maxAmount = lookItems.isEmpty ? 0.0 : lookItems.first.totalAmount;
    final denom = (maxAmount <= 0 ? 1.0 : maxAmount);

    final top = lookItems.take(10).toList(growable: false);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('쇼핑몰별 혜택 종류', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(selected),
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: '쇼핑몰/매장 선택',
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
                  _selectedBenefitStore = v;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              '이번달 합계: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '최근 6개월: ${_formatWon(lookbackTotal)} · ${lookItems.length}종류',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (top.isEmpty)
              Text(
                '선택한 쇼핑몰의 혜택 데이터가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...top.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                return _buildRankRow(
                  theme,
                  rank: rank,
                  title: item.name,
                  amount: item.totalAmount,
                  count: item.count,
                  denom: denom,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitTypeStats(ThemeData theme) {
    final txs = _txs;
    if (txs.isEmpty) {
      return Text(
        '최근 6개월 내 거래가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final monthStart = _startOfThisMonth();

    final lookbackByType = <String, _AggAcc>{};
    final thisMonthByType = <String, _AggAcc>{};

    Map<String, double> mapFor(Transaction t) {
      final structured = BenefitMemoUtils.decodeBenefitJson(t.benefitJson);
      if (structured.isNotEmpty) return structured;

      final memo = BenefitMemoUtils.parseBenefitByType(t.memo);
      if (memo.isNotEmpty) return memo;

      final charged = t.cardChargedAmount;
      if (charged != null && charged > 0) {
        final diff = t.amount - charged;
        if (diff > 0) {
          return <String, double>{'제시-실결제': diff};
        }
      }

      return const <String, double>{};
    }

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final byType = mapFor(t);
      if (byType.isEmpty) continue;

      for (final e in byType.entries) {
        final key = e.key.trim();
        final value = e.value;
        if (key.isEmpty) continue;
        if (value <= 0) continue;

        final acc = lookbackByType.putIfAbsent(
          key,
          () => _AggAcc(name: key),
        );
        acc.total += value;
        acc.count += 1;

        if (!t.date.isBefore(monthStart)) {
          final accMonth = thisMonthByType.putIfAbsent(
            key,
            () => _AggAcc(name: key),
          );
          accMonth.total += value;
          accMonth.count += 1;
        }
      }
    }

    if (lookbackByType.isEmpty) {
      return Text(
        '표시할 혜택 데이터가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final lookbackItems = lookbackByType.values
        .map((a) => _AggStat(name: a.name, count: a.count, totalAmount: a.total))
        .toList(growable: false)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final monthItems = thisMonthByType.values
        .map((a) => _AggStat(name: a.name, count: a.count, totalAmount: a.total))
        .toList(growable: false)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final thisMonthTotal = monthItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );
    final lookbackTotal = lookbackItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );

    final denom = (lookbackItems.isEmpty ? 1.0 : lookbackItems.first.totalAmount)
        .clamp(1.0, double.infinity);

    final top = lookbackItems.take(10).toList(growable: false);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('혜택 종류별 상위10', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              '이번달 합계: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '최근 6개월: ${_formatWon(lookbackTotal)} · ${lookbackItems.length}종류',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...top.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              return _buildRankRow(
                theme,
                rank: rank,
                title: item.name,
                amount: item.totalAmount,
                count: item.count,
                denom: denom,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreBenefitStats(ThemeData theme) {
    final txs = _txs;
    if (txs.isEmpty) {
      return Text(
        '최근 6개월 내 거래가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final monthStart = _startOfThisMonth();

    final lookbackByStore = <String, _AggAcc>{};
    final thisMonthByStore = <String, _AggAcc>{};

    var structuredBenefitThisMonth = 0.0;
    var structuredBenefitLookback = 0.0;
    var memoBenefitThisMonth = 0.0;
    var memoBenefitLookback = 0.0;

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final store = _resolvedStoreKeyOf(t);
      if (store == null || store.trim().isEmpty) continue;

      // Priority (no double counting):
      // 1) cardChargedAmount => benefit = amount - charged
      // 2) benefitJson       => benefit = sum(benefitJson)
      // 3) memo "혜택:"      => benefit = sum(parsed memo)
      double benefit = 0.0;

      final charged = t.cardChargedAmount;
      if (charged != null && charged > 0) {
        benefit = t.amount - charged;
      } else {
        final structuredMap = BenefitMemoUtils.decodeBenefitJson(t.benefitJson);
        if (structuredMap.isNotEmpty) {
          benefit = structuredMap.values.fold<double>(0, (s, v) => s + v);
          if (benefit > 0) {
            structuredBenefitLookback += benefit;
            if (!t.date.isBefore(monthStart)) {
              structuredBenefitThisMonth += benefit;
            }
          }
        } else {
          final memoMap = BenefitMemoUtils.parseBenefitByType(t.memo);
          if (memoMap.isNotEmpty) {
            benefit = memoMap.values.fold<double>(0, (s, v) => s + v);
            if (benefit > 0) {
              memoBenefitLookback += benefit;
              if (!t.date.isBefore(monthStart)) {
                memoBenefitThisMonth += benefit;
              }
            }
          }
        }
      }

      if (benefit <= 0) continue;

      final accLookback = lookbackByStore.putIfAbsent(
        store,
        () => _AggAcc(name: store),
      );
      accLookback.count += 1;
      accLookback.total += benefit;

      if (!t.date.isBefore(monthStart)) {
        final accMonth = thisMonthByStore.putIfAbsent(
          store,
          () => _AggAcc(name: store),
        );
        accMonth.count += 1;
        accMonth.total += benefit;
      }
    }

    if (lookbackByStore.isEmpty) {
      return Text(
        '표시할 혜택 데이터가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final monthItems = thisMonthByStore.values
        .map((a) => _AggStat(name: a.name, count: a.count, totalAmount: a.total))
        .toList(growable: false)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final lookbackItems = lookbackByStore.values
        .map((a) => _AggStat(name: a.name, count: a.count, totalAmount: a.total))
        .toList(growable: false)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final thisMonthTotal = monthItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );
    final lookbackTotal = lookbackItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );

    final denom = (lookbackItems.isEmpty ? 1.0 : lookbackItems.first.totalAmount)
        .clamp(1.0, double.infinity);

    final top = lookbackItems.take(10).toList(growable: false);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('쇼핑몰/매장별 혜택 상위10', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              '이번달 혜택: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (structuredBenefitThisMonth > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '이번달 직접입력 혜택: ${_formatWon(structuredBenefitThisMonth)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (memoBenefitThisMonth > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '이번달 메모 혜택: ${_formatWon(memoBenefitThisMonth)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '최근 6개월: ${_formatWon(lookbackTotal)} · ${lookbackItems.length}곳',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (structuredBenefitLookback > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '최근 6개월 직접입력 혜택: ${_formatWon(structuredBenefitLookback)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (memoBenefitLookback > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '최근 6개월 메모 혜택: ${_formatWon(memoBenefitLookback)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ...top.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              return _buildRankRow(
                theme,
                rank: rank,
                title: item.name,
                amount: item.totalAmount,
                count: item.count,
                denom: denom,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRankRow(
    ThemeData theme, {
    required int rank,
    required String title,
    required double amount,
    required int count,
    required double denom,
  }) {
    final scheme = theme.colorScheme;
    final emphasized = rank <= _topEmphasisRank;
    final pct = (amount / denom).clamp(0.0, 1.0);

    final textColor = emphasized ? null : scheme.onSurfaceVariant;
    final barColor = emphasized
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.22);
    final trackColor = emphasized
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.onSurfaceVariant.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$rank. $title',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatWon(amount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor ?? scheme.onSurfaceVariant,
                  fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
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
              color: barColor,
              backgroundColor: trackColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
              '$count건',
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor ?? scheme.onSurfaceVariant,
            ),
          ),
        ],
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

    final stats = _buildStoreProductAgg(txs, selected, monthStart);
    final maxAmount = stats
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
            const SizedBox(height: 10),
            Text(
              '이번달 총액: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
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
            if (stats.isEmpty)
              Text(
                '이번달 제품 데이터가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...stats.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                return _buildRankRow(
                  theme,
                  rank: rank,
                  title: item.name,
                  amount: item.totalAmount,
                  count: item.count,
                  denom: denom,
                );
              }),
          ],
        ),
      ),
    );
  }

  List<_AggStat> _buildStoreProductAgg(
    List<Transaction> txs,
    String store,
    DateTime start,
  ) {
    final byKey = <String, _AggAcc>{};
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
        () => _AggAcc(name: t.description.trim()),
      );
      acc.count += 1;
      acc.total += t.amount;

      final name = t.description.trim();
      if (name.isNotEmpty && acc.name.length < name.length) {
        acc.name = name;
      }
    }

    final items = byKey.values
        .map((a) => _AggStat(name: a.name, count: a.count, totalAmount: a.total))
        .toList(growable: false)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return items;
  }

  Widget _buildQuickInputSummary(ThemeData theme) {
    if (_entries.isEmpty) {
      return Text(
        '최근 6개월 내 저장된 1줄 입력이 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final monthStart = _startOfThisMonth();
    final thisMonthEntries = _entries
        .where((e) => !e.createdAt.isBefore(monthStart))
        .toList(growable: false);

    var thisMonthTotal = 0.0;
    for (final e in thisMonthEntries) {
      thisMonthTotal += e.amount;
    }

    final byKey = <String, _QuickAgg>{};
    for (final e in thisMonthEntries) {
      final key = ProductNameUtils.normalizeKey(e.description);
      if (key.isEmpty) continue;

      final acc = byKey.putIfAbsent(
        key,
        () => _QuickAgg(name: e.description.trim()),
      );
      acc.count += 1;
      acc.totalAmount += e.amount;

      final name = e.description.trim();
      if (name.isNotEmpty && acc.name.length < name.length) {
        acc.name = name;
      }
    }

    final top20 = byKey.values
        .map((a) => _QuickAggView(name: a.name, count: a.count, total: a.totalAmount))
        .toList(growable: false)
      ..sort((a, b) => b.total.compareTo(a.total));
    final topList = top20.take(_topEmphasisRank).toList(growable: false);
    final restList = top20.length > _topEmphasisRank
        ? top20.sublist(_topEmphasisRank)
        : const <_QuickAggView>[];

    final maxAmount = top20
        .map((e) => e.total)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final denom = maxAmount <= 0 ? 1.0 : maxAmount;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('간편지출 상위20', style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(
              '이번달 총액: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(1달) · 이번달 ${thisMonthEntries.length}건 · 전체(6개월) ${_entries.length}건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (topList.isEmpty)
              Text(
                '이번달 저장된 1줄 입력이 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              ...top20.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                return _buildRankRow(
                  theme,
                  rank: rank,
                  title: item.name,
                  amount: item.total,
                  count: item.count,
                  denom: denom,
                );
              }),
              if (restList.isNotEmpty)
                Text(
                  '(21위부터는 중요도 낮음)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

}

class _QuickAgg {
  String name;
  int count = 0;
  double totalAmount = 0;

  _QuickAgg({required this.name});
}

class _QuickAggView {
  final String name;
  final int count;
  final double total;

  const _QuickAggView({
    required this.name,
    required this.count,
    required this.total,
  });
}

class _AggStat {
  final String name;
  final int count;
  final double totalAmount;

  const _AggStat({
    required this.name,
    required this.count,
    required this.totalAmount,
  });
}

class _AggAcc {
  String name;
  int count = 0;
  double total = 0;

  _AggAcc({required this.name});
}

