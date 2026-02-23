import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../services/asset_service.dart';
import '../utils/currency_formatter.dart';
import 'asset_move_dialog_logic.dart';
import 'asset_move_dialog_widgets.dart';

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
  void _handleMemoEditingComplete() {
    FocusScope.of(context).unfocus();
  }

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  
  // 📱 커서 자동 이동을 위한 FocusNode 추가
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _memoFocusNode = FocusNode();
  
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
    
    // FocusNode 리소스 정리
    _amountFocusNode.dispose();
    _memoFocusNode.dispose();
    
    super.dispose();
  }

  AssetMoveType _autoMoveType(AssetCategory? toCat) {
    return determineAssetMoveType(
      fromCategory: widget.fromAsset.category,
      toCategory: toCat,
    );
  }

  Future<void> _submit() async {
    final success = await executeAssetMove(
      context: context,
      accountName: widget.accountName,
      fromAsset: widget.fromAsset,
      amountText: _amountController.text.trim(),
      memo: _memoController.text.trim(),
      selectedToAssetId: _selectedToAssetId,
      selectedToCategory: _selectedToCategory,
      selectedType: _selectedType,
      moveDate: _moveDate,
    );
    if (success && mounted) {
      Navigator.pop(context, true);
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
                        AssetMoveFromCard(
                          fromAsset: widget.fromAsset,
                          formattedBalance: formattedBalance,
                        ),
                        const SizedBox(height: 16),

                        // 이동 금액
                        Text('이동 금액', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        AssetMoveAmountField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          onEditingComplete: _memoFocusNode.requestFocus,
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
                                  const DropdownMenuItem(child: Text('선택안함')),
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
                                      _selectedType = _autoMoveType(
                                      toAsset.category,
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
                            const DropdownMenuItem(child: Text('선택안함')),
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
                              _selectedType = _autoMoveType(value);
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
                        AssetMoveTypeChips(
                          selectedType: _selectedType,
                          onChanged: (type) {
                            setState(() => _selectedType = type);
                          },
                        ),
                        const SizedBox(height: 16),

                        // 메모 (필수)
                        AssetMoveMemoField(
                          controller: _memoController,
                          focusNode: _memoFocusNode,
                          onEditingComplete: _handleMemoEditingComplete,
                        ),
                        const SizedBox(height: 16),

                        // 날짜
                        AssetMoveDatePicker(
                          moveDate: _moveDate,
                          onChanged: (picked) {
                            setState(() => _moveDate = picked);
                          },
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
