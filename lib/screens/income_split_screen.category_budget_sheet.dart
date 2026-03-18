// ignore_for_file: invalid_use_of_protected_member
part of 'income_split_screen.dart';

/// Extension: category budget bottom sheet.
extension IncomeSplitCategorySheet on _IncomeSplitScreenState {
  Future<void> _openCategoryBudgetSheet() async {
    final categories =
        CategoryDefinitions.mainCategories
            .where((c) => c != CategoryDefinitions.defaultCategory)
            .toList()
          ..add(CategoryDefinitions.defaultCategory);

    if (categories.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.showInfo(context, '설정 가능한 카테고리가 없습니다.');
      return;
    }

    final localBudgets = Map<String, double>.from(_categoryBudgets);
    final controllers = <String, TextEditingController>{};
    final focusNodes = <String, FocusNode>{};
    final fieldKeys = <String, GlobalKey>{};
    String? activeCategory;

    for (final category in categories) {
      final amount = localBudgets[category] ?? 0;
      controllers[category] = TextEditingController(
        text: amount > 0 ? CurrencyFormatter.currency.format(amount) : '',
      );
      fieldKeys[category] = GlobalKey();
    }

    final result = await showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final allocated = localBudgets.values.fold<double>(
                0,
                (sum, v) => sum + v,
              );
              final remaining = _budget - allocated;
              final hasBudget = _budget > 0;
              final isWithinBudget = !hasBudget || remaining >= 0;

              void handleValueChange(String category, String value) {
                final sanitized = value.replaceAll(',', '');
                final parsed = double.tryParse(sanitized) ?? 0;
                setSheetState(() {
                  if (parsed <= 0) {
                    localBudgets.remove(category);
                    controllers[category]?.clear();
                  } else {
                    localBudgets[category] = parsed;
                  }
                });
              }

              void ensureVisibleFor(String category) {
                Future.delayed(const Duration(milliseconds: 120), () {
                  if (!mounted) return;
                  final ctx = fieldKeys[category]?.currentContext;
                  if (ctx == null || !ctx.mounted) return;
                  Scrollable.ensureVisible(
                    ctx,
                    duration: const Duration(milliseconds: 200),
                    alignment: 0.2,
                  );
                });
              }

              void clearAll() {
                setSheetState(() {
                  localBudgets.clear();
                  for (final c in controllers.values) {
                    c.clear();
                  }
                });
              }

              void closeSheet() {
                final sanitized = Map<String, double>.from(localBudgets)
                  ..removeWhere((_, v) => v <= 0);
                Navigator.of(context).pop(sanitized);
              }

              final scheme = Theme.of(context).colorScheme;

              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) closeSheet();
                },
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 8,
                      bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '카테고리 배분',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: closeSheet,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!hasBudget)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '예산 입력 시 초과 여부를 확인할 수 있습니다.',
                              style: TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (!hasBudget) const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isWithinBudget
                                ? scheme.primaryContainer
                                : scheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '지출 예산: ${CurrencyFormatter.format(_budget)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '배분 합계',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(allocated),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isWithinBudget
                                          ? scheme.primary
                                          : scheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasBudget) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      remaining >= 0 ? '남은 예산' : '초과 금액',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: remaining >= 0
                                            ? scheme.primary
                                            : scheme.error,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatSigned(remaining),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: remaining >= 0
                                            ? scheme.primary
                                            : scheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final ctrl = controllers[cat]!;
                              final fn = focusNodes.putIfAbsent(cat, () {
                                final node = FocusNode();
                                node.addListener(() {
                                  if (!node.hasFocus) return;
                                  setSheetState(() => activeCategory = cat);
                                  ensureVisibleFor(cat);
                                });
                                return node;
                              });
                              return KeyedSubtree(
                                key: fieldKeys[cat],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SmartInputField(
                                      controller: ctrl,
                                      focusNode: fn,
                                      keyboardType: TextInputType.number,
                                      textInputAction:
                                          index < categories.length - 1
                                          ? TextInputAction.next
                                          : TextInputAction.done,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        _CurrencyInputFormatter(),
                                      ],
                                      hint: '배분 금액',
                                      suffixText: '원',
                                      onChanged: (v) =>
                                          handleValueChange(cat, v),
                                      onFieldSubmitted: (_) {
                                        if (index < categories.length - 1) {
                                          FocusScope.of(context).requestFocus(
                                            focusNodes[categories[index + 1]],
                                          );
                                        } else {
                                          FocusScope.of(context).unfocus();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (activeCategory != null) const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: localBudgets.isEmpty ? null : clearAll,
                              child: const Text('모든 배분 초기화'),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                final sanitized = Map<String, double>.from(
                                  localBudgets,
                                )..removeWhere((_, v) => v <= 0);
                                if (mounted) {
                                  setState(() => _categoryBudgets = sanitized);
                                }
                                SnackbarUtils.showInfo(context, '배분이 적용되었습니다.');
                                Navigator.of(context).pop(sanitized);
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('배분 적용'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    for (final n in focusNodes.values) {
      n.dispose();
    }
    for (final c in controllers.values) {
      c.dispose();
    }

    if (result != null && mounted) {
      setState(() {
        _categoryBudgets = Map<String, double>.from(result)
          ..removeWhere((_, v) => v <= 0);
      });
    }
  }
}
