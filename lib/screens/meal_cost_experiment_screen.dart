import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/savings_statistics_service.dart';
import '../utils/currency_formatter.dart';

class MealCostExperimentScreen extends StatefulWidget {
  const MealCostExperimentScreen({super.key});

  @override
  State<MealCostExperimentScreen> createState() =>
      _MealCostExperimentScreenState();
}

class _MealCostExperimentScreenState extends State<MealCostExperimentScreen> {
  final _titleController = TextEditingController(text: '오늘의 한 끼');

  final List<_MealItemInput> _ingredients = <_MealItemInput>[];
  final List<_MealItemInput> _rice = <_MealItemInput>[];

  @override
  void initState() {
    super.initState();
    SavingsStatisticsService.instance.load();

    _ingredients.add(_MealItemInput());
    _rice.add(_MealItemInput());
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final i in _ingredients) {
      i.dispose();
    }
    for (final i in _rice) {
      i.dispose();
    }
    super.dispose();
  }

  double _sumPrice(List<_MealItemInput> items) {
    return items.fold<double>(0.0, (acc, it) => acc + it.priceValue);
  }

  double get _ingredientsTotal => _sumPrice(_ingredients);
  double get _riceTotal => _sumPrice(_rice);

  List<Map<String, dynamic>> _toUsedIngredientsJson() {
    final out = <Map<String, dynamic>>[];

    void addAll(String group, List<_MealItemInput> items) {
      for (final it in items) {
        final name = it.name.trim();
        if (name.isEmpty) continue;

        out.add(<String, dynamic>{
          'group': group,
          'name': name,
          'used': it.gramsValue,
          'unit': 'g',
          'price': it.priceValue,
        });
      }
    }

    addAll('ingredients', _ingredients);
    addAll('rice', _rice);

    return out;
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final used = _toUsedIngredientsJson();

    if (used.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 항목을 입력하세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await SavingsStatisticsService.instance.addLog(
      recipeName: title.isEmpty ? '오늘의 한 끼' : title,
      totalUsedPrice: _ingredientsTotal,
      usedIngredientsJson: jsonEncode(used),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _buildMainCard(ThemeData theme) {
    return Card(
      child: ExpansionTile(
        title: Text(
          '오늘의 한 끼: ${CurrencyFormatter.format(_ingredientsTotal)}',
          style: theme.textTheme.titleLarge,
        ),
        subtitle: Text('쌀은 참고용으로 분리 표시됩니다.', style: theme.textTheme.bodySmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '식재료 ${CurrencyFormatter.format(_ingredientsTotal)}'
                  ' + 쌀(참고) ${CurrencyFormatter.format(_riceTotal)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('상세 내역 (실측 무게 기반)'),
            children: [
              _buildDetailGroup(theme, title: '식재료', items: _ingredients),
              const SizedBox(height: 8),
              _buildDetailGroup(theme, title: '쌀(참고)', items: _rice),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGroup(
    ThemeData theme, {
    required String title,
    required List<_MealItemInput> items,
  }) {
    final visible = items.where((e) => e.name.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        if (visible.isEmpty)
          Text('입력된 항목이 없습니다.', style: theme.textTheme.bodySmall)
        else
          Column(
            children: [
              for (final it in visible)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${it.name.trim()} ${it.gramsLabel}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(CurrencyFormatter.format(it.priceValue)),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required List<_MealItemInput> items,
    required VoidCallback onAdd,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final it in items)
              _MealItemRow(
                input: it,
                onRemove: items.length <= 1
                    ? null
                    : () {
                        setState(() {
                          items.remove(it);
                          it.dispose();
                        });
                      },
                onChanged: () => setState(() {}),
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
      appBar: AppBar(title: const Text('한 끼 비용 (실험 폼)')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '요리명/기록 제목',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildMainCard(theme),
          const SizedBox(height: 12),
          _buildSection(
            theme,
            title: '식재료',
            items: _ingredients,
            onAdd: () {
              setState(() => _ingredients.add(_MealItemInput()));
            },
          ),
          _buildSection(
            theme,
            title: '쌀(참고)',
            items: _rice,
            onAdd: () {
              setState(() => _rice.add(_MealItemInput()));
            },
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('저장 (소비 기록에 추가)')),
        ],
      ),
    );
  }
}

class _MealItemInput {
  final nameController = TextEditingController();
  final gramsController = TextEditingController();
  final priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    gramsController.dispose();
    priceController.dispose();
  }

  String get name => nameController.text;

  double get gramsValue {
    final raw = gramsController.text.trim();
    final v = double.tryParse(raw);
    return (v ?? 0.0).clamp(0.0, double.infinity);
  }

  String get gramsLabel {
    final g = gramsValue;
    if (g <= 0) return '';
    final isInt = g == g.toInt();
    return isInt ? '${g.toInt()}g' : '${g.toStringAsFixed(1)}g';
  }

  double get priceValue {
    final raw = priceController.text.trim().replaceAll(',', '');
    final v = double.tryParse(raw);
    return (v ?? 0.0).clamp(0.0, double.infinity);
  }
}

class _MealItemRow extends StatelessWidget {
  final _MealItemInput input;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _MealItemRow({
    required this.input,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              controller: input.nameController,
              decoration: const InputDecoration(
                labelText: '품목',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: input.gramsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'g',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: input.priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '원',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              tooltip: '삭제',
            ),
          ],
        ],
      ),
    );
  }
}
