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

part 'one_hundred_million_project_screen_settings.dart';
part 'one_hundred_million_project_screen_body.dart';

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

    if (mounted) setState(() => _isLoading = false);
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
      if (cash > 0 && rCash > 0) cash *= 1 + rCash;
      if (invest > 0 && rInvest > 0) invest *= 1 + rInvest;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('1억 프로젝트')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
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
      body: _buildProjectBody(),
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
