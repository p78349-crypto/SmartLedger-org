import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/pref_keys.dart';
import 'micro_savings_nudge_dialogs.dart';

part 'micro_savings_nudge_screen_logic.dart';
part 'micro_savings_nudge_screen_ui.dart';

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
  final List<TextEditingController> _amountControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _memoControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final TextEditingController _targetController = TextEditingController(
    text: '100,000,000',
  );
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

  @override
  @override
  Widget build(BuildContext context) => _buildContent(context);
}
