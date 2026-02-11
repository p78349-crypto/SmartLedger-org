part of 'asset_move_dialog.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _FormExt on _AssetMoveDialogState {
  Widget _buildFormContent(
    ThemeData theme,
    String formattedBalance,
    List<Asset> otherAssets,
  ) {
    return Column(
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  const DropdownMenuItem(child: Text('선택안함')),
                  ...otherAssets.map((asset) {
                    final assetLabel =
                        '${asset.name} (${asset.category.label})';
                    return DropdownMenuItem(
                      value: asset.id,
                      child: Text(assetLabel),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedToAssetId = value;
                    _selectedToCategory = null;
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
              _selectedToAssetId = null;
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
              borderSide: BorderSide(color: Colors.red.shade300),
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
    );
  }
}
