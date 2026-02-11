// ignore_for_file: invalid_use_of_protected_member
part of 'one_hundred_million_project_screen.dart';

extension _BodyExt on _OneHundredMillionProjectScreenState {
  Widget _buildProjectBody() {
    final theme = Theme.of(context);

    final safeNow = _assets
        .where(
          (a) =>
              a.category == AssetCategory.deposit ||
              a.category == AssetCategory.cash ||
              a.category == AssetCategory.bond,
        )
        .fold<double>(0, (s, a) => s + a.amount);

    final investNow = _assets
        .where(
          (a) =>
              a.category == AssetCategory.stock ||
              a.category == AssetCategory.crypto ||
              a.category == AssetCategory.realEstate ||
              a.category == AssetCategory.other,
        )
        .fold<double>(0, (s, a) => s + a.amount);

    final currentTotal = safeNow + investNow;

    double projectedAssetsFv = 0;
    for (final a in _assets) {
      final fallbackRate =
          (a.category == AssetCategory.deposit ||
                  a.category == AssetCategory.cash ||
                  a.category == AssetCategory.bond)
              ? _projectSafeRatePct
              : _projectInvestRatePct;
      final rate = a.expectedAnnualRatePct ?? fallbackRate;
      projectedAssetsFv += _fvLumpSum(
        presentValue: a.amount,
        annualRatePct: rate,
        years: _projectYears,
      );
    }

    final monthlyBenefit = _projectIncludeBenefits
        ? BenefitAggregationUtils.averageMonthlyBenefit(_txs)
        : 0.0;
    final benefitFv = _projectIncludeBenefits
        ? _fvMonthlyBenefitWithCashToInvestSwitch(
            monthly: monthlyBenefit,
            cashAnnualRatePct: _projectSafeRatePct,
            investAnnualRatePct: _projectInvestRatePct,
            years: _projectYears,
            cashToInvestThresholdAmount: _projectCashToInvestThresholdAmount,
          )
        : 0.0;

    final projectedTotal = projectedAssetsFv + benefitFv;
    final gapAt10y = (_projectTargetAmount - projectedTotal).clamp(
      double.negativeInfinity,
      double.infinity,
    );

    final extraMonthlyNeeded = _requiredMonthlyToReach(
      targetFutureValue: _projectTargetAmount,
      currentFutureValue: projectedTotal,
      annualRatePct: _projectSafeRatePct,
      years: _projectYears,
    );

    final currentLabel = CurrencyFormatter.format(currentTotal);
    final projectedLabel = CurrencyFormatter.format(projectedTotal);
    final targetLabel = CurrencyFormatter.format(_projectTargetAmount);
    final gapLabel = CurrencyFormatter.format(gapAt10y.abs());
    final extraMonthlyLabel = CurrencyFormatter.format(extraMonthlyNeeded);
    final monthlyBenefitLabel = CurrencyFormatter.format(monthlyBenefit);

    final achieved = gapAt10y <= 0;
    final gapText = achieved ? '목표 초과: $gapLabel' : '부족: $gapLabel';
    final gapColor =
        achieved ? theme.colorScheme.primary : theme.colorScheme.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            theme,
            targetLabel: targetLabel,
            currentLabel: currentLabel,
            projectedLabel: projectedLabel,
            gapText: gapText,
            gapColor: gapColor,
            achieved: achieved,
            extraMonthlyLabel: extraMonthlyLabel,
          ),
          const SizedBox(height: 24),
          Text(
            '상세 가정',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildAssumptionCard(
            theme,
            '안전자산 수익률',
            '${_projectSafeRatePct.toStringAsFixed(1)}% (연)',
            Icons.account_balance,
          ),
          const SizedBox(height: 8),
          _buildAssumptionCard(
            theme,
            '투자자산 수익률',
            '${_projectInvestRatePct.toStringAsFixed(1)}% (연)',
            Icons.trending_up,
          ),
          if (_projectIncludeBenefits) ...[
            const SizedBox(height: 8),
            _buildAssumptionCard(
              theme,
              '월평균 혜택/절약',
              monthlyBenefitLabel,
              Icons.redeem,
              subtitle: '최근 90일 기준 데이터를 기반으로 자동 계산됩니다.',
            ),
          ],
          const SizedBox(height: 32),
          _buildTipCard(theme),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme, {
    required String targetLabel,
    required String currentLabel,
    required String projectedLabel,
    required String gapText,
    required Color gapColor,
    required bool achieved,
    required String extraMonthlyLabel,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_projectYears년 후 미래 전망',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '목표: $targetLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(theme, '현재 자산', currentLabel),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              '예상 $_projectYears년 후',
              projectedLabel,
              isBold: true,
              valueColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              achieved ? '목표 달성 여부' : '목표까지',
              gapText,
              isBold: true,
              valueColor: gapColor,
            ),
            if (!achieved) ...[
              const Divider(height: 32),
              Text(
                '💡 제안',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '매달 $extraMonthlyLabel씩 추가로 저축하거나 투자하면 '
                '$_projectYears년 후 목표 금액에 도달할 수 있습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📌 팁',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '작은 할인이나 포인트 혜택도 비상금으로 모아두고, '
            '일정 금액이 모일 때마다 투자 자산으로 전환해 보세요. '
            '복리의 마법이 당신의 자산을 더 빠르게 성장시킬 것입니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
