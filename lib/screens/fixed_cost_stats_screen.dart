library fixed_cost_stats_screen;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fixed_cost.dart';
import '../navigation/app_routes.dart';
import '../services/fixed_cost_service.dart';
import '../utils/number_formats.dart';
import '../utils/stats_labels.dart';

part 'fixed_cost_stats_screen_list.dart';

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
          children: _buildSummaryAndList(theme, isLandscape),
        ),
      ),
    );
  }
}
