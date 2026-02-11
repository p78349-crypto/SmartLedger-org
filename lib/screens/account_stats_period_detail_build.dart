// ignore_for_file: invalid_use_of_protected_member
part of 'account_stats_period_detail_screen.dart';

/// 기간 상세 화면 빌드 헬퍼.
extension AccountStatsPeriodDetailBuild
    on _AccountStatsPeriodDetailScreenState {
  Widget _buildSearchAndNav(
    ThemeData theme,
    DateTimeRange range,
    String referenceLabel,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '거래 검색 (내용/메모/결제수단)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              _query = value;
              _searchDebouncer.run(() {
                if (!mounted) return;
                setState(() {});
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _goPrev,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _rangeLabel(range),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      referenceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _goNext,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(
    ThemeData theme,
    List<Transaction> filtered,
    bool isLandscape,
  ) {
    if (isLandscape) {
      return _buildLandscapeList(theme, filtered);
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final tx = filtered[index];
        return ListTile(
          leading: Icon(
            statsIconForType(tx.type),
            color: statsColorForType(tx.type, theme),
          ),
          title: Text(tx.description),
          subtitle: Text(
            '${_dateFormat.format(tx.date)} · ${tx.memo}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Text(_formatSignedAmount(tx)),
        );
      },
    );
  }

  Widget _buildLandscapeList(ThemeData theme, List<Transaction> filtered) {
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  '내용',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerStyle,
                ),
              ),
              Expanded(
                flex: 7,
                child: Text(
                  '날짜 · 메모',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerStyle,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '금액',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: headerStyle,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = filtered[index];
              final color = statsColorForType(tx.type, theme);
              final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(statsIconForType(tx.type), size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Text(
                        tx.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        '${_dateFormat.format(tx.date)} · ${tx.memo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatSignedAmount(tx),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
