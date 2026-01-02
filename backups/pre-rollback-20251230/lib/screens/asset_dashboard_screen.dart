import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/asset_move.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/screens/asset_detail_screen.dart';
import 'package:smart_ledger/services/asset_move_service.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/asset_dashboard_utils.dart';
import 'package:smart_ledger/utils/benefit_aggregation_utils.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/widgets/one_ui_input_field.dart';

/// 자산 대시보드 - 총 자산, 총 손익, 자산별 카드 뷰, 타임라인
class AssetDashboardScreen extends StatefulWidget {
  final String accountName;

  const AssetDashboardScreen({super.key, required this.accountName});

  @override
  State<AssetDashboardScreen> createState() => _AssetDashboardScreenState();
}

class _AssetDashboardScreenState extends State<AssetDashboardScreen> {
  List<Asset> _assets = [];
  List<Transaction> _txs = const <Transaction>[];
  bool _isLoading = true;

  int _projectYears = 10;
  double _projectTargetAmount = 100000000;
  double _projectSafeRatePct = 3;
  double _projectInvestRatePct = 6;
  bool _projectIncludeBenefits = true;
  double _projectCashToInvestThresholdAmount = 100000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();
    await TransactionService().loadTransactions();
    await _loadProject100mPrefs();
    if (!mounted) return;
    setState(() {
      _assets = AssetService().getAssets(widget.accountName);
      _txs = TransactionService().getTransactions(widget.accountName);
      _isLoading = false;
    });
  }

  Future<void> _loadProject100mPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _projectYears = (prefs.getInt(PrefKeys.project100mYearsV1) ?? 10)
        .clamp(1, 50);
    _projectTargetAmount =
        (prefs.getDouble(PrefKeys.project100mTargetAmountV1) ?? 100000000)
            .clamp(0.0, double.infinity);
    _projectSafeRatePct =
        (prefs.getDouble(PrefKeys.project100mSafeRatePctV1) ?? 3)
            .clamp(0.0, 100.0);
    _projectInvestRatePct =
        (prefs.getDouble(PrefKeys.project100mInvestRatePctV1) ?? 6)
            .clamp(0.0, 100.0);
    _projectIncludeBenefits =
        prefs.getBool(PrefKeys.project100mIncludeBenefitsV1) ?? true;

    _projectCashToInvestThresholdAmount =
      (prefs.getDouble(PrefKeys.project100mCashToInvestThresholdAmountV1) ??
          100000)
        .clamp(0.0, double.infinity);
  }

  Future<void> _saveProject100mPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.project100mYearsV1, _projectYears);
    await prefs.setDouble(
      PrefKeys.project100mTargetAmountV1,
      _projectTargetAmount,
    );
    await prefs.setDouble(PrefKeys.project100mSafeRatePctV1, _projectSafeRatePct);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 대시보드 요약 카드
            _buildDashboardSummary(theme),
            const SizedBox(height: 16),

            // 🎯 1억 프로젝트(10년 전망)
            _buildProject100mCard(theme),
            const SizedBox(height: 16),

            // 📈 자산별 카드 뷰
            _buildAssetCards(theme),
            const SizedBox(height: 16),

            // ⏱️ 최근 타임라인 (전체 자산 이동 기록)
            _buildRecentTimeline(theme),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  /// 📊 대시보드 요약: 총 자산, 총 손익, 손익률
  Widget _buildDashboardSummary(ThemeData theme) {
    final summary = AssetManagementUtils.generateDashboardSummary(_assets);
    return AssetUIBuilder.buildDashboardSummaryCard(
      theme: theme,
      summary: summary,
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

  Future<void> _openProject100mSettings() async {
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
                    OneUiInputField(
                      label: '기간(년)',
                      hint: '예: 10',
                      controller: yearsController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    OneUiInputField(
                      label: '목표 금액',
                      hint: '예: 100000000',
                      controller: targetController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    OneUiInputField(
                      label: '안전자산 연이율(%)',
                      hint: '예: 3.0',
                      controller: safeRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OneUiInputField(
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
                    OneUiInputField(
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
      _projectInvestRatePct =
          (investRate ?? _projectInvestRatePct).clamp(0.0, 100.0);
      _projectIncludeBenefits = includeBenefits;
      if (cashToInvestThreshold != null && cashToInvestThreshold >= 0) {
        _projectCashToInvestThresholdAmount = cashToInvestThreshold;
      }
    });

    await _saveProject100mPrefs();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('1억 프로젝트 설정이 저장되었습니다.')),
    );
  }

  Widget _buildProject100mCard(ThemeData theme) {
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
    final gapAt10y = (_projectTargetAmount - projectedTotal)
        .clamp(double.negativeInfinity, double.infinity);

    final extraMonthlyNeeded = _requiredMonthlyToReach(
      targetFutureValue: _projectTargetAmount,
      currentFutureValue: projectedTotal,
      annualRatePct: _projectSafeRatePct,
      years: _projectYears,
    );

    final currentLabel = CurrencyFormatter.format(currentTotal, showUnit: true);
    final projectedLabel = CurrencyFormatter.format(projectedTotal, showUnit: true);
    final targetLabel = CurrencyFormatter.format(
      _projectTargetAmount,
      showUnit: true,
    );
    final gapLabel = CurrencyFormatter.format(gapAt10y.abs(), showUnit: true);
    final extraMonthlyLabel = CurrencyFormatter.format(
      extraMonthlyNeeded,
      showUnit: true,
    );
    final monthlyBenefitLabel = CurrencyFormatter.format(
      monthlyBenefit,
      showUnit: true,
    );
    final thresholdLabel = CurrencyFormatter.format(
      _projectCashToInvestThresholdAmount,
      showUnit: true,
    );

    final achieved = gapAt10y <= 0;
    final gapText = achieved ? '목표 초과: $gapLabel' : '부족: $gapLabel';
    final gapColor = achieved
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '1억 프로젝트 ($_projectYears년 전망)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '설정',
                    onPressed: _openProject100mSettings,
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '목표: $targetLabel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text('현재 자산: $currentLabel', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(
                '예상 $_projectYears년 후: $projectedLabel',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                gapText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: gapColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!achieved) ...[
                const SizedBox(height: 6),
                Text(
                  '추가로 매달 $extraMonthlyLabel 더 모으면 목표에 가까워집니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '가정: 안전자산 ${_projectSafeRatePct.toStringAsFixed(1)}% · '
                '투자자산 ${_projectInvestRatePct.toStringAsFixed(1)}% 연이율',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_projectIncludeBenefits) ...[
                const SizedBox(height: 4),
                Text(
                  '혜택/절약(최근 90일 기준) 월평균: $monthlyBenefitLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '팁: 작은 할인/포인트는 비상금(현금)에 모아두고, 일정 금액이 되면 투자로 전환하면 성장에 도움이 됩니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '전환 기준: 비상금 $thresholdLabel 도달 시 투자로 전환(가정)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '※ 이 화면은 “가정(연이율/절약)” 기반의 미래 제시입니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📈 자산별 카드 뷰
  Widget _buildAssetCards(ThemeData theme) {
    if (_assets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                '등록된 자산이 없습니다',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자산별 현황',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._assets.map((asset) => _buildAssetCard(asset, theme)),
        ],
      ),
    );
  }

  /// 자산 카드
  Widget _buildAssetCard(Asset asset, ThemeData theme) {
    final cardInfo = AssetManagementUtils.generateAssetCardInfo(asset);
    return AssetUIBuilder.buildAssetCard(
      theme: theme,
      cardInfo: cardInfo,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(
              accountName: widget.accountName,
              asset: asset,
            ),
          ),
        );
        _loadData();
      },
    );
  }

  /// ⏱️ 최근 타임라인
  Widget _buildRecentTimeline(ThemeData theme) {
    final allMoves = AssetMoveService().getMoves(widget.accountName);
    final recentMoves = AssetManagementUtils.getRecentMoves(
      allMoves,
      limit: 10,
    );

    if (recentMoves.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '최근 자산 이동',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentMoves.map((move) => _buildTimelineItem(move, theme)),
        ],
      ),
    );
  }

  /// 타임라인 아이템
  Widget _buildTimelineItem(AssetMove move, ThemeData theme) {
    return AssetUIBuilder.buildTimelineItem(theme: theme, move: move);
  }
}

