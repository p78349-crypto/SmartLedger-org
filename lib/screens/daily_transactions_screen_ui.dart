// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: avoid_redundant_argument_values

part of 'daily_transactions_screen.dart';

/// 하단 액션 바 및 거래 리스트 아이템 빌더
extension DailyTransactionsUi on _DailyTransactionsScreenState {
  Widget buildBottomActionBar(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.transactionAddDetailed,
                      arguments: AccountArgs(
                        accountName: widget.accountName,
                      ),
                    );
                  },
                  // padding intentionally specified for visual balance
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.pink.shade200,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '개수 입력',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.shoppingPointsInput,
                      arguments: ShoppingPointsInputArgs(
                        accountName: widget.accountName,
                      ),
                    );
                  },
                  // padding intentionally specified for visual balance
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.pink.shade200,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '포인트 입력',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.foodExpiry,
                      arguments: const FoodExpiryArgs(
                        openUpsertOnStart: true,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '식료품/생활용품 등록',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 세로 모드 거래 아이템
  Widget buildPortraitItem(ThemeData theme, Transaction tx) {
    final (txColor, prefix) = _txStyle(tx);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: txColor.withValues(alpha: 0.2),
        child: Icon(Icons.receipt_long, color: txColor),
      ),
      title: Text(
        tx.description,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: tx.memo.isNotEmpty ? Text(tx.memo) : null,
      trailing: Text(
        '$prefix${_numberFormat.format(tx.amount)}원',
        style: TextStyle(
          color: txColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () => showTransactionActionSheet(tx),
    );
  }

  /// 가로 모드 거래 아이템 (테이블 행)
  Widget buildLandscapeItem(ThemeData theme, Transaction tx) {
    final (txColor, prefix) = _txStyle(tx);
    final sub = tx.subCategory?.trim();
    final categoryText = (sub == null || sub.isEmpty)
        ? tx.mainCategory
        : '${tx.mainCategory} · $sub';

    final memoText =
        tx.memo.trim().isEmpty ? '-' : tx.memo.trim();

    final cardCharged = tx.cardChargedAmount;
    final cardText = cardCharged == null
        ? '-'
        : '${_numberFormat.format(cardCharged)}원';
    final baseAbs = tx.amount.abs();
    final hasMismatch =
        cardCharged != null && (cardCharged - baseAbs).abs() >= 1;

    final discountAmount =
        (cardCharged != null &&
            tx.type == TransactionType.expense &&
            cardCharged < baseAbs)
        ? (baseAbs - cardCharged)
        : null;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      title: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              tx.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              categoryText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              tx.paymentMethod,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              memoText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$prefix${_numberFormat.format(tx.amount)}원',
            style: TextStyle(
              color: txColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cardText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasMismatch
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: hasMismatch ? FontWeight.w600 : null,
                ),
              ),
              if (discountAmount != null)
                Text(
                  _formatDiscountLabel(discountAmount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: () => showTransactionActionSheet(tx),
    );
  }

  /// 거래 타입별 색상/접두사
  (Color, String) _txStyle(Transaction tx) {
    switch (tx.type) {
      case TransactionType.income:
        return (AppColors.income, '+');
      case TransactionType.expense:
        return (AppColors.expense, '-');
      case TransactionType.savings:
        return (AppColors.savings, '⊕');
      case TransactionType.refund:
        return (RefundUtils.color, '⊕');
    }
  }
}
