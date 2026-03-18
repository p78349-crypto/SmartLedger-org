// ignore_for_file: invalid_use_of_protected_member

part of 'emergency_fund_list_screen.dart';

/// 비상금 리스트 UI 빌더 (세로/가로 모드)
extension EmergencyFundListUI on _EmergencyFundListScreenState {
  Widget buildPortraitList(List<EmergencyTransaction> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final tx = items[index];
        final isSelected = _selectedIds.contains(tx.id);
        final isDeposit = tx.amount >= 0;
        return ListTile(
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(tx.id),
                )
              : Icon(
                  isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isDeposit ? Colors.green : Colors.red,
                ),
          title: Text(tx.description),
          subtitle: Text(DateFormats.yMd.format(tx.date)),
          trailing: Text(
            CurrencyFormatter.formatSigned(tx.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDeposit ? Colors.green : Colors.red,
            ),
          ),
          onTap: _isSelectionMode ? () => _toggleSelection(tx.id) : null,
        );
      },
    );
  }

  Widget buildLandscapeList(List<EmergencyTransaction> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const Divider(),
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
                Expanded(flex: 7, child: Text('설명', style: headerStyle)),
                SizedBox(width: 12),
                Expanded(flex: 3, child: Text('날짜', style: headerStyle)),
                SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('금액', style: headerStyle),
                  ),
                ),
              ],
            ),
          );
        }

        final tx = items[index - 1];
        final isSelected = _selectedIds.contains(tx.id);
        final isDeposit = tx.amount >= 0;
        final dateLabel = DateFormats.yMd.format(tx.date);
        final amountLabel = CurrencyFormatter.formatSigned(tx.amount);
        final amountStyle = TextStyle(
          fontWeight: FontWeight.bold,
          color: isDeposit ? Colors.green : Colors.red,
        );

        return InkWell(
          onTap: _isSelectionMode ? () => _toggleSelection(tx.id) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(tx.id),
                        )
                      : Icon(
                          isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isDeposit ? Colors.green : Colors.red,
                        ),
                ),
                Expanded(
                  flex: 7,
                  child: Text(
                    tx.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      style: amountStyle,
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
}
