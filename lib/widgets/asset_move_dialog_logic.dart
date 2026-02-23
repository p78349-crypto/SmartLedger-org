import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/snackbar_utils.dart';

/// From/To 카테고리 기반 이동 타입 자동 결정
AssetMoveType determineAssetMoveType({
  required AssetCategory fromCategory,
  required AssetCategory? toCategory,
}) {
  if (toCategory == null) return AssetMoveType.transfer;

  final isCash = fromCategory == AssetCategory.cash;
  final isCashTo = toCategory == AssetCategory.cash;
  final isSameCategory = fromCategory == toCategory;

  if (isCash && toCategory == AssetCategory.deposit) {
    return AssetMoveType.deposit;
  }
  if (isCash && !isCashTo) {
    return AssetMoveType.purchase;
  }
  if (!isCash && isCashTo) {
    return AssetMoveType.sale;
  }
  if (isSameCategory && !isCash) {
    return AssetMoveType.exchange;
  }
  return AssetMoveType.transfer;
}

/// 자산 이동 실행 로직
Future<bool> executeAssetMove({
  required BuildContext context,
  required String accountName,
  required Asset fromAsset,
  required String amountText,
  required String memo,
  required String? selectedToAssetId,
  required AssetCategory? selectedToCategory,
  required AssetMoveType selectedType,
  required DateTime moveDate,
}) async {
  final amount = CurrencyFormatter.parse(amountText);
  if (amount == null || amount <= 0) {
    SnackbarUtils.showError(context, '유효한 금액을 입력하세요');
    return false;
  }

  if (amount > fromAsset.amount) {
    final formatted =
        CurrencyFormatter.format(fromAsset.amount);
    SnackbarUtils.showError(
      context,
      '잔액 부족 (보유: $formatted)',
    );
    return false;
  }

  if (memo.isEmpty) {
    SnackbarUtils.showError(
      context,
      '메모는 필수입니다 (판단 사유를 입력해주세요)',
    );
    return false;
  }
  if (memo.length < 5) {
    SnackbarUtils.showError(
      context,
      '메모는 최소 5자 이상 입력하세요 (판단 사유를 명확히)',
    );
    return false;
  }

  if (selectedToAssetId == null &&
      selectedToCategory == null) {
    SnackbarUtils.showError(context, '이동 대상을 선택하세요');
    return false;
  }

  try {
    final assetService = AssetService();
    final assetMoveService = AssetMoveService();
    await assetService.loadAssets();

    // 1. From 자산 감소
    final fromBeforeAmount = fromAsset.amount;
    final fromBeforeCostBasis = fromAsset.costBasis;
    final ratio = fromBeforeAmount > 0
        ? (amount / fromBeforeAmount)
        : 0.0;
    final transferredCostBasis =
        (fromBeforeCostBasis != null && ratio > 0)
            ? (fromBeforeCostBasis * ratio)
            : 0.0;
    final nextFromCostBasis = (fromBeforeCostBasis != null)
        ? (fromBeforeCostBasis - transferredCostBasis)
            .clamp(0.0, double.infinity)
        : null;

    final updatedFrom = fromAsset.copyWith(
      amount: fromBeforeAmount - amount,
      costBasis: nextFromCostBasis,
    );
    await assetService.updateAsset(accountName, updatedFrom);

    String? toAssetId;

    // 2. To 자산 생성 또는 증가
    if (selectedToCategory != null) {
      final moveDateLabel =
          '${moveDate.year}-'
          "${moveDate.month.toString().padLeft(2, '0')}-"
          "${moveDate.day.toString().padLeft(2, '0')}";
      final newAsset = Asset(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        name:
            '${selectedToCategory.label} ($moveDateLabel)',
        amount: amount,
        category: selectedToCategory,
        date: moveDate,
        memo: memo,
        costBasis:
            selectedToCategory == AssetCategory.cash
                ? null
                : (transferredCostBasis > 0
                    ? transferredCostBasis
                    : amount),
      );
      await assetService.addAsset(accountName, newAsset);
      toAssetId = newAsset.id;
    } else if (selectedToAssetId != null) {
      final assets = assetService.getAssets(accountName);
      final toAsset = assets.firstWhere(
        (a) => a.id == selectedToAssetId,
      );
      final addedCostBasis =
          toAsset.category == AssetCategory.cash
              ? 0.0
              : (fromAsset.category == AssetCategory.cash
                    ? amount
                    : (transferredCostBasis > 0
                        ? transferredCostBasis
                        : amount));
      final newCostBasis =
          (toAsset.costBasis ?? 0) + addedCostBasis;
      final updatedTo = toAsset.copyWith(
        amount: toAsset.amount + amount,
        costBasis: (toAsset.category == AssetCategory.cash &&
                toAsset.costBasis == null)
            ? null
            : newCostBasis,
      );
      await assetService.updateAsset(
        accountName,
        updatedTo,
      );
      toAssetId = toAsset.id;
    }

    // 3. 이동 기록 저장
    final move = AssetMove(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      accountName: accountName,
      fromAssetId: fromAsset.id,
      toAssetId: selectedToAssetId ?? toAssetId,
      toCategoryName: selectedToCategory?.name,
      amount: amount,
      type: selectedType,
      memo: memo,
      date: moveDate,
    );
    await assetMoveService.addMove(accountName, move);

    if (!context.mounted) return true;
    SnackbarUtils.showSuccess(
      context,
      '${CurrencyFormatter.format(amount)}이(가) 이동되었습니다',
    );
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    SnackbarUtils.showError(context, '이동 실패: $e');
    return false;
  }
}
