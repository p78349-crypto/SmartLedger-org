import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../models/investment_goal.dart';
import '../services/asset_service.dart';
import '../services/investment_goal_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class AssetInvestmentRoadmapScreen extends StatefulWidget {
  final String accountName;

  const AssetInvestmentRoadmapScreen({super.key, required this.accountName});

  @override
  State<AssetInvestmentRoadmapScreen> createState() =>
      _AssetInvestmentRoadmapScreenState();
}

class _AssetInvestmentRoadmapScreenState
    extends State<AssetInvestmentRoadmapScreen> {
  final _goalService = InvestmentGoalService();
  bool _isLoading = true;
  List<Asset> _assets = [];
  List<InvestmentGoal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final assetService = AssetService();
    await assetService.loadAssets();
    final assets = assetService.getAssets(widget.accountName);
    final goals = await _goalService.getGoals(widget.accountName);
    if (!mounted) return;
    setState(() {
      _assets = assets;
      _goals = goals;
      _isLoading = false;
    });
  }

  Future<void> _promptAddGoal() async {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController();
    InvestmentGoalType type = InvestmentGoalType.emergencyFund;
    InvestmentGoalHorizon horizon = InvestmentGoalHorizon.shortTerm;
    DateTime? targetDate;
    int priority = 3;
    AssetRiskLevel? riskLevel;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('목표 추가'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: '목표명'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<InvestmentGoalType>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: '목표 유형'),
                      items: InvestmentGoalType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => type = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<InvestmentGoalHorizon>(
                      initialValue: horizon,
                      decoration: const InputDecoration(labelText: '기간'),
                      items: InvestmentGoalHorizon.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => horizon = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: targetController,
                      decoration: const InputDecoration(labelText: '목표 금액'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: currentController,
                      decoration: const InputDecoration(labelText: '현재 금액'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: '우선순위'),
                      items: [1, 2, 3, 4, 5]
                          .map(
                            (t) =>
                                DropdownMenuItem(value: t, child: Text('P$t')),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => priority = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AssetRiskLevel>(
                      initialValue: riskLevel,
                      decoration: const InputDecoration(labelText: '리스크'),
                      items: AssetRiskLevel.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => riskLevel = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: targetDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => targetDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event_available),
                      label: Text(
                        targetDate == null
                            ? '목표 날짜 선택'
                            : DateFormatter.defaultDate.format(targetDate!),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    final targetAmount =
        CurrencyFormatter.parse(targetController.text.trim()) ?? 0;
    final currentAmount =
        CurrencyFormatter.parse(currentController.text.trim()) ?? 0;
    final goal = InvestmentGoal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      type: type,
      horizon: horizon,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
      priority: priority,
      riskLevel: riskLevel?.label,
    );

    final goals = await _goalService.addGoal(widget.accountName, goal);
    if (!mounted) return;
    setState(() => _goals = goals);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('투자 로드맵'),
        actions: [
          IconButton(
            onPressed: _promptAddGoal,
            icon: const Icon(Icons.add),
            tooltip: '목표 추가',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOverviewSection(theme),
            const SizedBox(height: 16),
            _buildGoalSection(theme, InvestmentGoalHorizon.shortTerm),
            const SizedBox(height: 16),
            _buildGoalSection(theme, InvestmentGoalHorizon.midTerm),
            const SizedBox(height: 16),
            _buildGoalSection(theme, InvestmentGoalHorizon.longTerm),
            const SizedBox(height: 16),
            _buildInsightSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(ThemeData theme) {
    final totalAssets = _assets.fold<double>(
      0,
      (sum, asset) => sum + asset.amount,
    );
    return _buildSectionCard(
      theme,
      title: '1. 현재 상태 분석',
      children: [
        _buildInfoCard(
          theme,
          rows: [
            _MetricRow('총 자산', CurrencyFormatter.format(totalAssets)),
            const _MetricRow('구성/수익률', '자산 분석/대시보드에서 확인'),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalSection(ThemeData theme, InvestmentGoalHorizon horizon) {
    final goals = _goals.where((g) => g.horizon == horizon).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return _buildSectionCard(
      theme,
      title: '목표: ${horizon.label}',
      children: [
        if (goals.isEmpty)
          Text('등록된 목표가 없습니다.', style: theme.textTheme.bodySmall)
        else
          ...goals.map((goal) => _buildGoalTile(theme, goal)),
      ],
    );
  }

  Widget _buildGoalTile(ThemeData theme, InvestmentGoal goal) {
    final progress = goal.progressPct;
    final progressText = progress.isNaN
        ? '0%'
        : '${progress.toStringAsFixed(1)}%';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text('P${goal.priority}', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${goal.type.label} · ${goal.horizon.label}',
            style: theme.textTheme.bodySmall,
          ),
          if (goal.riskLevel != null) ...[
            const SizedBox(height: 4),
            Text('리스크: ${goal.riskLevel}', style: theme.textTheme.bodySmall),
          ],
          if (goal.targetDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '목표일: ${DateFormatter.defaultDate.format(goal.targetDate!)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${CurrencyFormatter.format(goal.currentAmount)} / '
            '${CurrencyFormatter.format(goal.targetAmount)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: goal.targetAmount <= 0
                ? 0
                : (goal.currentAmount / goal.targetAmount),
          ),
          const SizedBox(height: 6),
          Text('달성률: $progressText', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildInsightSection(ThemeData theme) {
    final insights = <String>[];
    for (final asset in _assets) {
      if (asset.alertThreshold != null &&
          asset.amount < asset.alertThreshold!) {
        insights.add('${asset.name}: 임계값 이하');
      }
      if (asset.maturityDate != null) {
        final days = asset.maturityDate!.difference(DateTime.now()).inDays;
        if (days >= 0 && days <= 30) {
          insights.add('${asset.name}: 만기 임박 ($days일 남음)');
        }
      }
      if (asset.debtAmount != null && asset.debtAmount! > 0) {
        insights.add('${asset.name}: 부채 보유');
      }
    }

    final cashTotal = _assets
        .where((a) => a.category == AssetCategory.cash)
        .fold<double>(0, (sum, asset) => sum + asset.amount);
    final totalAssets = _assets.fold<double>(
      0,
      (sum, asset) => sum + asset.amount,
    );
    final cashRatio = totalAssets <= 0 ? 0 : (cashTotal / totalAssets) * 100;
    if (cashRatio < 10) {
      insights.add('현금 비중이 낮습니다. 비상금 비중을 점검하세요.');
    }

    return _buildSectionCard(
      theme,
      title: '5. 인사이트 & 알림',
      children: [
        if (insights.isEmpty)
          Text('특이사항 없음', style: theme.textTheme.bodySmall)
        else
          ...insights.map((i) => _buildInsightRow(theme, i)),
      ],
    );
  }

  Widget _buildInsightRow(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    String? title,
    required List<_MetricRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (final row in rows) _buildMetricRow(theme, row),
        ],
      ),
    );
  }

  Widget _buildMetricRow(ThemeData theme, _MetricRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              row.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow {
  final String label;
  final String value;

  const _MetricRow(this.label, this.value);
}
