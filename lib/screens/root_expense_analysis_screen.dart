import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/top_level_stats_utils.dart';
import '../widgets/root_summary_card.dart';

/// ROOT 지출 분석 화면
/// 상위 지출·예금 목록과 등록된 고정비용을 표시합니다.
class RootExpenseAnalysisScreen extends StatefulWidget {
  const RootExpenseAnalysisScreen({super.key});

  @override
  State<RootExpenseAnalysisScreen> createState() =>
      _RootExpenseAnalysisScreenState();
}

class _RootExpenseAnalysisScreenState extends State<RootExpenseAnalysisScreen> {
  bool _isLoading = true;
  RootDashboardContext? _context;
  List<RootTransactionEntry> _topOutflows = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final context = TopLevelStatsUtils.buildDashboardContext();
      if (!mounted) return;
      final outflows = TopLevelStatsUtils.buildTopOutflowEntries(
        allTransactions: context.allTransactions,
        transactionAccountMap: context.transactionAccountMap,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _context = context;
        _topOutflows = outflows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final currencyFormat = NumberFormats.currency;
    final dateFormat = DateFormatter.monthDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ROOT 지출 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _context == null
              ? const Center(child: Text('데이터를 불러올 수 없습니다.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._buildTopOutflowsSection(
                        theme: theme,
                        isLandscape: isLandscape,
                        currencyFormat: currencyFormat,
                        dateFormat: dateFormat,
                      ),
                      ..._buildFixedCostsSection(
                        theme: theme,
                        isLandscape: isLandscape,
                        currencyFormat: currencyFormat,
                      ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildTopOutflowsSection({
    required ThemeData theme,
    required bool isLandscape,
    required NumberFormat currencyFormat,
    required DateFormat dateFormat,
  }) {
    return [
      Text('상위 지출·예금', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      if (_topOutflows.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('표시할 거래가 없습니다.'),
          ),
        )
      else
        Card(
          child: Column(
            children: [
              if (isLandscape)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          '내용',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          '계정 · 날짜 · 결제',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '금액',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ..._topOutflows.take(20).map((tx) {
                final accountName = tx.accountName;
                final paymentPart = tx.transaction.paymentMethod.isNotEmpty
                  ? ' · ${tx.transaction.paymentMethod}'
                    : '';
                final datePart = dateFormat.format(tx.transaction.date);
                final subtitle = '$accountName · $datePart$paymentPart';
                final amount = currencyFormat.format(tx.transaction.amount);

                if (isLandscape) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconForType(tx.transaction.type),
                          size: 18,
                          color: _colorForType(tx.transaction.type, theme),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: Text(
                            tx.transaction.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            amount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListTile(
                  leading: Icon(
                    _iconForType(tx.transaction.type),
                    color: _colorForType(tx.transaction.type, theme),
                  ),
                  title: Text(tx.transaction.description),
                  subtitle: Text(subtitle),
                  trailing: Text(amount),
                );
              }),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildFixedCostsSection({
    required ThemeData theme,
    required bool isLandscape,
    required NumberFormat currencyFormat,
  }) {
    final allFixedCosts = _context!.allFixedCosts;

    return [
      const SizedBox(height: 16),
      Text('등록된 고정비용', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      if (allFixedCosts.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('등록된 고정비용이 없습니다.'),
          ),
        )
      else
        Card(
          child: Column(
            children: [
              if (isLandscape)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          '항목',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          '계정 · 정보',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '금액',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ...allFixedCosts.take(30).map((entry) {
                final accountName =
                    entry.accountName.isEmpty ? '미분류' : entry.accountName;
                final subtitle = '$accountName · ${_fixedCostSubtitle(entry.cost)}';
                final amount = currencyFormat.format(entry.cost.amount);

                if (isLandscape) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(IconCatalog.receiptLong, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: Text(
                            entry.cost.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            amount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListTile(
                  leading: const Icon(IconCatalog.receiptLong),
                  title: Text(entry.cost.name),
                  subtitle: Text(subtitle),
                  trailing: Text(amount),
                );
              }),
            ],
          ),
        ),
    ];
  }

  String _fixedCostSubtitle(FixedCost cost) {
    final parts = <String>[];
    if (cost.vendor != null && cost.vendor!.isNotEmpty) {
      parts.add(cost.vendor!);
    }
    if (cost.dueDay != null) {
      parts.add('매월 ${cost.dueDay}일');
    }
    return parts.isEmpty ? '고정비용' : parts.join(' · ');
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return IconCatalog.shoppingCart;
      case TransactionType.savings:
        return IconCatalog.savings;
      default:
        return IconCatalog.receipt;
    }
  }

  Color _colorForType(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.savings:
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
