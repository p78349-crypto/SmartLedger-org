part of root_transaction_manager_screen;

extension _RootTransactionManagerScreenUi
    on _RootTransactionManagerScreenState {
  Widget _buildScaffold(BuildContext context) {
    final entries = _loading ? const <_RootTxEntry>[] : _buildEntries();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return RootAuthGate(
      child: Scaffold(
        appBar: AppBar(title: const Text('거래관리')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('불러오기 실패: $_error'),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('거래가 없습니다.')),
                )
              else if (isLandscape)
                _buildLandscapeHeader(context),
              if (isLandscape) const Divider(height: 1),
              ...entries.expand((entry) => _buildEntryWidgets(entry, isLandscape)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              '계정 · 내용',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              '날짜',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              '유형 · 결제',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '금액',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 88),
        ],
      ),
    );
  }

  List<Widget> _buildEntryWidgets(_RootTxEntry entry, bool isLandscape) {
    final tx = entry.tx;
    final sign = tx.sign;
    final amountText = '$sign${_currency.format(tx.amount.abs())}';
    final typeLabel = tx.type == TransactionType.savings
        ? (tx.savingsAllocation?.label ?? tx.type.label)
        : tx.type.label;
    final dateLabel = _date.format(tx.date);

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '수정',
          icon: const Icon(IconCatalog.editOutlined),
          onPressed: () => _edit(entry),
        ),
        IconButton(
          tooltip: '삭제',
          icon: const Icon(IconCatalog.deleteOutline),
          onPressed: () => _delete(entry),
        ),
      ],
    );

    if (!isLandscape) {
      return [
        ListTile(
          title: Text('${entry.accountName} · ${tx.description}'),
          subtitle: Text('$dateLabel · $typeLabel · ${tx.paymentMethod}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amountText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              actions,
            ],
          ),
          onTap: () => _edit(entry),
        ),
      ];
    }

    final title = '${entry.accountName} · ${tx.description}';
    final detail = '$typeLabel · ${tx.paymentMethod}';

    return [
      InkWell(
        onTap: () => _edit(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Text(
                  title,
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
                flex: 5,
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              actions,
            ],
          ),
        ),
      ),
      const Divider(height: 1),
    ];
  }
}

class _RootTxEntry {
  const _RootTxEntry({required this.accountName, required this.tx});

  final String accountName;
  final Transaction tx;
}
