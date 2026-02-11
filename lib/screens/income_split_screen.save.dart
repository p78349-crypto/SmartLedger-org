// ignore_for_file: invalid_use_of_protected_member
part of 'income_split_screen.dart';

/// Extension: save income split.
extension IncomeSplitSave on _IncomeSplitScreenState {
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
      if (mounted) Navigator.of(context).pop(true);
    });
  }
}
