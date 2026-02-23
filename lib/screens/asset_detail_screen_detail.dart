part of 'asset_detail_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension AssetDetailDetail on _AssetDetailScreenState {
  bool _hasExtraInfo() {
    return (_currentAsset.institution ?? '').isNotEmpty ||
        (_currentAsset.currencyCode ?? '').isNotEmpty ||
        (_currentAsset.ticker ?? '').isNotEmpty ||
        _currentAsset.units != null ||
        _currentAsset.unitPrice != null ||
        _currentAsset.appraisalValue != null ||
        _currentAsset.monthlyIncome != null ||
      _currentAsset.riskLevel != null ||
      _currentAsset.debtAmount != null ||
      _currentAsset.maturityDate != null;
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailScreen() {
    final theme = Theme.of(context);
    final assetMoveService = AssetMoveService();
    final rawMoves = assetMoveService.getMovesForAsset(
      widget.accountName,
      widget.asset.id,
    );
    final moves = rawMoves.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 최신순
    final currentAmountLabel = CurrencyFormatter.format(_currentAsset.amount);
    final categoryLabel =
        '${_currentAsset.category.emoji} ${_currentAsset.category.label}';
    final registrationDateLabel = DateFormatter.defaultDate.format(
      _currentAsset.date,
    );
    final costBasisLabel = _currentAsset.costBasis != null
        ? CurrencyFormatter.format(_currentAsset.costBasis!)
        : null;
    final expectedRateLabel = _currentAsset.expectedAnnualRatePct != null
        ? '${_currentAsset.expectedAnnualRatePct!.toStringAsFixed(2)}%'
        : null;
    final hasCostBasis = costBasisLabel != null;
    final hasExpectedRate = expectedRateLabel != null;
    final costBasisText = costBasisLabel ?? '';
    final expectedRateText = expectedRateLabel ?? '';
    final currencyText = _currentAsset.currencyCode ?? '';
    final tickerText = _currentAsset.ticker ?? '';
    final institutionText = _currentAsset.institution ?? '';
    final unitsText = _currentAsset.units != null
      ? _currentAsset.units!.toStringAsFixed(4)
      : '';
    final unitPriceText = _currentAsset.unitPrice != null
      ? CurrencyFormatter.format(_currentAsset.unitPrice!)
      : '';
    final appraisalText = _currentAsset.appraisalValue != null
      ? CurrencyFormatter.format(_currentAsset.appraisalValue!)
      : '';
    final monthlyIncomeText = _currentAsset.monthlyIncome != null
      ? CurrencyFormatter.format(_currentAsset.monthlyIncome!)
      : '';
    final riskText = _currentAsset.riskLevel?.label ?? '';
    final debtText = _currentAsset.debtAmount != null
      ? CurrencyFormatter.format(_currentAsset.debtAmount!)
      : '';
    final maturityText = _currentAsset.maturityDate != null
      ? DateFormatter.defaultDate.format(_currentAsset.maturityDate!)
      : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 잔액 카드
            Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('현재 잔액', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    currentAmountLabel,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  // ✅ 손익 정보 표시 (원가가 있는 경우만)
                  if (hasCostBasis) ...[
                    const SizedBox(height: 8),
                    _buildProfitLossDisplay(theme),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('카테고리', style: theme.textTheme.labelSmall),
                          Text(
                            categoryLabel,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('등록일', style: theme.textTheme.labelSmall),
                          Text(
                            registrationDateLabel,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // ✅ 원가 정보 표시
                  if (hasCostBasis) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '원가',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            costBasisText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hasExpectedRate) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '기대수익률(연)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            expectedRateText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_hasExtraInfo()) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(theme, '보관처', institutionText),
                    _buildInfoRow(theme, '통화', currencyText),
                    _buildInfoRow(theme, '종목/심볼', tickerText),
                    _buildInfoRow(theme, '보유 수량', unitsText),
                    _buildInfoRow(theme, '단가', unitPriceText),
                    _buildInfoRow(theme, '평가액', appraisalText),
                    _buildInfoRow(theme, '월 수익', monthlyIncomeText),
                    _buildInfoRow(theme, '리스크', riskText),
                    _buildInfoRow(theme, '부채', debtText),
                    _buildInfoRow(theme, '만기', maturityText),
                  ],
                  if (_currentAsset.memo.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
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
            // 자산 이동 흐름 경로 (전체 계정 관점)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '자산 평가',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssetEvaluationScreen(
                            accountName: widget.accountName,
                            asset: _currentAsset,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.insights_outlined),
                    label: const Text('평가 리포트 열기'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '자산 이동 흐름',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAssetFlowPath(context, theme),
                ],
              ),
            ),
            // 자산 변화 타임라인 (생성 시점부터)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '자산 변화 기록',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '총 ${moves.length + 1}건',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInitialAssetTimeline(context, theme),
                  if (moves.isNotEmpty) const SizedBox(height: 16),
                  if (moves.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '이후 이동 기록이 없습니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: moves.length,
                      itemBuilder: (context, index) {
                        final move = moves[index];
                        final isFromCurrent =
                            move.fromAssetId == widget.asset.id;
                        final isOutgoing = isFromCurrent;
                        final isLastMove = index == moves.length - 1;
                        return _buildMoveTimeline(
                          context, move, isOutgoing, isLastMove,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
