// ignore_for_file: invalid_use_of_protected_member
part of 'income_split_screen.dart';

/// Extension: income allocation bottom sheet.
extension IncomeSplitAllocationSheet on _IncomeSplitScreenState {
  Future<void> _openIncomeAllocationSheet() async {
    final categories =
        IncomeCategoryDefinitions.mainCategories
            .where((c) => c != IncomeCategoryDefinitions.defaultCategory)
            .toList()
          ..add(IncomeCategoryDefinitions.defaultCategory);

    final localAllocations = Map<String, double>.from(_incomeAllocations);
    final controllers = <String, TextEditingController>{};
    final focusNodes = <String, FocusNode>{};
    String? activeCategory;

    for (final category in categories) {
      final amount = localAllocations[category] ?? 0;
      controllers[category] = TextEditingController(
        text: amount > 0 ? CurrencyFormatter.currency.format(amount) : '',
      );
    }

    final result = await showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final allocated = localAllocations.values.fold<double>(
                0,
                (sum, v) => sum + v,
              );
              final difference = _totalIncome - allocated;
              final hasTotalIncome = _totalIncome > 0;

              void handleValueChange(String category, String value) {
                final sanitized = value.replaceAll(',', '');
                final parsed = double.tryParse(sanitized) ?? 0;
                setSheetState(() {
                  if (parsed <= 0) {
                    localAllocations.remove(category);
                    controllers[category]?.clear();
                  } else {
                    localAllocations[category] = parsed;
                  }
                });
              }

              void clearAll() {
                setSheetState(() {
                  localAllocations.clear();
                  for (final c in controllers.values) {
                    c.clear();
                  }
                });
              }

              final scheme = Theme.of(context).colorScheme;

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '수입을 자산으로',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '총 수입: ${CurrencyFormatter.format(_totalIncome)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '배분 합계',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  CurrencyFormatter.format(allocated),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: difference >= 0
                                        ? scheme.primary
                                        : scheme.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  difference >= 0 ? '남은 금액' : '초과 금액',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: difference >= 0
                                        ? scheme.primary
                                        : scheme.error,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatSigned(difference),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: difference >= 0
                                        ? scheme.primary
                                        : scheme.error,
                                  ),
                                ),
                              ],
                            ),
                            if (!hasTotalIncome)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '총 수입을 입력하면 초과 여부를 더 쉽게 확인할 수 있어요.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
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
                              });
                              return node;
                            });
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SmartInputField(
                                  controller: ctrl,
                                  focusNode: fn,
                                  keyboardType: TextInputType.number,
                                  textInputAction: index < categories.length - 1
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _CurrencyInputFormatter(),
                                  ],
                                  hint: '배분 금액',
                                  suffixText: '원',
                                  onChanged: (v) => handleValueChange(cat, v),
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
                            );
                          },
                        ),
                      ),
                      if (activeCategory != null) const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: localAllocations.isEmpty
                                ? null
                                : clearAll,
                            child: const Text('모든 배분 초기화'),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () {
                              final sanitized = Map<String, double>.from(
                                localAllocations,
                              )..removeWhere((_, v) => v <= 0);
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
              );
            },
          ),
        );
      },
    );

    for (final c in controllers.values) {
      c.dispose();
    }
    for (final n in focusNodes.values) {
      n.dispose();
    }

    if (result != null && mounted) {
      setState(() {
        _incomeAllocations = Map<String, double>.from(result)
          ..removeWhere((_, v) => v <= 0);
      });
    }
  }
}
