part of 'asset_detail_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension AssetDetailFlow on _AssetDetailScreenState {
  /// 자산 이동 흐름 경로를 시각화 (개선된 버전)
  Widget _buildAssetFlowPath(BuildContext context, ThemeData theme) {
    final assetService = AssetService();
    final assetMoveService = AssetMoveService();

    // 모든 자산과 이동 기록 로드
    final allAssets = assetService.getAssets(widget.accountName);
    final allMoves = assetMoveService.getMoves(widget.accountName);

    // 이 자산과 관련된 이동만 필터링
    final relatedMoves = allMoves.where((move) {
      final isSource = move.fromAssetId == widget.asset.id;
      final isDestination = move.toAssetId == widget.asset.id;
      return isSource || isDestination;
    });
    final assetMoves = relatedMoves.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (assetMoves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '아직 이동 기록이 없습니다',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // 경로 데이터 구성
    final pathItems = <Map<String, dynamic>>[];

    // 시작 자산 추가
    pathItems.add({
      'emoji': widget.asset.category.emoji,
      'name': widget.asset.category.label,
      'isStart': true,
    });

    // 이동 기록 추가
    for (int i = 0; i < assetMoves.length; i++) {
      final move = assetMoves[i];

      pathItems.add({
        'emoji': _getMoveTypeEmoji(move.type),
        'name': move.type.label,
        'isMoveType': true,
        'date': move.date,
        'amount': CurrencyFormatter.format(move.amount),
        'dateLabel': DateFormatter.shortMonth.format(move.date),
      });

      if (move.fromAssetId == widget.asset.id) {
        if (move.toAssetId != null) {
          final toAsset = allAssets.firstWhere(
            (a) => a.id == move.toAssetId,
            orElse: () => widget.asset,
          );
          pathItems.add({
            'emoji': toAsset.category.emoji,
            'name': toAsset.category.label,
          });
        } else if (move.toCategoryName != null) {
          final toCategory = AssetCategory.values.firstWhere(
            (c) => c.name == move.toCategoryName,
            orElse: () => AssetCategory.other,
          );
          pathItems.add({'emoji': toCategory.emoji, 'name': toCategory.label});
        }
      } else {
        final fromAsset = allAssets.firstWhere(
          (a) => a.id == move.fromAssetId,
          orElse: () => widget.asset,
        );
        final alreadyIncluded = pathItems.any(
          (item) => item['emoji'] == fromAsset.category.emoji,
        );
        if (!alreadyIncluded) {
          pathItems.insert(pathItems.length - 1, {
            'emoji': fromAsset.category.emoji,
            'name': fromAsset.category.label,
          });
        }
      }
    }

    // 최대 15개까지만 표시
    final displayItems = pathItems.length > 15
        ? [
            ...pathItems.take(14),
            {'emoji': '...', 'name': '더보기', 'isMore': true},
          ]
        : pathItems;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < displayItems.length; i++) ...[
                  _buildPathNode(theme, displayItems[i]),
                  if (i < displayItems.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                theme, '총 이동', '${assetMoves.length}회', Icons.swap_horiz,
              ),
              _buildStatItem(
                theme, '이동 유형', _getUniqueMoveTypes(assetMoves), Icons.category,
              ),
              _buildStatItem(
                theme, '기간', _getMoveDateRange(assetMoves), Icons.calendar_today,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 경로 노드 빌드
  Widget _buildPathNode(ThemeData theme, Map<String, dynamic> item) {
    final isStart = item['isStart'] ?? false;
    final isMoveType = item['isMoveType'] ?? false;

    if (isMoveType) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['emoji'], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  item['name'],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (item['amount'] != null) ...[
            const SizedBox(height: 4),
            Text(
              item['amount'],
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
          if (item['dateLabel'] != null)
            Text(
              item['dateLabel'],
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isStart
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStart
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.secondary.withValues(alpha: 0.3),
          width: isStart ? 2 : 1,
        ),
        boxShadow: isStart
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item['emoji'], style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            item['name'],
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
