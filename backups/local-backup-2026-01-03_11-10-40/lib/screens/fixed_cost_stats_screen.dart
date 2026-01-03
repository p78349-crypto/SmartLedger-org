import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/fixed_cost_service.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/stats_labels.dart';

class FixedCostStatsScreen extends StatefulWidget {
  final String accountName;
  const FixedCostStatsScreen({super.key, required this.accountName});

  @override
  State<FixedCostStatsScreen> createState() => _FixedCostStatsScreenState();
}

class _FixedCostStatsScreenState extends State<FixedCostStatsScreen> {
  final NumberFormat _currencyFormat = NumberFormats.currency;
  bool _isLoading = true;
  List<FixedCost> _fixedCosts = [];

  String _fixedCostMeta(FixedCost cost) {
    final parts = <String>[];
    if (cost.paymentMethod.isNotEmpty) parts.add(cost.paymentMethod);
    if (cost.vendor != null && cost.vendor!.isNotEmpty) {
      parts.add(cost.vendor!);
    }
    if (cost.memo != null && cost.memo!.isNotEmpty) {
      parts.add(cost.memo!);
    }
    return parts.join(' · ');
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await FixedCostService().loadFixedCosts();
    if (!mounted) return;

    final service = FixedCostService();
    final costs = service.getFixedCosts(widget.accountName);

    setState(() {
      _fixedCosts = costs;
      _isLoading = false;
    });
  }

  double get _monthlyTotal {
    return _fixedCosts.fold<double>(0.0, (sum, cost) => sum + cost.amount);
  }

  double get _yearlyTotal => _monthlyTotal * 12;

  List<FixedCost> get _sortedCosts {
    final list = List<FixedCost>.from(_fixedCosts);
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(StatsLabels.fixedCostStats)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_fixedCosts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(StatsLabels.fixedCostStats)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                '등록된 고정비가 없습니다',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(StatsLabels.fixedCostStats),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '고정비 관리',
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.fixedCostTab,
                arguments: AccountArgs(accountName: widget.accountName),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 월간 합계 카드
            Card(
              color: theme.colorScheme.primaryContainer.withAlpha(100),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('월간 고정비', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '-${_currencyFormat.format(_monthlyTotal)}원',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fixedCosts.length}개 항목',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 연간 합계 카드
            Card(
              color: theme.colorScheme.errorContainer.withAlpha(100),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('연간 고정비', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '-${_currencyFormat.format(_yearlyTotal)}원',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '월 ${_currencyFormat.format(_monthlyTotal)}원 × 12개월',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 항목별 상세
            Text('항목별 고정비', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),

            ..._sortedCosts.map((cost) {
              final percentage = _monthlyTotal > 0
                  ? (cost.amount / _monthlyTotal * 100)
                  : 0.0;
              final meta = _fixedCostMeta(cost);
              final yearlyLabel =
                  '연간: -${_currencyFormat.format(cost.amount * 12)}원';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isLandscape
                      ? Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                cost.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (cost.dueDay != null)
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '매월 ${cost.dueDay}일',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            else
                              const Spacer(flex: 2),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '-${_currencyFormat.format(cost.amount)}원',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cost.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  '-${_currencyFormat.format(cost.amount)}원',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 진행률 바
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 8,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${percentage.toStringAsFixed(1)}% of '
                                    '월간 고정비',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (cost.dueDay != null)
                                  Text(
                                    '매월 ${cost.dueDay}일',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                              ],
                            ),

                            if (cost.paymentMethod.isNotEmpty ||
                                (cost.vendor != null &&
                                    cost.vendor!.isNotEmpty) ||
                                (cost.memo != null &&
                                    cost.memo!.isNotEmpty)) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (cost.paymentMethod.isNotEmpty)
                                    Chip(
                                      label: Text(cost.paymentMethod),
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: theme.textTheme.bodySmall,
                                    ),
                                  if (cost.vendor != null &&
                                      cost.vendor!.isNotEmpty)
                                    Chip(
                                      label: Text(cost.vendor!),
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: theme.textTheme.bodySmall,
                                    ),
                                  if (cost.memo != null &&
                                      cost.memo!.isNotEmpty)
                                    Chip(
                                      label: Text(cost.memo!),
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ],

                            // 연간 금액
                            const SizedBox(height: 8),
                            Text(
                              yearlyLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
