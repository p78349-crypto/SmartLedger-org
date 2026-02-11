part of 'asset_detail_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension AssetDetailTimeline on _AssetDetailScreenState {
  Widget _buildMoveTimeline(
    BuildContext context,
    AssetMove move,
    bool isOutgoing,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final assetService = AssetService();
    final assets = assetService.getAssets(widget.accountName);
    final moveTimestamp = _formatTimestamp(move.date);

    String? targetAssetName;
    if (isOutgoing) {
      if (move.toAssetId != null) {
        try {
          targetAssetName = assets
              .firstWhere((asset) => asset.id == move.toAssetId)
              .name;
        } catch (e) {
          debugPrint('Asset lookup failed for toAssetId: $e');
        }
      }
      targetAssetName ??= move.toCategoryName ?? '알 수 없음';
    } else {
      try {
        targetAssetName = assets
            .firstWhere((asset) => asset.id == move.fromAssetId)
            .name;
      } catch (e) {
        debugPrint('Asset lookup failed for fromAssetId: $e');
      }
      targetAssetName ??= move.toCategoryName ?? '알 수 없음';
    }

    final directionLabel = isOutgoing ? '→' : '←';
    final amountColor = isOutgoing ? theme.colorScheme.error : Colors.green;
    final amountSign = isOutgoing ? '-' : '+';
    final moveAmountLabel = _formatAmountWithUnit(move.amount);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타임라인 라인
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: amountColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          moveTimestamp,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: amountColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            move.type.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.asset.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' $directionLabel ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            targetAssetName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$amountSign$moveAmountLabel',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    if (move.memo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          move.memo,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }

  String _formatAmountWithUnit(num value) =>
      CurrencyFormatter.format(value);

  String _formatTimestamp(DateTime date) =>
      DateFormatter.dateTime.format(date);

  /// 자산 최초 생성 항목 표시
  Widget _buildInitialAssetTimeline(BuildContext context, ThemeData theme) {
    final creationTimestamp = _formatTimestamp(_currentAsset.date);
    final assetLabel =
        '${_currentAsset.category.emoji} ${_currentAsset.name} 생성';
    final initialAmountLabel = _formatAmountWithUnit(_currentAsset.amount);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      creationTimestamp,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '최초 보유',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  assetLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '+$initialAmountLabel',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (_currentAsset.memo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _currentAsset.memo,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
