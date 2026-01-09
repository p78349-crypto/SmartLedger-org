import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../services/asset_service.dart';
import '../services/transaction_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/pref_keys.dart';
import '../widgets/smart_input_field.dart';

class OneHundredMillionProjectScreen extends StatefulWidget {
  final String accountName;
  const OneHundredMillionProjectScreen({super.key, required this.accountName});

  @override
  State<OneHundredMillionProjectScreen> createState() =>
      _OneHundredMillionProjectScreenState();
}

class _OneHundredMillionProjectScreenState
    extends State<OneHundredMillionProjectScreen> {
  bool _isLoading = true;
  List<Asset> _assets = [];
  List<Transaction> _txs = [];

  // 1억 프로젝트 설정
  int _projectYears = 10;
  double _projectTargetAmount = 100000000;
  double _projectSafeRatePct = 3.0;
  double _projectInvestRatePct = 6.0;
  bool _projectIncludeBenefits = true;
  double _projectCashToInvestThresholdAmount = 100000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _assets = AssetService().getAssets(widget.accountName);
    _txs = TransactionService().getTransactions(widget.accountName);

    _projectYears = prefs.getInt(PrefKeys.project100mYearsV1) ?? 10;
    _projectTargetAmount =
        prefs.getDouble(PrefKeys.project100mTargetAmountV1) ?? 100000000;
    _projectSafeRatePct =
        prefs.getDouble(PrefKeys.project100mSafeRatePctV1) ?? 3.0;
    _projectInvestRatePct =
        prefs.getDouble(PrefKeys.project100mInvestRatePctV1) ?? 6.0;
    _projectIncludeBenefits =
        prefs.getBool(PrefKeys.project100mIncludeBenefitsV1) ?? true;
    _projectCashToInvestThresholdAmount =
        prefs.getDouble(PrefKeys.project100mCashToInvestThresholdAmountV1) ??
        100000;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProject100mPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.project100mYearsV1, _projectYears);
    await prefs.setDouble(
      PrefKeys.project100mTargetAmountV1,
      _projectTargetAmount,
    );
    await prefs.setDouble(
      PrefKeys.project100mSafeRatePctV1,
      _projectSafeRatePct,
    );
    await prefs.setDouble(
      PrefKeys.project100mInvestRatePctV1,
      _projectInvestRatePct,
    );
    await prefs.setBool(
      PrefKeys.project100mIncludeBenefitsV1,
      _projectIncludeBenefits,
    );
    await prefs.setDouble(
      PrefKeys.project100mCashToInvestThresholdAmountV1,
      _projectCashToInvestThresholdAmount,
    );
  }

  double _fvLumpSum({
    required double presentValue,
    required double annualRatePct,
    required int years,
  }) {
    if (presentValue <= 0) return 0;
    final r = (annualRatePct / 100.0).clamp(0.0, 100.0);
    if (r == 0) return presentValue;
    return presentValue * math.pow(1 + r, years).toDouble();
  }

  double _fvMonthlyBenefitWithCashToInvestSwitch({
    required double monthly,
    required double cashAnnualRatePct,
    required double investAnnualRatePct,
    required int years,
    required double cashToInvestThresholdAmount,
  }) {
    if (monthly <= 0) return 0;
    final months = years * 12;
    if (months <= 0) return 0;

    final rCash = (cashAnnualRatePct / 100.0).clamp(0.0, 100.0) / 12.0;
    final rInvest = (investAnnualRatePct / 100.0).clamp(0.0, 100.0) / 12.0;
    final threshold = cashToInvestThresholdAmount.clamp(0.0, double.infinity);

    var cash = 0.0;
    var invest = 0.0;
    var switched = false;

    for (var i = 0; i < months; i++) {
      if (cash > 0 && rCash > 0) {
        cash *= 1 + rCash;
      }
      if (invest > 0 && rInvest > 0) {
        invest *= 1 + rInvest;
      }

      if (!switched) {
        cash += monthly;
        if (threshold == 0 || cash >= threshold) {
          invest += cash;
          cash = 0;
          switched = true;
        }
      } else {
        invest += monthly;
      }
    }

    return cash + invest;
  }

  double _requiredMonthlyToReach({
    required double targetFutureValue,
    required double currentFutureValue,
    required double annualRatePct,
    required int years,
  }) {
    final needed = (targetFutureValue - currentFutureValue)
        .clamp(0.0, double.infinity)
        .toDouble();
    final n = years * 12;
    if (n <= 0) return 0;
    final rAnnual = (annualRatePct / 100.0).clamp(0.0, 100.0);
    if (rAnnual == 0) return needed / n;
    final r = rAnnual / 12.0;
    final factor = math.pow(1 + r, n).toDouble();
    final denom = factor - 1;
    if (denom == 0) return 0;
    return needed * r / denom;
  }

  Future<void> _openSettings() async {
    final yearsController = TextEditingController(text: '$_projectYears');
    final targetController = TextEditingController(
      text: CurrencyFormatter.format(_projectTargetAmount, showUnit: false),
    );
    final safeRateController = TextEditingController(
      text: _projectSafeRatePct.toStringAsFixed(1),
    );
    final investRateController = TextEditingController(
      text: _projectInvestRatePct.toStringAsFixed(1),
    );
    final cashToInvestController = TextEditingController(
      text: CurrencyFormatter.format(
        _projectCashToInvestThresholdAmount,
        showUnit: false,
      ),
    );

    var includeBenefits = _projectIncludeBenefits;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('1억 프로젝트 설정'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SmartInputField(
                      label: '기간(년)',
                      hint: '예: 10',
                      controller: yearsController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      label: '목표 금액',
                      hint: '예: 100000000',
                      controller: targetController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      label: '안전자산 연이율(%)',
                      hint: '예: 3.0',
                      controller: safeRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      label: '투자자산 연이율(%)',
                      hint: '예: 6.0',
                      controller: investRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('혜택/절약을 매달 적립으로 포함'),
                      value: includeBenefits,
                      onChanged: (v) =>
                          setDialogState(() => includeBenefits = v),
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      label: '비상금→투자 전환 기준(원)',
                      hint: '예: 100000',
                      controller: cashToInvestController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      yearsController.dispose();
      targetController.dispose();
      safeRateController.dispose();
      investRateController.dispose();
      cashToInvestController.dispose();
      return;
    }

    final years = int.tryParse(yearsController.text.trim());
    final target = CurrencyFormatter.parse(targetController.text.trim());
    final safeRate = double.tryParse(safeRateController.text.trim());
    final investRate = double.tryParse(investRateController.text.trim());
    final cashToInvestThreshold = CurrencyFormatter.parse(
      cashToInvestController.text.trim(),
    );

    yearsController.dispose();
    targetController.dispose();
    safeRateController.dispose();
    investRateController.dispose();
    cashToInvestController.dispose();

    setState(() {
      _projectYears = (years ?? _projectYears).clamp(1, 50);
      if (target != null && target >= 0) {
        _projectTargetAmount = target;
      }
      _projectSafeRatePct = (safeRate ?? _projectSafeRatePct).clamp(0.0, 100.0);
      _projectInvestRatePct = (investRate ?? _projectInvestRatePct).clamp(
        0.0,
        100.0,
      );
      _projectIncludeBenefits = includeBenefits;
      if (cashToInvestThreshold != null && cashToInvestThreshold >= 0) {
        _projectCashToInvestThresholdAmount = cashToInvestThreshold;
      }
    });

    await _saveProject100mPrefs();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('1억 프로젝트 설정이 저장되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('1억 프로젝트')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    final safeNow = _assets
        .where(
          (a) =>
              a.category == AssetCategory.deposit ||
              a.category == AssetCategory.cash ||
              a.category == AssetCategory.bond,
        )
        .fold<double>(0, (s, a) => s + a.amount);

    final investNow = _assets
        .where(
          (a) =>
              a.category == AssetCategory.stock ||
              a.category == AssetCategory.crypto ||
              a.category == AssetCategory.realEstate ||
              a.category == AssetCategory.other,
        )
        .fold<double>(0, (s, a) => s + a.amount);

    final currentTotal = safeNow + investNow;

    double projectedAssetsFv = 0;
    for (final a in _assets) {
      final fallbackRate =
          (a.category == AssetCategory.deposit ||
              a.category == AssetCategory.cash ||
              a.category == AssetCategory.bond)
          ? _projectSafeRatePct
          : _projectInvestRatePct;
      final rate = a.expectedAnnualRatePct ?? fallbackRate;
      projectedAssetsFv += _fvLumpSum(
        presentValue: a.amount,
        annualRatePct: rate,
        years: _projectYears,
      );
    }

    final monthlyBenefit = _projectIncludeBenefits
        ? BenefitAggregationUtils.averageMonthlyBenefit(_txs)
        : 0.0;
    final benefitFv = _projectIncludeBenefits
        ? _fvMonthlyBenefitWithCashToInvestSwitch(
            monthly: monthlyBenefit,
            cashAnnualRatePct: _projectSafeRatePct,
            investAnnualRatePct: _projectInvestRatePct,
            years: _projectYears,
            cashToInvestThresholdAmount: _projectCashToInvestThresholdAmount,
          )
        : 0.0;

    final projectedTotal = projectedAssetsFv + benefitFv;
    final gapAt10y = (_projectTargetAmount - projectedTotal).clamp(
      double.negativeInfinity,
      double.infinity,
    );

    final extraMonthlyNeeded = _requiredMonthlyToReach(
      targetFutureValue: _projectTargetAmount,
      currentFutureValue: projectedTotal,
      annualRatePct: _projectSafeRatePct,
      years: _projectYears,
    );

    final currentLabel = CurrencyFormatter.format(currentTotal);
    final projectedLabel = CurrencyFormatter.format(projectedTotal);
    final targetLabel = CurrencyFormatter.format(_projectTargetAmount);
    final gapLabel = CurrencyFormatter.format(gapAt10y.abs());
    final extraMonthlyLabel = CurrencyFormatter.format(extraMonthlyNeeded);
    final monthlyBenefitLabel = CurrencyFormatter.format(monthlyBenefit);

    final achieved = gapAt10y <= 0;
    final gapText = achieved ? '목표 초과: $gapLabel' : '부족: $gapLabel';
    final gapColor = achieved
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('1억 프로젝트'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_projectYears년 후 미래 전망',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '목표: $targetLabel',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(theme, '현재 자산', currentLabel),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      theme,
                      '예상 $_projectYears년 후',
                      projectedLabel,
                      isBold: true,
                      valueColor: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      theme,
                      achieved ? '목표 달성 여부' : '목표까지',
                      gapText,
                      isBold: true,
                      valueColor: gapColor,
                    ),
                    if (!achieved) ...[
                      const Divider(height: 32),
                      Text(
                        '💡 제안',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '매달 $extraMonthlyLabel씩 추가로 저축하거나 투자하면 '
                        '$_projectYears년 후 목표 금액에 도달할 수 있습니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '상세 가정',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAssumptionCard(
              theme,
              '안전자산 수익률',
              '${_projectSafeRatePct.toStringAsFixed(1)}% (연)',
              Icons.account_balance,
            ),
            const SizedBox(height: 8),
            _buildAssumptionCard(
              theme,
              '투자자산 수익률',
              '${_projectInvestRatePct.toStringAsFixed(1)}% (연)',
              Icons.trending_up,
            ),
            if (_projectIncludeBenefits) ...[
              const SizedBox(height: 8),
              _buildAssumptionCard(
                theme,
                '월평균 혜택/절약',
                monthlyBenefitLabel,
                Icons.redeem,
                subtitle: '최근 90일 기준 데이터를 기반으로 자동 계산됩니다.',
              ),
            ],
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📌 팁',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '작은 할인이나 포인트 혜택도 비상금으로 모아두고, '
                    '일정 금액이 모일 때마다 투자 자산으로 전환해 보세요. '
                    '복리의 마법이 당신의 자산을 더 빠르게 성장시킬 것입니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAssumptionCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon, {
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
