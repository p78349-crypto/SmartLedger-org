part of income_split_service;

Future<void> _createAssetMovesForIncomeDistribution({
  required String accountName,
  required List<IncomeItem> incomeItems,
  required double savingsAmount,
  required double budgetAmount,
  required double emergencyAmount,
  required double assetTransferAmount,
}) async {
  final assetService = AssetService();
  final assetMoveService = AssetMoveService();
  await assetService.loadAssets();
  await assetMoveService.loadMoves();

  final incomeNames = incomeItems.map((i) => i.name).join(', ');

  final now = DateTime.now();
  final dateLabel = '[${DateFormatter.formatDate(now)}]';
  var assets = assetService.getAssets(accountName);

  // 현금 자산 확보 (없으면 생성)
  Asset? cashAsset;
  final cashList = assets
      .where((a) => a.category == AssetCategory.cash)
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
    await assetService.addAsset(accountName, actualCashAsset);
    assets = assetService.getAssets(accountName);
  }

  // 1. 저축 자산으로 이동
  if (savingsAmount > 0) {
    final Asset savingsAsset = assets.firstWhere(
      (a) =>
          a.category == AssetCategory.deposit &&
          a.name.contains('저축'),
      orElse: () => Asset(
        id: '${now.microsecondsSinceEpoch}_savings',
        name: '$dateLabel 저축',
        amount: 0,
        category: AssetCategory.deposit,
        memo: '수입 분배: 저축',
        date: now,
      ),
    );

    if (!assets.contains(savingsAsset)) {
      await assetService.addAsset(accountName, savingsAsset);
      assets = assetService.getAssets(accountName);
    }

    final move = AssetMove(
      id: '${now.microsecondsSinceEpoch}_savings_move',
      accountName: accountName,
      fromAssetId: actualCashAsset.id,
      toAssetId: savingsAsset.id,
      amount: savingsAmount,
      type: AssetMoveType.deposit,
      memo: '수입 분배: 저축 ($incomeNames)',
      date: now,
      createdAt: now,
    );
    await assetMoveService.addMove(accountName, move);
  }

  // 2. 예산 자산으로 이동
  if (budgetAmount > 0) {
    final Asset budgetAsset = assets.firstWhere(
      (a) =>
          a.category == AssetCategory.cash &&
          a.name.contains('예산'),
      orElse: () => Asset(
        id: '${now.microsecondsSinceEpoch}_budget',
        name: '$dateLabel 예산',
        amount: 0,
        category: AssetCategory.cash,
        memo: '수입 분배: 지출 예산',
        date: now,
      ),
    );

    if (!assets.contains(budgetAsset)) {
      await assetService.addAsset(accountName, budgetAsset);
      assets = assetService.getAssets(accountName);
    }

    final move = AssetMove(
      id: '${now.microsecondsSinceEpoch}_budget_move',
      accountName: accountName,
      fromAssetId: actualCashAsset.id,
      toAssetId: budgetAsset.id,
      amount: budgetAmount,
      memo: '수입 분배: 지출 예산 ($incomeNames)',
      date: now,
      createdAt: now,
    );
    await assetMoveService.addMove(accountName, move);
  }

  // 3. 비상금 자산으로 이동
  if (emergencyAmount > 0) {
    final Asset emergencyAsset = assets.firstWhere(
      (a) =>
          a.category == AssetCategory.deposit &&
          a.name.contains('비상금'),
      orElse: () => Asset(
        id: '${now.microsecondsSinceEpoch}_emergency',
        name: '$dateLabel 비상금',
        amount: 0,
        category: AssetCategory.deposit,
        memo: '수입 분배: 비상금',
        date: now,
      ),
    );

    if (!assets.contains(emergencyAsset)) {
      await assetService.addAsset(accountName, emergencyAsset);
      assets = assetService.getAssets(accountName);
    }

    final move = AssetMove(
      id: '${now.microsecondsSinceEpoch}_emergency_move',
      accountName: accountName,
      fromAssetId: actualCashAsset.id,
      toAssetId: emergencyAsset.id,
      amount: emergencyAmount,
      type: AssetMoveType.deposit,
      memo: '수입 분배: 비상금 ($incomeNames)',
      date: now,
      createdAt: now,
    );
    await assetMoveService.addMove(accountName, move);
  }

  // 4. 투자 자산으로 이동 (현금→주식)
  if (assetTransferAmount > 0) {
    final Asset investmentAsset = assets.firstWhere(
      (a) => a.category == AssetCategory.stock,
      orElse: () => Asset(
        id: '${now.microsecondsSinceEpoch}_investment',
        name: '$dateLabel 투자',
        amount: 0,
        category: AssetCategory.stock,
        memo: '수입 분배: 투자',
        date: now,
      ),
    );

    if (!assets.contains(investmentAsset)) {
      await assetService.addAsset(accountName, investmentAsset);
      assets = assetService.getAssets(accountName);
    }

    final move = AssetMove(
      id: '${now.microsecondsSinceEpoch}_investment_move',
      accountName: accountName,
      fromAssetId: actualCashAsset.id,
      toAssetId: investmentAsset.id,
      amount: assetTransferAmount,
      type: AssetMoveType.purchase,
      memo: '수입 분배: 투자 ($incomeNames)',
      date: now,
      createdAt: now,
    );
    await assetMoveService.addMove(accountName, move);
  }
}
