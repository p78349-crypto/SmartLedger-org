part of 'income_split_status_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension IncomeSplitSubcategoryModal on _IncomeSplitStatusScreenState {
  void openSubcategoryModal(String mainCategory) async {
    final subcategories =
        _subcategoryAllocations[mainCategory]?.keys.toList() ?? [];
    final controllers = <String, TextEditingController>{};
    final selectedTargets = <String, String?>{};
    final accounts = AccountService().accounts.map((a) => a.name).toList();
    for (final sub in subcategories) {
      final entry = _subcategoryAllocations[mainCategory]![sub];
      controllers[sub] = TextEditingController(
        text: entry != null && entry['amount'] != null
            ? entry['amount'].toString()
            : '',
      );
      selectedTargets[sub] = entry != null
          ? (entry['targetAccount'] as String?)
          : null;
    }
    // Allow adding new subcategory
    String newSubcategory = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$mainCategory 소분류 배분',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...controllers.entries.map((entry) {
                    final sub = entry.key;
                    return Row(
                      children: [
                        Expanded(child: Text(sub)),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: entry.value,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(suffixText: '원'),
                            onChanged: (val) {
                              setSheetState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String?>(
                            initialValue: selectedTargets[sub],
                            items: [
                              const DropdownMenuItem<String?>(
                                child: Text('대상계좌 없음'),
                              ),
                              ...accounts.map(
                                (a) => DropdownMenuItem<String?>(
                                  value: a,
                                  child: Text(a),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setSheetState(() {
                                selectedTargets[sub] = val;
                              });
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () {
                            setSheetState(() {
                              controllers.remove(entry.key);
                              selectedTargets.remove(entry.key);
                            });
                          },
                        ),
                      ],
                    );
                  }),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(hintText: '새 소분류명'),
                          onChanged: (val) {
                            newSubcategory = val;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (newSubcategory.trim().isEmpty) return;
                          setSheetState(() {
                            controllers[newSubcategory] =
                                TextEditingController();
                            newSubcategory = '';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // Save subcategory allocations with target accounts
                          final updated = <String, Map<String, dynamic>>{};
                          controllers.forEach((k, v) {
                            final val = double.tryParse(
                              v.text.replaceAll(',', ''),
                            );
                            if (val != null && val > 0) {
                              updated[k] = {
                                'amount': val,
                                'targetAccount': selectedTargets[k],
                              };
                            }
                          });
                          setState(() {
                            _subcategoryAllocations[mainCategory] = updated;
                          });
                          Navigator.of(context).pop();

                          // Persist allocations to service
                          final existing = IncomeSplitService().getSplit(
                            widget.accountName,
                          );
                          await IncomeSplitService().setSplit(
                            accountName: widget.accountName,
                            incomeItems:
                                existing?.incomeItems ?? <IncomeItem>[],
                            savingsAmount: existing?.savingsAmount ?? 0,
                            budgetAmount: existing?.budgetAmount ?? 0,
                            emergencyAmount: existing?.emergencyAmount ?? 0,
                            assetTransferAmount:
                                existing?.assetTransferAmount ?? 0,
                            categoryBudgets: existing?.categoryBudgets ?? {},
                            subcategoryAllocations: _subcategoryAllocations,
                            createAssetMoves: false,
                          );
                        },
                        child: const Text('저장'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
