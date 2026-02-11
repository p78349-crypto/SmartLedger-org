part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Income-asset allocation dialog and cash-asset helper.
extension TxDetailSaveAsset on _TransactionAddDetailedFormState {
  /// 수입 거래 저장 후 자산 할당 확인
  /// null: 취소, true: 분배하기, false: 현금 추가만
  Future<bool?> _showAssetAllocationDialog(Transaction transaction) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return AlertDialog(
          icon: Icon(IconCatalog.trendingUp, size: 48, color: scheme.primary),
          title: const Text('수입 분배'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.description} ('
                  '${transaction.amount.toStringAsFixed(0)}원)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '이 수입을 어떻게 처리할까요?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '옵션 1: 현금 자산에 추가 (권장)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                      const Text(
                        '급여가 현금으로 입금되어, 현금 자산의 잔액이 증가합니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '옵션 2: 지금 바로 분배하기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.tertiary,
                        ),
                      ),
                      const Text(
                        '저축, 예산, 비상금, 투자로 나누어 배분합니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('옵션 1: 현금 추가만'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(IconCatalog.accountBalanceWallet),
              label: const Text('옵션 2: 분배하기'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );
  }

  /// 현금 자산에 수입금 추가
  Future<void> _addToCashAsset(Transaction transaction) async {
    try {
      final assetService = AssetService();
      await assetService.loadAssets();

      var assets = assetService.getAssets(widget.accountName);
      final now = DateTime.now();

      Asset? cashAsset;
      final cashList = assets
          .where((a) => a.category == AssetCategory.cash && a.name == '현금')
          .toList();
      if (cashList.isNotEmpty) {
        cashAsset = cashList.first;
      }
      final Asset actualCashAsset =
          cashAsset ??
          Asset(
            id: '${now.microsecondsSinceEpoch}_cash',
            name: '현금',
            amount: 0,
            category: AssetCategory.cash,
            memo: '기본 현금 자산',
            date: now,
          );

      if (!assets.any((a) => a.id == actualCashAsset.id)) {
        await assetService.addAsset(widget.accountName, actualCashAsset);
        assets = assetService.getAssets(widget.accountName);
      }

      final updatedAsset = Asset(
        id: actualCashAsset.id,
        name: actualCashAsset.name,
        amount: actualCashAsset.amount + transaction.amount,
        category: actualCashAsset.category,
        memo: actualCashAsset.memo.isEmpty
            ? '${transaction.description} 입금'
            : '${actualCashAsset.memo}\n${transaction.description} 입금',
        date: actualCashAsset.date,
        inputType: actualCashAsset.inputType,
        targetRatio: actualCashAsset.targetRatio,
        targetAmount: actualCashAsset.targetAmount,
        isInvestment: actualCashAsset.isInvestment,
        conversionDate: actualCashAsset.conversionDate,
      );

      await assetService.updateAsset(widget.accountName, updatedAsset);

      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        '${transaction.amount.toStringAsFixed(0)}원이 현금 자산에 추가되었습니다',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showWarning(context, '자산 추가 중 오류: ${e.toString()}');
    }
  }
}
