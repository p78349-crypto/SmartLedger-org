import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/budget_service.dart';
import 'package:smart_ledger/services/income_split_service.dart';
import 'package:smart_ledger/utils/category_definitions.dart';
import 'package:smart_ledger/utils/income_category_definitions.dart';
import 'package:smart_ledger/utils/utils.dart';
import 'package:smart_ledger/widgets/one_ui_input_field.dart';

class IncomeSplitScreen extends StatefulWidget {
  final String accountName;
  final double? initialIncomeAmount;
  const IncomeSplitScreen({
    super.key,
    required this.accountName,
    this.initialIncomeAmount,
  });

  @override
  State<IncomeSplitScreen> createState() => _IncomeSplitScreenState();
}

class _IncomeSplitScreenState extends State<IncomeSplitScreen> {
  late TextEditingController _incomeController;
  late TextEditingController _savingsController;
  late TextEditingController _budgetController;
  late TextEditingController _emergencyController;
  late TextEditingController _assetController;
  late List<String> _availableAccounts = [];
  late String _targetAccount;

  double _totalIncome = 0;
  double _savings = 0;
  double _budget = 0;
  double _emergency = 0;
  double _assetTransfer = 0;

  Map<String, double> _categoryBudgets = <String, double>{};
  Map<String, double> _incomeAllocations = <String, double>{};

  double get _total => _savings + _budget + _emergency + _assetTransfer;
  double get _remaining => _totalIncome - _total;
  bool get _isValid =>
      (_totalIncome > 0 && _total <= _totalIncome) ||
      (_totalIncome == 0 && _total > 0);
  double get _categoryBudgetTotal =>
      _categoryBudgets.values.fold(0, (sum, value) => sum + value);

  @override
  void initState() {
    super.initState();
    _incomeController = TextEditingController();
    _savingsController = TextEditingController();
    _budgetController = TextEditingController();
    _emergencyController = TextEditingController();
    _assetController = TextEditingController();

    _incomeController.addListener(_updateCalculation);
    _savingsController.addListener(_updateCalculation);
    _budgetController.addListener(_updateCalculation);
    _emergencyController.addListener(_updateCalculation);
    _assetController.addListener(_updateCalculation);

    final accounts = AccountService().accounts;
    _availableAccounts = accounts.map((account) => account.name).toList();
    _targetAccount = _availableAccounts.contains(widget.accountName)
        ? widget.accountName
        : (_availableAccounts.isNotEmpty
              ? _availableAccounts.first
              : widget.accountName);

    _loadExisting();

    final initialAmount = widget.initialIncomeAmount;
    if ((initialAmount ?? 0) > 0) {
      _incomeController.text = CurrencyFormatter.currency.format(initialAmount);
      _updateCalculation();
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    _budgetController.dispose();
    _emergencyController.dispose();
    _assetController.dispose();
    super.dispose();
  }

  void _loadExisting() {
    final split = IncomeSplitService().getSplit(_targetAccount);
    if (split == null) {
      _updateCalculation();
      return;
    }

    void setController(TextEditingController controller, double value) {
      controller.text = value > 0
          ? CurrencyFormatter.currency.format(value)
          : '';
    }

    setController(_incomeController, split.totalIncome);
    setController(_savingsController, split.savingsAmount);
    setController(_budgetController, split.budgetAmount);
    setController(_emergencyController, split.emergencyAmount);
    setController(_assetController, split.assetTransferAmount);

    final sanitizedBudgets = Map<String, double>.from(split.categoryBudgets)
      ..removeWhere((_, value) => value <= 0);
    final allocations = _incomeAllocationsFromItems(split.incomeItems);

    setState(() {
      _totalIncome = split.totalIncome;
      _savings = split.savingsAmount;
      _budget = split.budgetAmount;
      _emergency = split.emergencyAmount;
      _assetTransfer = split.assetTransferAmount;
      _categoryBudgets = sanitizedBudgets;
      _incomeAllocations = allocations;
    });
  }

  void _updateCalculation() {
    double parse(TextEditingController controller) {
      final sanitized = controller.text.replaceAll(',', '').trim();
      if (sanitized.isEmpty) {
        return 0;
      }
      return double.tryParse(sanitized) ?? 0;
    }

    setState(() {
      _totalIncome = parse(_incomeController);
      _savings = parse(_savingsController);
      _budget = parse(_budgetController);
      _emergency = parse(_emergencyController);
      _assetTransfer = parse(_assetController);
    });
  }

  Future<void> _save() async {
    if (!_isValid) {
      if (!mounted) return;
      SnackbarUtils.showWarning(context, '총 수입보다 배분 금액이 많아서 저장할 수 없어요.');
      return;
    }

    if (_totalIncome == 0 && _total > 0) {
      _totalIncome = _total;
      _incomeController.text = CurrencyFormatter.currency.format(_totalIncome);
      if (mounted) {
        SnackbarUtils.showInfo(context, '총 수입이 비어 있어 배분 합계로 자동 설정했어요.');
      }
    }

    final sanitizedBudgets = Map<String, double>.from(_categoryBudgets)
      ..removeWhere((_, value) => value <= 0);

    List<IncomeItem> incomeItems;
    if (_incomeAllocations.isNotEmpty) {
      incomeItems = _buildIncomeItems(_incomeAllocations);
    } else if (_totalIncome > 0) {
      final mainCategory =
          IncomeCategoryDefinitions.defaultMainCategory ??
          IncomeCategoryDefinitions.defaultCategory;
      incomeItems = [
        IncomeItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: '총수입',
          amount: _totalIncome,
          category: mainCategory,
        ),
      ];
    } else {
      incomeItems = <IncomeItem>[];
    }

    await IncomeSplitService().setSplit(
      accountName: _targetAccount,
      incomeItems: incomeItems,
      savingsAmount: _savings,
      budgetAmount: _budget,
      emergencyAmount: _emergency,
      assetTransferAmount: _assetTransfer,
      categoryBudgets: sanitizedBudgets,
    );

    await BudgetService().setBudget(_targetAccount, _budget);

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, '수입 배분을 저장했어요.');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _openCategoryBudgetSheet() async {
    final categories =
        CategoryDefinitions.mainCategories
            .where(
              (category) => category != CategoryDefinitions.defaultCategory,
            )
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
          heightFactor: 0.75,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final allocated = localBudgets.values.fold<double>(
                0,
                (sum, value) => sum + value,
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
                // Delay slightly to allow keyboard to animate
                Future.delayed(const Duration(milliseconds: 120), () {
                  if (!mounted) {
                    return;
                  }
                  final key = fieldKeys[category];
                  final ctx = key?.currentContext;
                  if (ctx == null || !ctx.mounted) {
                    return;
                  }
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
                  for (final controller in controllers.values) {
                    controller.clear();
                  }
                });
              }

              void closeWithSanitizedBudgets() {
                final sanitized = Map<String, double>.from(localBudgets)
                  ..removeWhere((_, value) => value <= 0);
                Navigator.of(context).pop(sanitized);
              }

              final scheme = Theme.of(context).colorScheme;

              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) {
                    return;
                  }
                  closeWithSanitizedBudgets();
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
                              '카테고리별 예산 배분',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: closeWithSanitizedBudgets,
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
                            separatorBuilder: (_, unusedIndex) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final controller = controllers[category]!;
                              final focusNode = focusNodes.putIfAbsent(
                                category,
                                () {
                                  final node = FocusNode();
                                  node.addListener(() {
                                    if (!node.hasFocus) return;
                                    setSheetState(() {
                                      activeCategory = category;
                                    });
                                    ensureVisibleFor(category);
                                  });
                                  return node;
                                },
                              );

                              return KeyedSubtree(
                                key: fieldKeys[category],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    OneUiInputField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        _CurrencyInputFormatter(),
                                      ],
                                      hint: '배분 금액',
                                      suffixText: '원',
                                      onChanged: (value) =>
                                          handleValueChange(category, value),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (activeCategory != null) ...[
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            TextButton(
                              onPressed: localBudgets.isEmpty ? null : clearAll,
                              child: const Text('모든 배분 초기화'),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: isWithinBudget
                                  ? () {
                                      final sanitized =
                                          Map<String, double>.from(localBudgets)
                                            ..removeWhere(
                                              (_, value) => value <= 0,
                                            );

                                      if (mounted) {
                                        setState(() {
                                          _categoryBudgets = sanitized;
                                        });
                                      }

                                      SnackbarUtils.showInfo(
                                        context,
                                        '배분이 적용되었습니다. 계속 입력할 수 있어요.',
                                      );
                                    }
                                  : null,
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

    for (final node in focusNodes.values) {
      node.dispose();
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }

    for (final controller in controllers.values) {
      controller.dispose();
    }

    if (result != null && mounted) {
      setState(() {
        _categoryBudgets = Map<String, double>.from(result)
          ..removeWhere((_, value) => value <= 0);
      });
    }
  }

  Widget _buildCategoryBudgetCard() {
    final scheme = Theme.of(context).colorScheme;
    final entries = _categoryBudgets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _categoryBudgetTotal;
    final hasBudget = _budget > 0;
    final difference = _budget - total;
    final matchesBudget = !hasBudget || difference == 0;

    return Card(
      color: matchesBudget
          ? scheme.surface
          : (difference > 0 ? scheme.tertiaryContainer : scheme.errorContainer),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, size: 18),
                SizedBox(width: 8),
                Text(
                  '카테고리별 배분 요약',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (total > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.formatRatio(
                          entry.value,
                          total,
                          decimals: 1,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '배분 합계',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.format(total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (hasBudget) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    difference >= 0 ? '남은 예산' : '초과 금액',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: difference >= 0 ? scheme.primary : scheme.error,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatSigned(difference),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: difference >= 0 ? scheme.primary : scheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('수입 배분 설정'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton.filled(
                  onPressed: _isValid ? _save : null,
                  tooltip: '저장',
                  style: IconButton.styleFrom(
                    backgroundColor: _isValid
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    foregroundColor: _isValid
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                  icon: const Icon(Icons.save_outlined),
                ),
                Positioned.fill(
                  child: TextButton(
                    onPressed: _isValid ? _save : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: Colors.transparent,
                    ),
                    child: const Text(
                      '저장',
                      style: TextStyle(color: Colors.transparent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: scheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 이번 달 수입을 어떻게 배분하시겠어요?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '총 수입을 예금, 지출예산, 비상금으로 나누어 관리하세요.\n예산이 자동으로 설정됩니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 계정 선택
            if (_availableAccounts.length > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '어느 계정에 배분하시겠어요?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _targetAccount,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: _availableAccounts.map((account) {
                      return DropdownMenuItem(
                        value: account,
                        child: Text(account),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _targetAccount = newValue;
                          // 선택된 계정의 기존 설정 로드
                          _loadExisting();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            OneUiInputField(
              label: '💰 총 수입',
              hint: '이번 달 총 수입을 입력하세요',
              controller: _incomeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원',
              prefixIcon: const Icon(Icons.attach_money),
            ),
            // If total income is not set but split amounts exist,
            // surface a helper text below the field.
            if (_totalIncome == 0 && _total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '총 수입을 비워두면 입력하신 합계가 '
                  '총 수입으로 자동 설정됩니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openIncomeAllocationSheet,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('수입 항목 배분'),
            ),
            if (_incomeAllocations.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildIncomeAllocationCard(),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '배분 계획',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OneUiInputField(
              label: '🌱 예금 (예금)',
              hint: '은행 예금할 금액',
              controller: _savingsController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원',
              prefixIcon: const Icon(Icons.savings),
            ),
            const SizedBox(height: 12),
            OneUiInputField(
              label: '💳 지출 예산',
              hint: '생활비로 쓸 금액',
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원',
              prefixIcon: const Icon(Icons.shopping_cart),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openCategoryBudgetSheet,
              icon: const Icon(Icons.tune),
              label: const Text('카테고리별 예산 배분 옵션'),
            ),
            if (_categoryBudgets.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCategoryBudgetCard(),
            ],
            const SizedBox(height: 12),
            OneUiInputField(
              label: '🚨 비상금',
              hint: '비상시를 위한 금액',
              controller: _emergencyController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원',
              prefixIcon: const Icon(Icons.warning_amber),
            ),
            const SizedBox(height: 12),
            OneUiInputField(
              label: '🏦 자산 이동',
              hint: '자산으로 옮길 금액',
              controller: _assetController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원',
              prefixIcon: const Icon(Icons.account_balance_wallet),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '저장 시 입력한 금액만큼 자산 탭으로 자동 이동합니다',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              color: _isValid
                  ? scheme.primaryContainer
                  : (_totalIncome > 0
                        ? scheme.errorContainer
                        : scheme.surfaceContainerLow),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '총 수입',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormatter.format(_totalIncome),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildSummaryInline(
                      _savings,
                      _budget,
                      _emergency,
                      _assetTransfer,
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '배분 합계',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormatter.format(_total),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isValid ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _remaining >= 0 ? '남은 금액' : '초과 금액',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _remaining >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatSigned(_remaining),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _remaining >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryInline(
    double savings,
    double budget,
    double emergency,
    double assetTransfer,
  ) {
    Widget buildColumn(
      String label,
      double amount,
      Color color, {
      TextAlign align = TextAlign.start,
    }) {
      return Column(
        crossAxisAlignment: align == TextAlign.end
            ? CrossAxisAlignment.end
            : align == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(amount),
            textAlign: align,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: buildColumn('예금', savings, Colors.orange)),
            const VerticalDivider(width: 24, thickness: 0.5),
            Expanded(
              child: buildColumn(
                '예산',
                budget,
                Colors.blue,
                align: TextAlign.center,
              ),
            ),
            const VerticalDivider(width: 24, thickness: 0.5),
            Expanded(
              child: buildColumn(
                '비상금',
                emergency,
                Colors.purple,
                align: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '자산 이동',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                CurrencyFormatter.format(assetTransfer),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double get _incomeAllocationTotal =>
      _incomeAllocations.values.fold(0, (sum, value) => sum + value);

  Map<String, double> _incomeAllocationsFromItems(List<IncomeItem> items) {
    final allocations = <String, double>{};
    for (final item in items) {
      final normalized = _normalizeIncomeCategoryKey(
        item.category.isNotEmpty ? item.category : item.name,
      );
      if (item.amount <= 0) {
        continue;
      }
      allocations[normalized] = (allocations[normalized] ?? 0) + item.amount;
    }
    return allocations;
  }

  String _normalizeIncomeCategoryKey(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return IncomeCategoryDefinitions.defaultCategory;
    }

    const options = IncomeCategoryDefinitions.categoryOptions;
    if (options.containsKey(value)) {
      return value;
    }

    final valueLower = value.toLowerCase();

    for (final entry in options.entries) {
      if (entry.value.any(
        (sub) => sub == value || sub.toLowerCase() == valueLower,
      )) {
        return entry.key;
      }
    }

    switch (valueLower) {
      case 'salary':
      case 'main':
      case '주수입':
        return '주수입';
      case 'business':
      case '사업':
      case '사업소득':
        return '사업소득';
      case 'bonus':
      case 'sideincome':
      case '부수입':
      case '상여금':
        return '부수입';
      case 'finance':
      case '금융소득':
        return '금융소득';
      case 'other':
      case '기타':
      case '기타소득':
        return '기타소득';
    }

    return IncomeCategoryDefinitions.defaultCategory;
  }

  List<IncomeItem> _buildIncomeItems(Map<String, double> allocations) {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    var index = 0;
    return allocations.entries.map((entry) {
      index++;
      return IncomeItem(
        id: '${nowMicros}_income_$index',
        name: entry.key,
        amount: entry.value,
        category: entry.key,
      );
    }).toList();
  }

  Future<void> _openIncomeAllocationSheet() async {
    final categories =
        IncomeCategoryDefinitions.mainCategories
            .where(
              (category) =>
                  category != IncomeCategoryDefinitions.defaultCategory,
            )
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
          heightFactor: 0.9,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final allocated = localAllocations.values.fold<double>(
                0,
                (sum, value) => sum + value,
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
                  for (final controller in controllers.values) {
                    controller.clear();
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
                            '수입 항목 배분',
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
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final controller = controllers[category]!;
                            final focusNode = focusNodes.putIfAbsent(
                              category,
                              () {
                                final node = FocusNode();
                                node.addListener(() {
                                  if (!node.hasFocus) return;
                                  setSheetState(() {
                                    activeCategory = category;
                                  });
                                });
                                return node;
                              },
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                OneUiInputField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _CurrencyInputFormatter(),
                                  ],
                                  hint: '배분 금액',
                                  suffixText: '원',
                                  onChanged: (value) =>
                                      handleValueChange(category, value),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (activeCategory != null) ...[
                        const SizedBox(height: 12),
                      ],
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
                              )..removeWhere((_, value) => value <= 0);
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

    for (final controller in controllers.values) {
      controller.dispose();
    }

    for (final node in focusNodes.values) {
      node.dispose();
    }

    if (result != null && mounted) {
      setState(() {
        _incomeAllocations = Map<String, double>.from(result)
          ..removeWhere((_, value) => value <= 0);
      });
    }
  }

  Widget _buildIncomeAllocationCard() {
    final scheme = Theme.of(context).colorScheme;
    final entries = _incomeAllocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalAllocations = _incomeAllocationTotal;
    final difference = _totalIncome - totalAllocations;

    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '카테고리별 수입 배분',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.map((entry) {
              final percent = totalAllocations > 0
                  ? (entry.value / totalAllocations * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (totalAllocations > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '배분 합계',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.format(totalAllocations),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  difference >= 0 ? '남은 금액' : '초과 금액',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: difference >= 0 ? scheme.primary : scheme.error,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatSigned(difference),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: difference >= 0 ? scheme.primary : scheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 천 단위 구분 콤마를 자동으로 추가하는 입력 포매터
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 숫자만 추출
    final onlyDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (onlyDigits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 천 단위 구분
    final formatted = _formatWithCommas(onlyDigits);

    // 커서 위치 계산
    int cursorPosition = formatted.length;
    final oldOnlyDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');

    if (oldOnlyDigits.length < onlyDigits.length) {
      // 입력된 경우
      cursorPosition = formatted.length;
    } else if (oldOnlyDigits.length > onlyDigits.length) {
      // 삭제된 경우
      cursorPosition = newValue.selection.baseOffset;
      if (cursorPosition > 0 && formatted[cursorPosition - 1] == ',') {
        cursorPosition--;
      }
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  String _formatWithCommas(String text) {
    final buffer = StringBuffer();
    final length = text.length;

    for (int i = 0; i < length; i++) {
      // 앞에서부터 순회하며 남은 자리수가 3의 배수일 때 콤마를 찍는다 (선두 콤마 방지)
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}
