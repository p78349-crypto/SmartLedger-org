import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cooking_usage_log.dart';
import '../services/savings_statistics_service.dart';
import '../utils/currency_formatter.dart';
import 'meal_cost_experiment_screen.dart';

class CookingUsageHistoryScreen extends StatelessWidget {
  const CookingUsageHistoryScreen({super.key});

  List<_UsedIngredientRow> _parseUsedIngredients(String raw) {
    if (raw.trim().isEmpty) return const <_UsedIngredientRow>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_UsedIngredientRow>[];

      final out = <_UsedIngredientRow>[];
      for (final e in decoded) {
        if (e is! Map) continue;

        final group = (e['group'] as String?)?.trim() ?? 'ingredients';

        final name = (e['name'] as String?)?.trim() ?? '';
        if (name.isEmpty) continue;

        final used = (e['used'] as num?)?.toDouble();
        final unit = (e['unit'] as String?)?.trim() ?? '';
        final price = (e['price'] as num?)?.toDouble() ?? 0.0;

        out.add(
          _UsedIngredientRow(
            group: group,
            name: name,
            used: used,
            unit: unit,
            price: price,
          ),
        );
      }
      return out;
    } catch (_) {
      return const <_UsedIngredientRow>[];
    }
  }

  String _formatUsed(double? used, String unit) {
    if (used == null) return unit.isEmpty ? '-' : unit;
    final isInt = used == used.toInt();
    var v = isInt ? used.toInt().toString() : used.toStringAsFixed(2);
    if (v.contains('.')) {
      v = v.replaceFirst(RegExp(r'0+$'), '');
      v = v.replaceFirst(RegExp(r'\.$'), '');
    }
    return unit.isEmpty ? v : '$v$unit';
  }

  void _showLogDetail(BuildContext context, CookingUsageLog log) {
    final theme = Theme.of(context);
    final rows = _parseUsedIngredients(log.usedIngredientsJson);

    bool isRiceGroup(String g) => g == 'rice' || g == 'rice_snack';
    final riceTotal = rows
        .where((r) => isRiceGroup(r.group))
        .fold<double>(0.0, (acc, r) => acc + r.price);
    final riceRows = rows.where((r) => isRiceGroup(r.group)).toList();
    final ingredientRows = rows.where((r) => !isRiceGroup(r.group)).toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(log.recipeName.isEmpty ? '사용 기록' : log.recipeName),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(log.usageDate),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '합계: ${CurrencyFormatter.format(log.totalUsedPrice)}',
                style: theme.textTheme.titleMedium,
              ),
              if (riceTotal > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '쌀(참고): ${CurrencyFormatter.format(riceTotal)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Text('사용된 식재료 상세가 없습니다.', style: theme.textTheme.bodyMedium)
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (ingredientRows.isNotEmpty) ...[
                        Text('식재료', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 6),
                        ...ingredientRows.map(
                          (r) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(r.name),
                            subtitle: Text(_formatUsed(r.used, r.unit)),
                            trailing: Text(CurrencyFormatter.format(r.price)),
                          ),
                        ),
                      ],
                      if (riceRows.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('쌀(참고)', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 6),
                        ...riceRows.map(
                          (r) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(r.name),
                            subtitle: Text(_formatUsed(r.used, r.unit)),
                            trailing: Text(CurrencyFormatter.format(r.price)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('소비 기록'),
          actions: [
            IconButton(
              tooltip: '새 기록 입력(실험)',
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MealCostExperimentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: ValueListenableBuilder<List<CookingUsageLog>>(
          valueListenable: SavingsStatisticsService.instance.logs,
          builder: (context, logs, _) {
            final sorted = List<CookingUsageLog>.from(logs)
              ..sort((a, b) => b.usageDate.compareTo(a.usageDate));

            final total = sorted.fold<double>(
              0.0,
              (acc, l) => acc + l.totalUsedPrice,
            );

            if (sorted.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '아직 소비 기록이 없습니다.\n'
                    '재고 목록에서 요리/사용 모드로 사용량을 적용하면\n'
                    '여기에 기록이 쌓입니다.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('소비 기록', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                '${sorted.length}건',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(total),
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: sorted.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final log = sorted[i];
                      final rows = _parseUsedIngredients(
                        log.usedIngredientsJson,
                      );

                      bool isRiceGroup(String g) =>
                          g == 'rice' || g == 'rice_snack';
                      final riceTotal = rows
                          .where((r) => isRiceGroup(r.group))
                          .fold<double>(0.0, (acc, r) => acc + r.price);

                      final riceSuffix = riceTotal > 0
                          ? ' · 쌀(참고) ${CurrencyFormatter.format(riceTotal)}'
                          : '';

                      final subtitle =
                          '${DateFormat('MM/dd HH:mm').format(log.usageDate)}'
                          ' · ${rows.isEmpty ? '-' : '${rows.length}종'}'
                          '$riceSuffix';

                      return Card(
                        child: ListTile(
                          title: Text(
                            log.recipeName.isEmpty ? '사용 기록' : log.recipeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(subtitle),
                          trailing: Text(
                            CurrencyFormatter.format(log.totalUsedPrice),
                            style: theme.textTheme.titleMedium,
                          ),
                          onTap: () => _showLogDetail(context, log),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UsedIngredientRow {
  final String group;
  final String name;
  final double? used;
  final String unit;
  final double price;

  const _UsedIngredientRow({
    required this.group,
    required this.name,
    required this.used,
    required this.unit,
    required this.price,
  });
}
