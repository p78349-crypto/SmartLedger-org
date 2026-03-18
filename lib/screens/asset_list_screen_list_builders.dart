// ignore_for_file: invalid_use_of_protected_member
part of 'asset_list_screen.dart';

/// 자산 목록 리스트 빌더: 가로/세로 모드
extension AssetListScreenListBuilders on _AssetListScreenState {
  Widget _buildLandscapeList(List<Asset> filteredAssets) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filteredAssets.length + 1,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        if (index == 0) {
          const headerStyle = TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );

          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                SizedBox(width: 40),
                Expanded(
                  flex: 7,
                  child: Text(
                    '자산',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headerStyle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Text(
                    '손익',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headerStyle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '금액',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: headerStyle,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '타입',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: headerStyle,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final asset = filteredAssets[index - 1];
        final isSelected = _selectedIds.contains(asset.id);

        final profitLoss = ProfitLossCalculator.calculateProfitLoss(
          asset.amount,
          asset.costBasis,
        );
        final profitLossRate = ProfitLossCalculator.calculateProfitLossRate(
          asset.amount,
          asset.costBasis,
        );
        final profitLossColor = ProfitLossCalculator.getProfitLossColor(
          profitLoss,
        );
        final profitLossLabel = ProfitLossCalculator.formatProfitLoss(
          profitLoss,
        );
        final profitLossRateLabel = ProfitLossCalculator.formatProfitLossRate(
          profitLossRate,
        );

        final hasProfitLoss = asset.costBasis != null && asset.costBasis! > 0;
        final profitLossText = hasProfitLoss
            ? '$profitLossLabel ($profitLossRateLabel)'
            : '';

        final assetLabel = asset.memo.isNotEmpty
            ? '${asset.name} · ${asset.memo}'
            : asset.name;

        final amountLabel = '${_currencyFormat.format(asset.amount)}원';

        return InkWell(
          onTap: _isSelectionMode
              ? () => _toggleSelection(asset.id)
              : () => _showAssetActionSheet(asset),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(asset.id),
                        )
                      : null,
                ),
                Expanded(
                  flex: 7,
                  child: Text(
                    assetLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Text(
                    profitLossText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: profitLossColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _getAssetTypeLabel(asset),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitList(List<Asset> filteredAssets) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filteredAssets.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final asset = filteredAssets[index];
        final isSelected = _selectedIds.contains(asset.id);
        final profitLoss = ProfitLossCalculator.calculateProfitLoss(
          asset.amount,
          asset.costBasis,
        );
        final profitLossRate = ProfitLossCalculator.calculateProfitLossRate(
          asset.amount,
          asset.costBasis,
        );
        final profitLossColor = ProfitLossCalculator.getProfitLossColor(
          profitLoss,
        );
        final profitLossLabel = ProfitLossCalculator.formatProfitLoss(
          profitLoss,
        );
        final profitLossRateLabel = ProfitLossCalculator.formatProfitLossRate(
          profitLossRate,
        );

        return ListTile(
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(asset.id),
                )
              : null,
          title: Text(asset.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (asset.memo.isNotEmpty) Text(asset.memo),
              if (asset.costBasis != null && asset.costBasis! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '$profitLossLabel ($profitLossRateLabel)',
                    style: TextStyle(
                      color: profitLossColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_currencyFormat.format(asset.amount)}원',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                _getAssetTypeLabel(asset),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          onTap: _isSelectionMode
              ? () => _toggleSelection(asset.id)
              : () => _showAssetActionSheet(asset),
        );
      },
    );
  }
}
