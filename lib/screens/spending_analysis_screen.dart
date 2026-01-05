import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/chart_colors.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/period_utils.dart' as period;
import 'package:smart_ledger/utils/saving_tips_utils.dart';
import 'package:smart_ledger/utils/spending_analysis_utils.dart';
import 'package:smart_ledger/widgets/background_widget.dart';

/// 지출 분석 + 절약 팁 화면
///
/// TOP 5 지출 항목, 반복 지출 패턴, 맞춤형 절약 팁을 제공합니다.
class SpendingAnalysisScreen extends StatefulWidget {
  final String accountName;
  final DateTime? initialDate;

  const SpendingAnalysisScreen({
    super.key,
    required this.accountName,
    this.initialDate,
  });

  @override
  State<SpendingAnalysisScreen> createState() => _SpendingAnalysisScreenState();
}

class _SpendingAnalysisScreenState extends State<SpendingAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _anchorDate;
  List<Transaction> _allTransactions = [];
  bool _loading = true;
  period.PeriodType _periodType = period.PeriodType.month;

  final NumberFormat _currencyFormat = NumberFormats.currency;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _anchorDate = widget.initialDate ?? DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await TransactionService().loadTransactions();
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );
    if (!mounted) return;
    setState(() {
      _allTransactions = transactions;
      _loading = false;
    });
  }

  void _changePeriod(int delta) {
    setState(() {
      switch (_periodType) {
        case period.PeriodType.week:
          _anchorDate = _anchorDate.add(Duration(days: 7 * delta));
          break;
        case period.PeriodType.month:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + delta);
          break;
        case period.PeriodType.quarter:
        case period.PeriodType.halfYear:
        case period.PeriodType.year:
        case period.PeriodType.decade:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + delta);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('지출 분석 & 절약 팁'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.bar_chart), text: 'TOP 지출'),
                Tab(icon: Icon(Icons.repeat), text: '반복 패턴'),
                Tab(icon: Icon(Icons.lightbulb), text: '절약 팁'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: '새로고침',
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildPeriodSelector(theme),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTopSpendingTab(theme),
                          _buildRecurringPatternTab(theme),
                          _buildSavingTipsTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    final range = period.PeriodUtils.getPeriodRange(
      _periodType,
      baseDate: _anchorDate,
    );
    String label = DateFormat('yyyy년 M월').format(_anchorDate);
    if (_periodType == period.PeriodType.week) {
      final df = DateFormat('M/d');
      label = '${df.format(range.start)} ~ ${df.format(range.end)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changePeriod(-1),
          ),
          GestureDetector(
            onTap: () => _showPeriodTypeSelector(theme),
            child: Row(
              children: [
                Text(label, style: theme.textTheme.titleLarge),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changePeriod(1),
          ),
        ],
      ),
    );
  }

  void _showPeriodTypeSelector(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('주간'),
            selected: _periodType == period.PeriodType.week,
            onTap: () {
              setState(() => _periodType = period.PeriodType.week);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('월간'),
            selected: _periodType == period.PeriodType.month,
            onTap: () {
              setState(() => _periodType = period.PeriodType.month);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // === TAB 1: TOP 지출 ===
  Widget _buildTopSpendingTab(ThemeData theme) {
    final range = period.PeriodUtils.getPeriodRange(
      _periodType,
      baseDate: _anchorDate,
    );

    // TOP 5 품목
    final topItems = SpendingAnalysisUtils.getTopSpendingItems(
      transactions: _allTransactions,
      startDate: range.start,
      endDate: range.end,
    );

    // TOP 5 카테고리
    final topCategories = SpendingAnalysisUtils.getTopSpendingCategories(
      transactions: _allTransactions,
      currentMonth: _anchorDate,
    );

    // TOP 5 상점
    final topStores = SpendingAnalysisUtils.getTopSpendingStores(
      transactions: _allTransactions,
      startDate: range.start,
      endDate: range.end,
    );

    if (topItems.isEmpty && topCategories.isEmpty) {
      return _buildEmptyState(theme, '해당 기간 지출 내역이 없습니다');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP 5 품목 차트
          _buildSectionTitle(theme, 'TOP 5 품목', Icons.shopping_bag),
          const SizedBox(height: 12),
          if (topItems.isNotEmpty) ...[
            _buildBarChart(topItems, theme),
            const SizedBox(height: 16),
            _buildTopItemsList(topItems, theme),
          ] else
            _buildEmptyCard(theme, '품목 데이터가 없습니다'),

          const SizedBox(height: 24),

          // TOP 5 카테고리
          _buildSectionTitle(theme, 'TOP 5 카테고리', Icons.category),
          const SizedBox(height: 12),
          if (topCategories.isNotEmpty)
            _buildCategorySummaryList(topCategories, theme)
          else
            _buildEmptyCard(theme, '카테고리 데이터가 없습니다'),

          const SizedBox(height: 24),

          // TOP 5 상점
          _buildSectionTitle(theme, 'TOP 5 상점', Icons.store),
          const SizedBox(height: 12),
          if (topStores.isNotEmpty)
            _buildStoreList(topStores, theme)
          else
            _buildEmptyCard(theme, '상점 데이터가 없습니다'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<ItemSpendingAnalysis> items, ThemeData theme) {
    if (items.isEmpty) return const SizedBox.shrink();

    final maxValue = items.first.totalAmount;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = items[group.x];
                return BarTooltipItem(
                  '${item.name}\n${_currencyFormat.format(item.totalAmount)}',
                  TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final name = items[idx].name;
                  final displayName =
                      name.length > 6 ? '${name.substring(0, 6)}...' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayName,
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact(locale: 'ko').format(value),
                    style: theme.textTheme.labelSmall,
                  );
                },
                reservedSize: 50,
              ),
            ),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(),
          barGroups: List.generate(items.length, (index) {
            final item = items[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.totalAmount,
                  color: ChartColors.getColorForIndex(index, theme),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopItemsList(
    List<ItemSpendingAnalysis> items,
    ThemeData theme,
  ) {
    return Card(
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: ChartColors.getColorForIndex(index, theme),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(item.name),
            subtitle: Text('${item.count}회 구매 · 평균 ${_currencyFormat.format(item.avgAmount)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(item.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySummaryList(
    List<CategorySpendingSummary> categories,
    ThemeData theme,
  ) {
    return Card(
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;

          // 전월 대비 변동 표시
          final changeIcon = cat.monthOverMonthChange > 0
              ? Icons.trending_up
              : (cat.monthOverMonthChange < 0
                  ? Icons.trending_down
                  : Icons.trending_flat);
          final changeColor = cat.monthOverMonthChange > 10
              ? theme.colorScheme.error
              : (cat.monthOverMonthChange < -10
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: ChartColors.getColorForIndex(index, theme),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(cat.category),
            subtitle: Row(
              children: [
                Text('${cat.transactionCount}건'),
                const SizedBox(width: 8),
                Icon(changeIcon, size: 16, color: changeColor),
                Text(
                  '${cat.monthOverMonthChange >= 0 ? '+' : ''}${cat.monthOverMonthChange.toStringAsFixed(0)}%',
                  style: TextStyle(color: changeColor, fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(cat.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cat.percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoreList(List<ItemSpendingAnalysis> stores, ThemeData theme) {
    return Card(
      child: Column(
        children: stores.asMap().entries.map((entry) {
          final index = entry.key;
          final store = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: ChartColors.getColorForIndex(index, theme),
              child: const Icon(Icons.store, color: Colors.white, size: 18),
            ),
            title: Text(store.name),
            subtitle: Text('${store.count}회 방문'),
            trailing: Text(
              _currencyFormat.format(store.totalAmount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // === TAB 2: 반복 패턴 ===
  Widget _buildRecurringPatternTab(ThemeData theme) {
    final patterns = SpendingAnalysisUtils.detectRecurringPatterns(
      transactions: _allTransactions,
    );

    final duplicateRisks = SpendingAnalysisUtils.detectDuplicatePurchaseRisk(
      transactions: _allTransactions,
    );

    if (patterns.isEmpty) {
      return _buildEmptyState(theme, '반복 구매 패턴이 감지되지 않았습니다.\n거래 데이터가 쌓이면 분석됩니다.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 중복 구매 위험 경고
          if (duplicateRisks.isNotEmpty) ...[
            _buildSectionTitle(theme, '⚠️ 중복 구매 주의', Icons.warning_amber),
            const SizedBox(height: 12),
            _buildDuplicateRiskCards(duplicateRisks, theme),
            const SizedBox(height: 24),
          ],

          // 반복 구매 패턴
          _buildSectionTitle(theme, '반복 구매 패턴', Icons.repeat),
          const SizedBox(height: 12),
          _buildPatternList(patterns, theme),

          const SizedBox(height: 24),

          // 다음 구매 예측
          _buildSectionTitle(theme, '다음 구매 예측', Icons.calendar_today),
          const SizedBox(height: 12),
          _buildPredictionList(patterns, theme),
        ],
      ),
    );
  }

  Widget _buildDuplicateRiskCards(
    List<RecurringSpendingPattern> risks,
    ThemeData theme,
  ) {
    return Column(
      children: risks.take(3).map((risk) {
        final daysSinceLast = DateTime.now()
            .difference(risk.purchaseDates.last)
            .inDays;

        return Card(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          child: ListTile(
            leading: Icon(
              Icons.warning,
              color: theme.colorScheme.error,
            ),
            title: Text(risk.name),
            subtitle: Text(
              '$daysSinceLast일 전 구매함 · 평균 주기 ${risk.avgInterval.round()}일',
            ),
            trailing: Text(
              '${(risk.avgInterval - daysSinceLast).round()}일 후\n구매 적절',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPatternList(
    List<RecurringSpendingPattern> patterns,
    ThemeData theme,
  ) {
    return Card(
      child: Column(
        children: patterns.take(10).map((pattern) {
          final confidence = pattern.predictionConfidence;
          final confidenceColor = confidence > 0.7
              ? Colors.green
              : (confidence > 0.5 ? Colors.orange : Colors.grey);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${pattern.frequency}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(pattern.name),
            subtitle: Row(
              children: [
                Text('월 ${pattern.frequency}회'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '신뢰도 ${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: confidenceColor,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(pattern.avgAmount),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '평균 ${pattern.avgInterval.round()}일 간격',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPredictionList(
    List<RecurringSpendingPattern> patterns,
    ThemeData theme,
  ) {
    final upcoming = patterns
        .where((p) => p.predictedNextPurchase != null)
        .where((p) => p.predictedNextPurchase!.isAfter(DateTime.now()))
        .where((p) =>
            p.predictedNextPurchase!.difference(DateTime.now()).inDays <= 14)
        .toList()
      ..sort((a, b) => a.predictedNextPurchase!.compareTo(
            b.predictedNextPurchase!,
          ));

    if (upcoming.isEmpty) {
      return _buildEmptyCard(theme, '2주 내 예정된 구매가 없습니다');
    }

    return Card(
      child: Column(
        children: upcoming.take(5).map((pattern) {
          final daysUntil = pattern.predictedNextPurchase!
              .difference(DateTime.now())
              .inDays;
          final dateStr = DateFormat('M/d(E)', 'ko')
              .format(pattern.predictedNextPurchase!);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: daysUntil <= 3
                  ? theme.colorScheme.error
                  : theme.colorScheme.primaryContainer,
              child: Text(
                'D-$daysUntil',
                style: TextStyle(
                  fontSize: 11,
                  color: daysUntil <= 3
                      ? Colors.white
                      : theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(pattern.name),
            subtitle: Text('예상 구매일: $dateStr'),
            trailing: Text(
              '~${_currencyFormat.format(pattern.avgAmount)}',
              style: theme.textTheme.titleSmall,
            ),
          );
        }).toList(),
      ),
    );
  }

  // === TAB 3: 절약 팁 ===
  Widget _buildSavingTipsTab(ThemeData theme) {
    // 분석 데이터 준비
    final topCategories = SpendingAnalysisUtils.getTopSpendingCategories(
      transactions: _allTransactions,
      currentMonth: _anchorDate,
    );
    final patterns = SpendingAnalysisUtils.detectRecurringPatterns(
      transactions: _allTransactions,
    );

    // 맞춤 팁 생성
    final tips = SavingTipsUtils.generateTipsFromAnalysis(
      topCategories: topCategories,
      recurringPatterns: patterns,
    );

    // 중복 구매 경고 팁
    final duplicateRisks = SpendingAnalysisUtils.detectDuplicatePurchaseRisk(
      transactions: _allTransactions,
    );
    final duplicateWarnings = SavingTipsUtils.generateDuplicatePurchaseWarnings(
      duplicateRisks,
    );

    final allTips = [...duplicateWarnings, ...tips];

    // 총 예상 절약 금액
    final totalSavings = SavingTipsUtils.calculateTotalPotentialSavings(allTips);

    if (allTips.isEmpty) {
      return _buildEmptyState(theme, '아직 분석할 데이터가 부족합니다.\n거래 내역이 쌓이면 맞춤 팁을 제공합니다.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 예상 절약 금액 요약
          if (totalSavings > 0)
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '예상 월 절약 금액',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(totalSavings),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 팁 목록
          _buildSectionTitle(theme, '맞춤 절약 팁', Icons.lightbulb),
          const SizedBox(height: 12),
          ...allTips.map((tip) => _buildTipCard(tip, theme)),
        ],
      ),
    );
  }

  Widget _buildTipCard(SavingTip tip, ThemeData theme) {
    final iconName = SavingTipsUtils.getTipTypeIcon(tip.type);
    final typeLabel = SavingTipsUtils.getTipTypeLabel(tip.type);

    IconData getIconData() {
      switch (iconName) {
        case 'emoji_events':
          return Icons.emoji_events;
        case 'compare_arrows':
          return Icons.compare_arrows;
        case 'schedule':
          return Icons.schedule;
        case 'swap_horiz':
          return Icons.swap_horiz;
        case 'psychology':
          return Icons.psychology;
        case 'inventory_2':
          return Icons.inventory_2;
        case 'autorenew':
          return Icons.autorenew;
        case 'card_giftcard':
          return Icons.card_giftcard;
        default:
          return Icons.lightbulb;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: tip.priority == 1
              ? theme.colorScheme.error
              : theme.colorScheme.primaryContainer,
          child: Icon(
            getIconData(),
            color: tip.priority == 1
                ? Colors.white
                : theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          tip.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            if (tip.estimatedMonthlySaving != null &&
                tip.estimatedMonthlySaving! > 0) ...[
              const SizedBox(width: 8),
              Text(
                '월 ~${_currencyFormat.format(tip.estimatedMonthlySaving)} 절약',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.description,
                  style: theme.textTheme.bodyMedium,
                ),
                if (tip.actionItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '💡 실천 방법',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...tip.actionItems.map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(action)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Common Widgets ===
  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ThemeData theme, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
