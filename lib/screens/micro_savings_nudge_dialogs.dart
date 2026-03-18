import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/currency_formatter.dart';

import '../utils/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

/// Shows a quick-record dialog for skipped spend or saved points.
///
/// Returns `true` if a transaction was saved, `false` otherwise.
Future<bool> showQuickRecordDialog(
  BuildContext context, {
  required String accountName,
  required String title,
  required String description,
  required String memoTag,
}) async {
  final List<TextEditingController> amountControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> memoControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<FocusNode> amountFocusNodes = List.generate(5, (_) => FocusNode());
  final TextEditingController targetController = TextEditingController(
    text: '100,000,000',
  );

  final prefs = await SharedPreferences.getInstance();
  final projectSafeRatePct =
      prefs.getDouble(PrefKeys.project100mSafeRatePctV1) ?? 3.0;

  double selectedTarget = 100000000;
  bool showCalculation = false;

  if (!context.mounted) return false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          // 동적으로 입력된 목표 금액 파싱
          final targetInput =
              CurrencyFormatter.parse(
                targetController.text.trim(),
              )?.toDouble() ??
              selectedTarget;

          double totalInput = 0;
          for (var c in amountControllers) {
            final val = CurrencyFormatter.parse(c.text.trim());
            if (val != null) totalInput += val;
          }

          // 10년 후 미래가치 계산
          final r = (projectSafeRatePct / 100.0) / 12.0;
          const n10 = 120.0; // 10년
          double fv10 = 0;
          double monthsToTarget = 0;
          double requiredMonthlyFor10y = 0;

          if (totalInput > 0) {
            // 1. 10년 후 얼마가 되는가
            if (r > 0) {
              fv10 = totalInput * (math.pow(1 + r, n10) - 1) / r * (1 + r);
              // 2. 목표달성까지 몇 달 걸리는가
              final val = (targetInput * r) / (totalInput * (1 + r)) + 1;
              if (val > 0) {
                monthsToTarget = math.log(val) / math.log(1 + r);
              }
              // 3. 10년안에 목표 달성하려면 월 얼마 필요한가
              requiredMonthlyFor10y =
                  targetInput * r / ((math.pow(1 + r, n10) - 1) * (1 + r));
            } else {
              fv10 = totalInput * n10;
              monthsToTarget = targetInput / totalInput;
              requiredMonthlyFor10y = targetInput / n10;
            }
          }

          return AlertDialog(
            title: Text('$title 기록'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 목표 선택 및 직접 입력
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '목표 설정:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('1,000만'),
                                selected:
                                    targetController.text == '10,000,000' ||
                                    selectedTarget == 10000000,
                                onSelected: (val) => setDialogState(() {
                                  selectedTarget = 10000000;
                                  targetController.text = '10,000,000';
                                }),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('3,000만'),
                                selected:
                                    targetController.text == '30,000,000' ||
                                    selectedTarget == 30000000,
                                onSelected: (val) => setDialogState(() {
                                  selectedTarget = 30000000;
                                  targetController.text = '30,000,000';
                                }),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('5,000만'),
                                selected:
                                    targetController.text == '50,000,000' ||
                                    selectedTarget == 50000000,
                                onSelected: (val) => setDialogState(() {
                                  selectedTarget = 50000000;
                                  targetController.text = '50,000,000';
                                }),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('1억'),
                                selected:
                                    targetController.text == '100,000,000' ||
                                    selectedTarget == 100000000,
                                onSelected: (val) => setDialogState(() {
                                  selectedTarget = 100000000;
                                  targetController.text = '100,000,000';
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: targetController,
                          decoration: const InputDecoration(
                            labelText: '직접 입력 (목표 금액)',
                            isDense: true,
                            suffixText: '원',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setDialogState(() {}),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ...List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: amountControllers[index],
                                focusNode: amountFocusNodes[index],
                                decoration: InputDecoration(
                                  labelText: '금액 ${index + 1}',
                                  hintText: '0',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) {
                                  if (showCalculation) {
                                    setDialogState(
                                      () => showCalculation = false,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: memoControllers[index],
                                decoration: InputDecoration(
                                  labelText: '메모 ${index + 1}',
                                  hintText: '선택',
                                  isDense: true,
                                ),
                                textInputAction: index == 4
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    if (!showCalculation)
                      OutlinedButton.icon(
                        onPressed: totalInput > 0
                            ? () => setDialogState(() => showCalculation = true)
                            : null,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('미래가치 계산해보기'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            ctx,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              ctx,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '💰 월 합계: ${CurrencyFormatter.format(totalInput)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 16),
                            Text(
                              '📅 10년 후 예상: ${CurrencyFormatter.format(fv10)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '🚀 목표(${CurrencyFormatter.format(selectedTarget)}) 달성까지: '
                              '${monthsToTarget > 0 ? (monthsToTarget / 12).toStringAsFixed(1) : "?? "}년',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '💡 10년 만에 ${CurrencyFormatter.format(selectedTarget)}을 모으려면?\n'
                              '매달 ${CurrencyFormatter.format(requiredMonthlyFor10y)} 저축이 필요해요.',
                              style: TextStyle(
                                color: Theme.of(ctx).colorScheme.primary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('기록하기'),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved != true || !context.mounted) {
    for (var c in amountControllers) {
      c.dispose();
    }
    for (var c in memoControllers) {
      c.dispose();
    }
    for (var f in amountFocusNodes) {
      f.dispose();
    }
    return false;
  }

  int savedCount = 0;
  double savedTotal = 0;

  for (int i = 0; i < 5; i++) {
    final parsed = CurrencyFormatter.parse(amountControllers[i].text.trim());
    if (parsed == null || parsed <= 0) continue;

    final amount = parsed.toDouble();
    final memoRaw = memoControllers[i].text.trim();
    final memo = memoRaw.isEmpty ? memoTag : '$memoTag $memoRaw';

    final tx = Transaction(
      id: 'micro_${DateTime.now().millisecondsSinceEpoch}_$i',
      type: TransactionType.savings,
      description: title,
      amount: amount,
      date: DateTime.now(),
      memo: memo,
      savingsAllocation: SavingsAllocation.assetIncrease,
    );

    await TransactionService().addTransaction(accountName, tx);
    savedCount++;
    savedTotal += amount;
  }

  for (var c in amountControllers) {
    c.dispose();
  }
  for (var c in memoControllers) {
    c.dispose();
  }
  for (var f in amountFocusNodes) {
    f.dispose();
  }

  if (savedCount > 0 && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title $savedCount건 (${CurrencyFormatter.format(savedTotal)}) 저장 완료',
        ),
      ),
    );
    return true;
  }

  return false;
}

/// Shows a round-up savings dialog.
///
/// Returns `true` if a transaction was saved, `false` otherwise.
Future<bool> showRoundUpDialog(
  BuildContext context, {
  required String accountName,
}) async {
  final amountController = TextEditingController();
  final amountFocusNode = FocusNode();

  var unit = 1000.0;
  double? computed;

  double computeRoundUp(double base) {
    if (base <= 0) return 0;
    if (unit <= 0) return 0;
    final rounded = (base / unit).ceil() * unit;
    final diff = rounded - base;
    return diff > 0 ? diff : 0;
  }

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!dialogContext.mounted) return;
        if (!amountFocusNode.hasFocus) {
          amountFocusNode.requestFocus();
        }
        final text = amountController.text;
        amountController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
      });

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final parsed = CurrencyFormatter.parse(amountController.text.trim());
          final base = (parsed ?? 0).toDouble();
          computed = computeRoundUp(base);

          return AlertDialog(
            title: const Text('잔돈 모으기(반올림)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  focusNode: amountFocusNode,
                  decoration: const InputDecoration(
                    labelText: '결제 금액',
                    hintText: '예: 9900',
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<double>(
                  key: ValueKey<double>(unit),
                  initialValue: unit,
                  decoration: const InputDecoration(labelText: '반올림 단위'),
                  items: const [
                    DropdownMenuItem(value: 1000, child: Text('1,000원')),
                    DropdownMenuItem(value: 10000, child: Text('10,000원')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setDialogState(() => unit = v);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  '저축 금액(잔돈): ${CurrencyFormatter.format(computed ?? 0)}',
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '이 기록은 1억 프로젝트의 "혜택/절약"에 포함됩니다.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('저축 기록'),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved != true || !context.mounted) {
    amountController.dispose();
    amountFocusNode.dispose();
    return false;
  }

  final parsed = CurrencyFormatter.parse(amountController.text.trim());
  amountController.dispose();
  amountFocusNode.dispose();

  final base = (parsed ?? 0).toDouble();
  final diff = computeRoundUp(base);
  if (base <= 0 || diff <= 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('반올림할 금액이 없습니다.')));
    }
    return false;
  }

  final rounded = (base / unit).ceil() * unit;
  final memo =
      '${BenefitAggregationUtils.roundUpMemoTag} '
      '${CurrencyFormatter.format(base)}→'
      '${CurrencyFormatter.format(rounded)}';

  final tx = Transaction(
    id: 'roundup_${DateTime.now().millisecondsSinceEpoch}',
    type: TransactionType.savings,
    description: '잔돈 모으기',
    amount: diff,
    date: DateTime.now(),
    memo: memo,
    savingsAllocation: SavingsAllocation.assetIncrease,
  );

  await TransactionService().addTransaction(accountName, tx);
  if (!context.mounted) return true;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('잔돈 ${CurrencyFormatter.format(diff)} 저축 저장 완료')),
  );

  return true;
}
