import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../utils/number_formats.dart';
import '../utils/root_account_summary_aggregation_utils.dart';
import '../utils/top_level_stats_utils.dart';

/// ROOT 계정별 현황 화면
/// 각 계정의 수입/지출/예금/순이익을 한눈에 보여줍니다.
class RootAccountSummaryScreen extends StatefulWidget {
  const RootAccountSummaryScreen({super.key});

  @override
  State<RootAccountSummaryScreen> createState() =>
      _RootAccountSummaryScreenState();
}

class _RootAccountSummaryScreenState extends State<RootAccountSummaryScreen> {
  bool _isLoading = true;
  RootDashboardContext? _context;
  List<AccountAggregateSummary> _accountSummaries = [];

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
      final summaries =
          RootAccountSummaryAggregationUtils.buildAccountAggregates(context);

      if (!mounted) return;
      setState(() {
        _context = context;
        _accountSummaries = summaries;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('ROOT 계정별 현황'),
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
              child: _accountSummaries.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('등록된 계정이 없습니다.'),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('계정별 현황', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: [
                              if (isLandscape)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '계정',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 7,
                                        child: Text(
                                          '요약',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '순이익',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ..._accountSummaries.map((summary) {
                                return _buildAccountRow(
                                  summary,
                                  theme,
                                  isLandscape,
                                  currencyFormat,
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildAccountRow(
    AccountAggregateSummary summary,
    ThemeData theme,
    bool isLandscape,
    NumberFormat currencyFormat,
  ) {
    final accountName = summary.name.isEmpty ? '미분류' : summary.name;
    final incomeLabel = _formatCurrency(currencyFormat, summary.income);
    final expenseLabel = _formatAmount(currencyFormat, summary.expense);
    final savingsLabel = _formatAmount(currencyFormat, summary.savings);

    final detailParts = [
      '수입 $incomeLabel',
      '지출 $expenseLabel',
      '예금 $savingsLabel',
    ];
    if (summary.refund > 0) {
      final refundLabel = _formatAmount(currencyFormat, summary.refund);
      detailParts.add('반품 $refundLabel');
    }
    if (summary.fixedCost > 0) {
      final fixedCostLabel = _formatAmount(currencyFormat, summary.fixedCost);
      detailParts.add('고정비 $fixedCostLabel');
    }
    final netLabel = _formatCurrency(
      currencyFormat,
      summary.net,
      includeSign: true,
    );
    final detailText = detailParts.join(' · ');

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                accountName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 7,
              child: Text(
                detailText,
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
                netLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: summary.net >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListTile(
      title: Text(accountName),
      subtitle: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            for (var i = 0; i < detailParts.length; i++)
              ...(() {
                final part = detailParts[i];
                if (part.startsWith('예금')) {
                  const label = '예금';
                  final value = part.substring(label.length);
                  return [
                    const TextSpan(
                      text: label,
                      style: TextStyle(color: AppColors.savingsText),
                    ),
                    TextSpan(text: value),
                    if (i < detailParts.length - 1) const TextSpan(text: ' · '),
                  ];
                }
                return [
                  TextSpan(text: part),
                  if (i < detailParts.length - 1) const TextSpan(text: ' · '),
                ];
              })(),
          ],
        ),
      ),
      trailing: Text(
        netLabel,
        style: TextStyle(
          color: summary.net >= 0
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatCurrency(
    NumberFormat format,
    double value, {
    bool includeSign = false,
  }) {
    final sign = includeSign && value > 0 ? '+' : '';
    return '$sign${format.format(value)}';
  }

  String _formatAmount(NumberFormat format, double value) {
    return format.format(value);
  }
}
