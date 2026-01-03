import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/memo_stats_utils.dart';
import 'package:smart_ledger/utils/number_formats.dart';

class MemoStatsScreen extends StatefulWidget {
  const MemoStatsScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<MemoStatsScreen> createState() => _MemoStatsScreenState();
}

class _MemoStatsScreenState extends State<MemoStatsScreen> {
  bool _isLoading = true;
  MemoStatsResult? _result;

  final NumberFormat _currencyFormat = NumberFormats.currency;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await TransactionService().loadTransactions();
    if (!mounted) return;

    final service = TransactionService();
    final txs = service.getTransactions(widget.accountName);
    final result = MemoStatsUtils.memoStats(txs);

    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  String _formatWon(double value) => '${_currencyFormat.format(value)}원';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('메모 통계')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final result =
        _result ??
        const MemoStatsResult(
          totalMemoAmount: 0,
          memoTransactionCount: 0,
          top10: <MemoStatEntry>[],
          topCategoryInsight: null,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('리스크 가치', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  _formatWon(result.totalMemoAmount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '메모된 항목 ${result.memoTransactionCount}건',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('메모 상위 10위', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (result.top10.isEmpty)
          Text(
            '메모가 있는 지출이 없습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...result.top10.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            return Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              child: ListTile(
                dense: true,
                title: Text('$rank. ${item.memo}'),
                subtitle: Text('${item.count}건'),
                trailing: Text(_formatWon(item.totalAmount)),
              ),
            );
          }),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildInsight(theme, result),
          ),
        ),
      ],
    );
  }

  Widget _buildInsight(ThemeData theme, MemoStatsResult result) {
    final insight = result.topCategoryInsight;
    if (insight == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('인사이트', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '분석할 메모 데이터가 없습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('인사이트', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          '메모가 가장 많이 발생한 카테고리: ${insight.mainCategory}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '${insight.memoCount}건 · ${_formatWon(insight.totalAmount)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
