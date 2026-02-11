part of 'input_stats_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InputStatsScreenBuild on _InputStatsScreenState {
  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('입력 통계(1달)'),
        actions: [
          IconButton(
            tooltip: '마트/쇼핑몰명 병합/정리',
            icon: const Icon(IconCatalog.compareArrows),
            onPressed: () async {
              await Navigator.of(context).pushNamed(
                AppRoutes.storeMerge,
                arguments: AccountArgs(accountName: widget.accountName),
              );
              if (!mounted) return;
              await _load();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final memoThisMonth =
        _memoThisMonth ??
        const MemoStatsResult(
          totalMemoAmount: 0,
          memoTransactionCount: 0,
          top10: <MemoStatEntry>[],
          topCategoryInsight: null,
        );

    final memoLookback =
        _memoLookback ??
        const MemoStatsResult(
          totalMemoAmount: 0,
          memoTransactionCount: 0,
          top10: <MemoStatEntry>[],
          topCategoryInsight: null,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('메모', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이번달 메모 지출', style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  _formatWon(memoThisMonth.totalMemoAmount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '(1달) · ${memoThisMonth.memoTransactionCount}건',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '최근 6개월: ${_formatWon(memoLookback.totalMemoAmount)}'
                  ' · ${memoLookback.memoTransactionCount}건',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('간편 지출(1줄)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildQuickInputSummary(theme),
        const SizedBox(height: 20),
        Text('혜택(제시-실결제)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildStoreBenefitStats(theme),
        const SizedBox(height: 12),
        _buildBenefitTypeStats(theme),
        const SizedBox(height: 12),
        _buildBenefitTypeByStoreStats(theme),
        const SizedBox(height: 20),
        Text('상세 카테고리(3단계) 상위', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildCategory3TierStats(theme),
        const SizedBox(height: 20),
        Text('마트/쇼핑몰별 제품', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildStoreProductStats(theme),
      ],
    );
  }
}
