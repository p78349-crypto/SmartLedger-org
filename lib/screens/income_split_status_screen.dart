import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/income_split_service.dart';
import '../services/account_service.dart';
import '../services/transaction_service.dart';
import '../utils/utils.dart';
import '../utils/category_definitions.dart';

part 'income_split_status_screen_subcategory.dart';
part 'income_split_status_screen_chart.dart';
part 'income_split_status_screen_overview.dart';

class IncomeSplitStatusScreen extends StatefulWidget {
  final String accountName;

  const IncomeSplitStatusScreen({super.key, required this.accountName});

  @override
  State<IncomeSplitStatusScreen> createState() =>
      _IncomeSplitStatusScreenState();
}

class _IncomeSplitStatusScreenState extends State<IncomeSplitStatusScreen> {
  final Map<String, Map<String, dynamic>> _subcategoryAllocations = {};

  late final StreamSubscription<void> _splitSub;

  @override
  void initState() {
    super.initState();
    _splitSub = IncomeSplitService().onChange.listen((_) {
      if (mounted) setState(() {});
    });

    final existing = IncomeSplitService().getSplit(widget.accountName);
    if (existing != null && existing.subcategoryAllocations.isNotEmpty) {
      _subcategoryAllocations.addAll(
        existing.subcategoryAllocations.map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _splitSub.cancel();
    super.dispose();
  }

  double _calculateAxisInterval(double maxValue) {
    if (maxValue <= 0) return 1;

    final rawInterval = maxValue / 4;
    double magnitude = 1;

    for (var i = 0; i < 10 && rawInterval / magnitude > 10; i++) {
      magnitude *= 10;
    }

    for (var i = 0; i < 10 && rawInterval / magnitude < 1; i++) {
      magnitude /= 10;
    }

    final normalized = rawInterval / magnitude;
    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    return niceNormalized * magnitude;
  }

  List<_SplitAllocationData> _splitAllocations(
    IncomeSplit split,
    double totalExpense,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final investmentColor = Color.lerp(scheme.primary, scheme.tertiary, 0.55)!;
    final double totalAllocated =
        split.savingsAmount +
        split.budgetAmount +
        split.emergencyAmount +
        split.assetTransferAmount;

    final double unassigned = split.totalIncome - totalAllocated;

    return [
      _SplitAllocationData(
        label: '저축',
        planned: split.savingsAmount,
        actual: split.savingsAmount,
        color: scheme.primary,
        description: '저축으로 이동',
      ),
      _SplitAllocationData(
        label: '예산',
        planned: split.budgetAmount,
        actual: totalExpense,
        color: scheme.tertiary,
        description: '지출 예산 사용',
      ),
      _SplitAllocationData(
        label: '비상금',
        planned: split.emergencyAmount,
        actual: split.emergencyAmount,
        color: scheme.secondary,
        description: '비상금으로 적립',
      ),
      _SplitAllocationData(
        label: '투자',
        planned: split.assetTransferAmount,
        actual: split.assetTransferAmount,
        color: investmentColor,
        description: '투자 자산으로 이동',
      ),
      if (unassigned > 0)
        _SplitAllocationData(
          label: '미배정',
          planned: unassigned,
          actual: 0,
          color: scheme.outline,
          description: '아직 계획되지 않은 금액',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final split = IncomeSplitService().getSplit(widget.accountName);
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );

    double totalExpense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.accountName} - 수입 배분')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: split == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('이번 달 수입 배분 내역이 없습니다.'),
                ),
              )
            : buildIncomeSplitOverview(split, totalExpense),
      ),
    );
  }
}

class _SplitAllocationData {
  final String label;
  final double planned;
  final double actual;
  final Color color;
  final String description;

  _SplitAllocationData({
    required this.label,
    required this.planned,
    required this.actual,
    required this.color,
    required this.description,
  });
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
