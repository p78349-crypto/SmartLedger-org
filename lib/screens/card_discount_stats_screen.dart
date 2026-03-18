import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../navigation/app_routes_args.dart';
import '../navigation/app_routes_paths.dart';
import '../services/transaction_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/benefit_memo_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/pref_keys.dart';

part 'card_discount_stats_screen_logic.dart';
part 'card_discount_stats_screen_ui.dart';

class CardDiscountStatsScreen extends StatefulWidget {
  const CardDiscountStatsScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<CardDiscountStatsScreen> createState() =>
      _CardDiscountStatsScreenState();
}

class _CardDiscountStatsScreenState extends State<CardDiscountStatsScreen> {
  static const _periodYears = [1, 3, 5, 7, 10];
  int _selectedYears = 1;

  static const double _defaultAnnualRatePct = 3.0;
  final TextEditingController _annualRateController = TextEditingController(
    text: _defaultAnnualRatePct.toStringAsFixed(0),
  );
  double _annualRatePct = _defaultAnnualRatePct;

  // Interest calculation mode: allow annual simple interest or compounding.
  static const int _modeSimpleAnnual = 0;
  static const int _modeCompoundYearly = 1;
  static const int _modeCompoundMonthly = 2;
  int _interestMode = _modeSimpleAnnual;

  List<Transaction> _txs = [];

  @override
  void initState() {
    super.initState();
    _txs = TransactionService().getTransactions(widget.accountName);
    _loadPointsSettingsFromPrefs();
  }

  @override
  void dispose() {
    _annualRateController.dispose();
    super.dispose();
  }

  // ── Benefit aggregation by 4 categories ──

  static const _catCard = '카드';
  static const _catMart = '마트';
  static const _catShopping = '쇼핑몰';
  static const _catOther = '기타';

  String _normalizeKey(String rawKey) {
    final k = rawKey.trim().toLowerCase();
    if (k.contains('카드')) return _catCard;
    if (k.contains('마트')) return _catMart;
    if (k.contains('쇼핑') || k.contains('온라인')) return _catShopping;
    return _catOther;
  }

  Map<String, double> _savedByCategory(Transaction t) {
    if (BenefitAggregationUtils.isSavedPointsRecord(t)) {
      final structured = t.benefitByType;
      if (structured.isNotEmpty) return _bucketize(structured);
      final memoMap = BenefitMemoUtils.parseBenefitByType(t.memo);
      if (memoMap.isNotEmpty) return _bucketize(memoMap);
      final amount = t.amount;
      if (amount <= 0) return const {};
      return {_catOther: amount};
    }
    if (t.type != TransactionType.expense) return const {};
    if (t.isRefund) return const {};

    final charged = t.cardChargedAmount;
    if (charged != null && charged > 0) {
      final diff = t.amount - charged;
      if (diff > 0) return {_catCard: diff};
      return const {};
    }

    final structured = t.benefitByType;
    if (structured.isNotEmpty) return _bucketize(structured);

    final memoMap = BenefitMemoUtils.parseBenefitByType(t.memo);
    if (memoMap.isNotEmpty) return _bucketize(memoMap);

    return const {};
  }

  Map<String, double> _bucketize(Map<String, double> raw) {
    final out = <String, double>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v.isNaN || v.isInfinite || v <= 0) continue;
      final cat = _normalizeKey(e.key);
      out[cat] = (out[cat] ?? 0) + v;
    }
    return out;
  }

  Map<String, double> _aggregateForPeriod() {
    final now = DateTime.now();
    final start = DateTime(now.year - _selectedYears, now.month, now.day);
    final totals = <String, double>{
      _catCard: 0,
      _catMart: 0,
      _catShopping: 0,
      _catOther: 0,
    };

    for (final t in _txs) {
      if (t.date.isBefore(start)) continue;
      if (t.date.isAfter(now)) continue;
      final bucket = _savedByCategory(t);
      for (final e in bucket.entries) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
    }
    return totals;
  }

  // ── UI ──

  @override
  @override
  Widget build(BuildContext context) => _buildContent(context);
  // ── Helper widgets ──
}
