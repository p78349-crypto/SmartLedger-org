// ignore_for_file: invalid_use_of_protected_member
part of 'asset_input_screen.dart';

extension _HelpersExt on _AssetInputScreenState {
  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialAssetFormSnapshot(
      nameText: _nameController.text,
      amountText: _amountController.text,
      memoText: _memoController.text,
      ratioText: _ratioController.text,
      targetAmountText: _targetAmountController.text,
      costBasisText: _costBasisController.text,
      expectedAnnualRateText: _expectedAnnualRateController.text,
      tickerText: _tickerController.text,
      institutionText: _institutionController.text,
      currencyText: _currencyController.text,
      unitsText: _unitsController.text,
      unitPriceText: _unitPriceController.text,
      appraisalValueText: _appraisalValueController.text,
      monthlyIncomeText: _monthlyIncomeController.text,
      debtAmountText: _debtAmountController.text,
      alertThresholdText: _alertThresholdController.text,
      assetDate: _assetDate,
      maturityDate: _maturityDate,
      selectedCategory: _selectedCategory,
      isInvestment: _isInvestment,
      riskLevel: _riskLevel,
    );
  }

  Future<void> _promptRevertToInitial() async {
    _captureInitialSnapshotIfNeeded();
    final snapshot = _initialSnapshot;
    if (snapshot == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('입력값 되돌리기'),
          content: const Text('화면을 열었을 때의 입력값으로 되돌릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('되돌리기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      FocusScope.of(context).unfocus();
      setState(() {
        _nameController.text = snapshot.nameText;
        _amountController.text = snapshot.amountText;
        _memoController.text = snapshot.memoText;
        _ratioController.text = snapshot.ratioText;
        _targetAmountController.text = snapshot.targetAmountText;
        _costBasisController.text = snapshot.costBasisText;
        _expectedAnnualRateController.text = snapshot.expectedAnnualRateText;
        _tickerController.text = snapshot.tickerText;
        _institutionController.text = snapshot.institutionText;
        _currencyController.text = snapshot.currencyText;
        _unitsController.text = snapshot.unitsText;
        _unitPriceController.text = snapshot.unitPriceText;
        _appraisalValueController.text = snapshot.appraisalValueText;
        _monthlyIncomeController.text = snapshot.monthlyIncomeText;
        _debtAmountController.text = snapshot.debtAmountText;
        _alertThresholdController.text = snapshot.alertThresholdText;
        _assetDate = snapshot.assetDate;
        _maturityDate = snapshot.maturityDate;
        _selectedCategory = snapshot.selectedCategory;
        _isInvestment = snapshot.isInvestment;
        _riskLevel = snapshot.riskLevel;
      });
    }
  }

  Widget _buildOriginalCard(ThemeData theme) {
    final initialAsset = widget.initialAsset!;
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '원본',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(initialAsset.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${initialAsset.category.label} · '
              '${DateFormats.yMd.format(initialAsset.date)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(initialAsset.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (initialAsset.targetRatio != null ||
                initialAsset.targetAmount != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (initialAsset.targetRatio != null)
                      Text(_targetRatioLabel(initialAsset.targetRatio!)),
                    if (initialAsset.targetAmount != null)
                      Text(_targetAmountLabel(initialAsset.targetAmount!)),
                  ],
                ),
              ),
            if (initialAsset.memo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(initialAsset.memo),
              ),
          ],
        ),
      ),
    );
  }

  String _targetRatioLabel(double ratio) {
    return '목표 비율: ${ratio.toStringAsFixed(1)}%';
  }

  String _targetAmountLabel(num amount) {
    return '목표액: ${CurrencyFormatter.format(amount)}';
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
