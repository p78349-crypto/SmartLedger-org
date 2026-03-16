import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/pref_keys.dart';
import 'micro_savings_nudge_dialogs.dart';

class MicroSavingsNudgeScreen extends StatefulWidget {
  const MicroSavingsNudgeScreen({
    super.key,
    required this.accountName,
    this.initialTypeIndex,
  });

  final String accountName;
  final int? initialTypeIndex;

  @override
  State<MicroSavingsNudgeScreen> createState() =>
      _MicroSavingsNudgeScreenState();
}

typedef _SumCount = ({double total, int count});

class _MicroSavingsNudgeScreenState extends State<MicroSavingsNudgeScreen> {
  bool _loading = true;

  _SumCount _skippedThisMonth = (total: 0, count: 0);
  _SumCount _skippedLookback = (total: 0, count: 0);

  _SumCount _pointsThisMonth = (total: 0, count: 0);
  _SumCount _pointsLookback = (total: 0, count: 0);

  _SumCount _roundUpThisMonth = (total: 0, count: 0);
  _SumCount _roundUpLookback = (total: 0, count: 0);

  // Quick Entry State
  final List<TextEditingController> _amountControllers =
      List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _memoControllers =
      List.generate(5, (_) => TextEditingController());
  final TextEditingController _targetController = TextEditingController(text: '100,000,000');
  double _selectedTarget = 100000000;
  bool _showCalculation = false;
  int _selectedTypeIndex = 0; // 0: 참은 소비, 1: 포인트 모으기
  double _projectSafeRatePct = 3.0;

  @override
  void initState() {
    super.initState();
    final initIndex = widget.initialTypeIndex;
    if (initIndex != null) {
      _selectedTypeIndex = initIndex.clamp(0, 1);
    }
    _load();
  }

  @override
  void dispose() {
    for (var c in _amountControllers) {
      c.dispose();
    }
    for (var c in _memoControllers) {
      c.dispose();
    }
    _targetController.dispose();
    super.dispose();
  }

  DateTime _startOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime _startOfLookback() {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 5);
  }

  _SumCount _sumWhere(
    Iterable<Transaction> txs,
    bool Function(Transaction) pred,
  ) {
    var total = 0.0;
    var count = 0;
    for (final t in txs) {
      if (!pred(t)) continue;
      if (t.amount <= 0) continue;
      total += t.amount;
      count += 1;
    }
    return (total: total, count: count);
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    _projectSafeRatePct = prefs.getDouble(PrefKeys.project100mSafeRatePctV1) ?? 3.0;

    await TransactionService().loadTransactions();
    final all = TransactionService().getTransactions(widget.accountName);

    final thisMonthStart = _startOfThisMonth();
    final lookbackStart = _startOfLookback();

    final thisMonth = <Transaction>[];
    final lookback = <Transaction>[];

    for (final t in all) {
      if (t.date.isBefore(lookbackStart)) continue;
      lookback.add(t);
      if (!t.date.isBefore(thisMonthStart)) {
        thisMonth.add(t);
      }
    }

    if (!mounted) return;
    setState(() {
      _skippedThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isSkippedSpendRecord,
      );
      _skippedLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isSkippedSpendRecord,
      );
      _pointsThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isSavedPointsRecord,
      );
      _pointsLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isSavedPointsRecord,
      );
      _roundUpThisMonth = _sumWhere(
        thisMonth,
        BenefitAggregationUtils.isRoundUpRecord,
      );
      _roundUpLookback = _sumWhere(
        lookback,
        BenefitAggregationUtils.isRoundUpRecord,
      );
      _loading = false;
    });
  }

  Widget _quickEntryCard(ThemeData theme) {
    double totalInput = 0;
    for (var c in _amountControllers) {
      final val = CurrencyFormatter.parse(c.text.trim());
      if (val != null) totalInput += val;
    }
    
    // 동적 목표 금액 파싱
    final currentTarget = CurrencyFormatter.parse(_targetController.text.trim())?.toDouble() ?? _selectedTarget;

    final r = (_projectSafeRatePct / 100.0) / 12.0;
    const n10 = 120.0;
    double fv10 = 0;
    double monthsToTarget = 0;
    double requiredMonthlyFor10y = 0;

    if (totalInput > 0) {
      if (r > 0) {
        fv10 = totalInput * (math.pow(1 + r, n10) - 1) / r * (1 + r);
        final val = (currentTarget * r) / (totalInput * (1 + r)) + 1;
        if (val > 0) {
          monthsToTarget = math.log(val) / math.log(1 + r);
        }
        requiredMonthlyFor10y = currentTarget * r / ((math.pow(1 + r, n10) - 1) * (1 + r));
      } else {
        fv10 = totalInput * n10;
        monthsToTarget = currentTarget / totalInput;
        requiredMonthlyFor10y = currentTarget / n10;
      }
    }

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_graph, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('자산 가속 입력 & 시뮬레이션', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            // 분류 및 목표 선택
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('참은 소비'), icon: Icon(Icons.money_off, size: 16)),
                      ButtonSegment(value: 1, label: Text('포인트'), icon: Icon(Icons.card_giftcard, size: 16)),
                    ],
                    selected: {_selectedTypeIndex},
                    onSelectionChanged: (set) => setState(() => _selectedTypeIndex = set.first),
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('목표 금액 설정:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _targetPresetChip('1,000만', 10000000),
                      const SizedBox(width: 4),
                      _targetPresetChip('3,000만', 30000000),
                      const SizedBox(width: 4),
                      _targetPresetChip('5,000만', 50000000),
                      const SizedBox(width: 4),
                      _targetPresetChip('1억', 100000000),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetController,
                  decoration: const InputDecoration(
                    labelText: '목표 금액 직접 입력',
                    isDense: true,
                    suffixText: '원',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _amountControllers[index],
                        decoration: InputDecoration(
                          labelText: '금액 ${index + 1}',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 13),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (_showCalculation) setState(() => _showCalculation = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _memoControllers[index],
                        decoration: InputDecoration(
                          labelText: '메모 ${index + 1}',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (!_showCalculation)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: totalInput > 0 ? () => setState(() => _showCalculation = true) : null,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('미래가치 계산해보기'),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('💰 월 합계: ${CurrencyFormatter.format(totalInput)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(height: 16),
                    Text('📅 10년 후 예상: ${CurrencyFormatter.format(fv10)}', style: const TextStyle(fontSize: 13)),
                    Text(
                      '🚀 목표(${CurrencyFormatter.format(currentTarget)}) 달성: ${monthsToTarget > 0 ? (monthsToTarget / 12).toStringAsFixed(1) : "??"}년',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '💡 10년내 목표 달성을 위해선 매월 ${CurrencyFormatter.format(requiredMonthlyFor10y)} 저축이 필요해요.',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: totalInput > 0 ? _onBatchSave : null,
              icon: const Icon(Icons.save),
              label: Text('${_selectedTypeIndex == 0 ? "참은 소비" : "포인트"} ${CurrencyFormatter.format(totalInput)} 기록하기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onBatchSave() async {
    final title = _selectedTypeIndex == 0 ? '참은 소비' : '포인트 모으기';
    final memoTag = _selectedTypeIndex == 0 
        ? BenefitAggregationUtils.skippedSpendMemoTag 
        : BenefitAggregationUtils.savedPointsMemoTag;

    int savedCount = 0;
    for (int i = 0; i < 5; i++) {
      final parsed = CurrencyFormatter.parse(_amountControllers[i].text.trim());
      if (parsed == null || parsed <= 0) continue;

      final memoRaw = _memoControllers[i].text.trim();
      final memo = memoRaw.isEmpty ? memoTag : '$memoTag $memoRaw';

      final tx = Transaction(
        id: 'micro_${DateTime.now().millisecondsSinceEpoch}_$i',
        type: TransactionType.savings,
        description: title,
        amount: parsed.toDouble(),
        date: DateTime.now(),
        memo: memo,
        savingsAllocation: SavingsAllocation.assetIncrease,
      );

      await TransactionService().addTransaction(widget.accountName, tx);
      savedCount++;
    }

    if (savedCount > 0) {
      for (var c in _amountControllers) {
        c.clear();
      }
      for (var c in _memoControllers) {
        c.clear();
      }
      setState(() => _showCalculation = false);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$savedCount건의 $title를 기록했습니다.')),
        );
      }
    }
  }

  Widget _targetPresetChip(String label, double value) {
    // 쉼표 포함 형식과 숫자를 비교하기 위해 파싱 필요
    final currentTarget = CurrencyFormatter.parse(_targetController.text.trim())?.toDouble() ?? 0;
    final isSelected = currentTarget == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          _selectedTarget = value;
          _targetController.text = CurrencyFormatter.format(value);
        });
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _metric(
    ThemeData theme, {
    required String title,
    required _SumCount month,
    required _SumCount lookback,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(month.total),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '이번달 ${month.count}건 · 최근 6개월 '
              '${CurrencyFormatter.format(lookback.total)} '
              '(${lookback.count}건)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 가속(푼돈 모으기)'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _quickEntryCard(theme),
                const SizedBox(height: 20),
                Text(
                  '나의 저축 현황',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _metric(
                  theme,
                  title: '참은 소비',
                  month: _skippedThisMonth,
                  lookback: _skippedLookback,
                ),
                const SizedBox(height: 12),
                _metric(
                  theme,
                  title: '포인트 모으기',
                  month: _pointsThisMonth,
                  lookback: _pointsLookback,
                ),
                const SizedBox(height: 12),
                _metric(
                  theme,
                  title: '잔돈 모으기(반올림)',
                  month: _roundUpThisMonth,
                  lookback: _roundUpLookback,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  '기타 기능',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final changed = await showRoundUpDialog(
                        context,
                        accountName: widget.accountName,
                      );
                      if (changed) await _load();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('잔돈 모으기(반올림) 수동 기록'),
                  ),
                ),
              ],
            ),
    );
  }
}
