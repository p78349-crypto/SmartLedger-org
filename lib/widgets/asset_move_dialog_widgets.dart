import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/icon_catalog.dart';

/// From 자산 정보 표시 카드
class AssetMoveFromCard extends StatelessWidget {
  final Asset fromAsset;
  final String formattedBalance;

  const AssetMoveFromCard({
    super.key,
    required this.fromAsset,
    required this.formattedBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fromAsset.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            fromAsset.category.label,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            '잔액: $formattedBalance',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// 이동 금액 입력 필드 (커서 자동 이동 지원)
class AssetMoveAmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;

  const AssetMoveAmountField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onEditingComplete,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      decoration: const InputDecoration(
        prefixIcon: Icon(IconCatalog.attachMoney),
        hintText: '0',
        border: OutlineInputBorder(),
      ),
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      inputFormatters: [CurrencyInputFormatter()],
    );
  }
}

/// 이동 타입 선택 칩
class AssetMoveTypeChips extends StatelessWidget {
  final AssetMoveType selectedType;
  final ValueChanged<AssetMoveType> onChanged;

  const AssetMoveTypeChips({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AssetMoveType.values.map((type) {
          final isSelected = selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(type.label),
              onSelected: (selected) {
                if (selected) onChanged(type);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 이동 메모 입력 필드 (필수, 커서 자동 이동 지원)
class AssetMoveMemoField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;

  const AssetMoveMemoField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onEditingComplete,
    this.textInputAction = TextInputAction.done,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모 (필수: 판단 사유 기록)',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            hintText:
                '예: 채권 이자 기대, 주가 상승 예상, 긴급 자금 필요 등',
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red.shade300,
              ),
            ),
          ),
          maxLines: 3,
          minLines: 2,
        ),
      ],
    );
  }
}

/// 날짜 선택 위젯
class AssetMoveDatePicker extends StatelessWidget {
  final DateTime moveDate;
  final ValueChanged<DateTime> onChanged;

  const AssetMoveDatePicker({
    super.key,
    required this.moveDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: moveDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '이동 날짜',
          border: OutlineInputBorder(),
        ),
        child: Text(
          moveDate.toString().split(' ')[0],
        ),
      ),
    );
  }
}
