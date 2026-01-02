import 'package:flutter/material.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/asset_move.dart';
import 'package:smart_ledger/services/asset_move_service.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/currency_input_formatter.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';

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
  String? _selectedToAssetId; // 기존 자산 선택
  AssetCategory? _selectedToCategory; // 새로 생성할 자산 카테고리
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
    // toCategory == null이면 새로 생성 케이스
    if (toCategory == null) return AssetMoveType.transfer;

    final isCash = fromCategory == AssetCategory.cash;
    final isCashTo = toCategory == AssetCategory.cash;
    final isSameCategory = fromCategory == toCategory;

    // 현금 관련 이동
    if (isCash && toCategory == AssetCategory.deposit) {
      return AssetMoveType.deposit; // 현금 → 예금/적금
    }
    if (isCash && !isCashTo) {
      return AssetMoveType.purchase; // 현금 → 주식/채권/부동산
    }
    if (!isCash && isCashTo) {
      return AssetMoveType.sale; // 주식/채권/부동산 → 현금
    }

    // 같은 카테고리 간 교환 (주식 ↔ 주식, 채권 ↔ 채권 등)
    if (isSameCategory && !isCash) {
      return AssetMoveType.exchange; // 교환
    }

    // 그 외 자산 간 이동
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

    // 메모 필수 입력 검증
    final memo = _memoController.text.trim();
    if (memo.isEmpty) {
      SnackbarUtils.showError(context, '메모는 필수입니다 (판단 사유를 기록해주세요)');
      return;
    }
    if (memo.length < 5) {
      SnackbarUtils.showError(context, '메모는 최소 5자 이상 입력하세요 (판단 사유를 명확히)');
      return;
    }

    // To 자산/카테고리 중 하나는 반드시 선택되어야 함
    if (_selectedToAssetId == null && _selectedToCategory == null) {
      SnackbarUtils.showError(context, '이동 대상을 선택하세요');
      return;
    }

    try {
      final assetService = AssetService();
      final assetMoveService = AssetMoveService();

      // Ensure we have up-to-date assets for lookups.
      await assetService.loadAssets();

      // 1. From 자산 감소 (+ costBasis proportionally reduced when present)
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

      // 2. To 자산 생성 또는 증가
      if (_selectedToCategory != null) {
        // 카테고리 선택: 신규 자산 생성
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
        // 기존 자산 선택: 기존 자산 증가
        final assets = assetService.getAssets(widget.accountName);
        final toAsset = assets.firstWhere((a) => a.id == _selectedToAssetId);
        // Cost basis handling:
        // - Cash doesn't accumulate cost basis
        // - When moving from non-cash to non-cash,
        //   carry proportional cost basis
        // - When moving from cash to non-cash, add the invested amount
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

      // 3. 이동 기록 저장
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('자산 이동', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),

                        // From 자산 (읽기 전용)
                        Text('From', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.fromAsset.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.fromAsset.category.label,
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                '잔액: $formattedBalance',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 이동 금액
                        Text('이동 금액', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(IconCatalog.attachMoney),
                            hintText: '0',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [CurrencyInputFormatter()],
                        ),
                        const SizedBox(height: 16),

                        // To 자산 선택: 기존 자산과 카테고리 선택지 통합
                        Text('To (이동 대상)', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),

                        // 기존 자산 선택
                        if (otherAssets.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _selectedToAssetId,
                                decoration: const InputDecoration(
                                  labelText: '기존 자산 선택',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('선택안함'),
                                  ),
                                  ...otherAssets.map((asset) {
                                    final assetLabel =
                                        '${asset.name} ('
                                        '${asset.category.label})';
                                    return DropdownMenuItem(
                                      value: asset.id,
                                      child: Text(assetLabel),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedToAssetId = value;
                                    _selectedToCategory =
                                        null; // 기존 자산 선택 시 카테고리 초기화
                                    if (value != null) {
                                      final toAsset = otherAssets.firstWhere(
                                        (a) => a.id == value,
                                      );
                                      _selectedType = _determineAssetMoveType(
                                        fromCategory: widget.fromAsset.category,
                                        toCategory: toAsset.category,
                                      );
                                    }
                                  });
                                },
                                isExpanded: true,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),

                        // 카테고리 선택 (새로 생성)
                        DropdownButtonFormField<AssetCategory>(
                          initialValue: _selectedToCategory,
                          decoration: const InputDecoration(
                            labelText: '또는 새 자산 생성 (카테고리 선택)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('선택안함'),
                            ),
                            ...AssetCategory.values.map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text('${cat.emoji} ${cat.label}'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedToCategory = value;
                              _selectedToAssetId = null; // 카테고리 선택 시 자산 초기화
                              if (value != null) {
                                _selectedType = _determineAssetMoveType(
                                  fromCategory: widget.fromAsset.category,
                                  toCategory: value,
                                );
                              }
                            });
                          },
                          isExpanded: true,
                        ),
                        const SizedBox(height: 16),

                        // 이동 타입 (자동 결정, 사용자 변경 가능)
                        Text(
                          '이동 타입 (자동 선택, 변경 가능)',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: AssetMoveType.values.map((type) {
                              final isSelected = _selectedType == type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Text(type.label),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedType = type);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 메모 (필수)
                        Text(
                          '메모 (필수: 판단 사유 기록)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _memoController,
                          decoration: InputDecoration(
                            hintText: '예: 채권 이자 기대, 주가 상승 예상, 긴급 자금 필요 등',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                              ),
                            ),
                          ),
                          maxLines: 3,
                          minLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // 날짜
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _moveDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _moveDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '이동 날짜',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_moveDate.toString().split(' ')[0]),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('취소'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _submit,
                              child: const Text('이동 확인'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

