import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/snackbar_utils.dart';

part 'asset_move_dialog_form.dart';

/// 자산 이동/전환 다이얼로그
class AssetMoveDialog extends StatefulWidget {
  final String accountName;
  final Asset fromAsset;

  const AssetMoveDialog({
    super.key,
    required this.accountName,
    required this.fromAsset,
  });

  @override
  State<AssetMoveDialog> createState() => _AssetMoveDialogState();
}

class _AssetMoveDialogState extends State<AssetMoveDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  late DateTime _moveDate;
  String? _selectedToAssetId;
  AssetCategory? _selectedToCategory;
  late AssetMoveType _selectedType;

  @override
  void initState() {
    super.initState();
    _moveDate = DateTime.now();
    _selectedType = AssetMoveType.transfer;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// To 자산과 From 자산의 카테고리를 기반으로 이동 타입 자동 결정
  AssetMoveType _determineAssetMoveType({
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

  Future<void> _submit() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      SnackbarUtils.showError(context, '금액을 입력하세요');
      return;
    }

    final amount = CurrencyFormatter.parse(amountStr);
    if (amount == null || amount <= 0) {
      SnackbarUtils.showError(context, '유효한 금액을 입력하세요');
      return;
    }

    if (amount > widget.fromAsset.amount) {
      final formattedBalance = CurrencyFormatter.format(
        widget.fromAsset.amount,
      );
      SnackbarUtils.showError(context, '잔액 부족 (보유: $formattedBalance)');
      return;
    }

    final memo = _memoController.text.trim();
    if (memo.isEmpty) {
      SnackbarUtils.showError(context, '메모는 필수입니다 (판단 사유를 입력해주세요)');
      return;
    }
    if (memo.length < 5) {
      SnackbarUtils.showError(context, '메모는 최소 5자 이상 입력하세요 (판단 사유를 명확히)');
      return;
    }

    if (_selectedToAssetId == null && _selectedToCategory == null) {
      SnackbarUtils.showError(context, '이동 대상을 선택하세요');
      return;
    }

    try {
      final assetService = AssetService();
      final assetMoveService = AssetMoveService();

      await assetService.loadAssets();

      final fromBeforeAmount = widget.fromAsset.amount;
      final fromBeforeCostBasis = widget.fromAsset.costBasis;
      final ratio = fromBeforeAmount > 0 ? (amount / fromBeforeAmount) : 0.0;
      final transferredCostBasis = (fromBeforeCostBasis != null && ratio > 0)
          ? (fromBeforeCostBasis * ratio)
          : 0.0;
      final nextFromCostBasis = (fromBeforeCostBasis != null)
          ? (fromBeforeCostBasis - transferredCostBasis).clamp(
              0.0,
              double.infinity,
            )
          : null;

      final updatedFrom = widget.fromAsset.copyWith(
        amount: fromBeforeAmount - amount,
        costBasis: nextFromCostBasis,
      );
      await assetService.updateAsset(widget.accountName, updatedFrom);

      String? toAssetId;

      if (_selectedToCategory != null) {
        final moveDateLabel =
            '${_moveDate.year}-'
            "${_moveDate.month.toString().padLeft(2, '0')}-"
            "${_moveDate.day.toString().padLeft(2, '0')}";
        final newAsset = Asset(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: '${_selectedToCategory!.label} ($moveDateLabel)',
          amount: amount,
          category: _selectedToCategory!,
          date: _moveDate,
          memo: _memoController.text.trim(),
          costBasis: _selectedToCategory == AssetCategory.cash
              ? null
              : (transferredCostBasis > 0 ? transferredCostBasis : amount),
        );
        await assetService.addAsset(widget.accountName, newAsset);
        toAssetId = newAsset.id;
      } else if (_selectedToAssetId != null) {
        final assets = assetService.getAssets(widget.accountName);
        final toAsset = assets.firstWhere((a) => a.id == _selectedToAssetId);
        final addedCostBasis = toAsset.category == AssetCategory.cash
            ? 0.0
            : (widget.fromAsset.category == AssetCategory.cash
                  ? amount
                  : (transferredCostBasis > 0 ? transferredCostBasis : amount));
        final newCostBasis = (toAsset.costBasis ?? 0) + addedCostBasis;
        final updatedTo = toAsset.copyWith(
          amount: toAsset.amount + amount,
          costBasis:
              (toAsset.category == AssetCategory.cash &&
                  toAsset.costBasis == null)
              ? null
              : newCostBasis,
        );
        await assetService.updateAsset(widget.accountName, updatedTo);
        toAssetId = toAsset.id;
      }

      final move = AssetMove(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        accountName: widget.accountName,
        fromAssetId: widget.fromAsset.id,
        toAssetId: _selectedToAssetId ?? toAssetId,
        toCategoryName: _selectedToCategory?.name,
        amount: amount,
        type: _selectedType,
        memo: _memoController.text.trim(),
        date: _moveDate,
      );
      await assetMoveService.addMove(widget.accountName, move);

      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        '${CurrencyFormatter.format(amount)}이(가) 이동되었습니다',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '이동 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: AssetService().loadAssets(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final formattedBalance = CurrencyFormatter.format(
          widget.fromAsset.amount,
        );
        final assetService = AssetService();
        final otherAssets = assetService
            .getAssets(widget.accountName)
            .where((a) => a.id != widget.fromAsset.id)
            .toList();

        return Dialog(
          child: snapshot.connectionState != ConnectionState.done
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: SizedBox(
                    height: 72,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildFormContent(
                      theme,
                      formattedBalance,
                      otherAssets,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
