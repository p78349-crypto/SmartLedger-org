part of 'refund_transactions_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension RefundGroupedSearch on _RefundTransactionsScreenState {
  Widget buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SmartInputField(
        hint: '반품 검색 (날짜/상품명/메모/가격/구매자·거래처)',
        controller: _searchController,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.trim().isEmpty
            ? null
            : IconButton(
                tooltip: '지우기',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
        onChanged: (v) {
          _searchDebouncer.run(() {
            if (!mounted) return;
            setState(() {
              _searchQuery = v;
            });
          });
        },
      ),
    );
  }

  Widget buildGroupedByPayment(List<Transaction> txs, ThemeData theme) {
    if (txs.isEmpty) {
      return const SizedBox.shrink();
    }
    final grouped = <String, List<Transaction>>{};
    for (final tx in txs) {
      final key = tx.paymentMethod.trim().isEmpty
          ? '기타 결제'
          : tx.paymentMethod.trim();
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final sumA = a.value.fold<double>(0, (s, t) => s + t.amount);
        final sumB = b.value.fold<double>(0, (s, t) => s + t.amount);
        return sumB.compareTo(sumA);
      });

    return Column(
      children: entries.map((entry) {
        final total = entry.value.fold<double>(0, (s, t) => s + t.amount);
        final displayList = entry.value.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: theme.textTheme.titleMedium),
                    Text(
                      '⊕${_numberFormat.format(total)}원',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: RefundUtils.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...displayList
                    .take(5)
                    .map(
                      (tx) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          tx.description.trim().isEmpty
                              ? '(미입력)'
                              : tx.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd').format(tx.date),
                        ),
                        trailing: Text(
                          '⊕${_numberFormat.format(tx.amount)}원',
                          style: const TextStyle(color: RefundUtils.color),
                        ),
                        onTap: () => showTransactionActionSheet(tx),
                      ),
                    ),
                if (entry.value.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${entry.value.length - 5}건 더 보기',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
