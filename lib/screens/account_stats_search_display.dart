part of 'account_stats_search_screen.dart';

/// 검색 결과 화면 표시 및 혜택 요약 카드.
extension AccountStatsSearchDisplay on _AccountStatsSearchScreenState {
  Widget _buildBenefitSummary(
    ThemeData theme, {
    required String query,
    required List<StatsSearchResult> results,
  }) {
    final plan = _lastPlan;
    if (plan == null) return const SizedBox.shrink();
    if (widget.memoOnly) return const SizedBox.shrink();
    if (query.isEmpty) return const SizedBox.shrink();

    final f = plan.filters;
    final isBenefit = _isBenefitQuery(plan);
    if (!isBenefit) return const SizedBox.shrink();

    var total = 0.0;
    var count = 0;

    bool isPointsKey(String key) {
      final k = key.toLowerCase();
      return k.contains('포인트') || k.contains('적립') || k.contains('point');
    }

    for (final r in results) {
      final tx = r.transaction;
      final byType = benefitByTypeForSearch(tx);
      double sum;
      if (f.pointsOnly) {
        sum = byType.entries
            .where((e) => isPointsKey(e.key))
            .fold<double>(0, (a, e) => a + e.value);
      } else {
        sum = byType.values.fold<double>(0, (a, b) => a + b);
      }
      if (sum <= 0) continue;
      count += 1;
      total += sum;
    }

    final avg = count == 0 ? 0.0 : (total / count);
    final label = f.pointsOnly ? '포인트' : '혜택';
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final readableSubStyle = subStyle?.copyWith(height: 1.25);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$label 합계: ${_currencyFormat.format(total)}원',
                    style: valueStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text('건수: $count', style: subStyle),
                const SizedBox(width: 12),
                Text('평균: ${_currencyFormat.format(avg)}원', style: subStyle),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _tenYearAggLoading
                  ? '최근 10년 누적(계정 전체): 계산 중…'
                  : '최근 10년 누적(계정 전체): '
                        '${_currencyFormat.format(_tenYearAggTotal ?? 0)}원',
              style: subStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (f.pointsOnly) ...[
              const SizedBox(height: 6),
              Text(
                _buildPointProjectionHeadline(),
                style: readableSubStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!_pointProjectionLoading) ...[
                const SizedBox(height: 4),
                Text(
                  '현재(이번달) 선택이 미래를 만듭니다',
                  style: readableSubStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!_pointProjectionLoading &&
                  (_pointProjectionMonthlyBase3mAvg ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _buildProjectionAvgLabel(
                    periodLabel: '최근 3개월',
                    base: _pointProjectionMonthlyBase3mAvg,
                    fiveYear: _pointProjectionFiveYear3mAvg,
                    tenYear: _pointProjectionTenYear3mAvg,
                  ),
                  style: readableSubStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!_pointProjectionLoading &&
                  (_pointProjectionMonthlyBase6mAvg ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _buildProjectionAvgLabel(
                    periodLabel: '최근 6개월',
                    base: _pointProjectionMonthlyBase6mAvg,
                    fiveYear: _pointProjectionFiveYear6mAvg,
                    tenYear: _pointProjectionTenYear6mAvg,
                  ),
                  style: readableSubStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _buildPointProjectionHeadline() {
    final annualRate = _pointProjectionAnnualRateUsed.toStringAsFixed(0);
    if (_pointProjectionLoading) {
      return '이번달(최우선) 포인트 기반 5/10년 예상(연 '
          '$annualRate%): 계산 중…';
    }
    final base = _pointProjectionMonthlyBase ?? 0;
    if (base <= 0) {
      return '이번달(최우선) 포인트 기반 5/10년 예상(연 '
          '$annualRate%): 0원';
    }
    final monthlyLabel = '${_currencyFormat.format(base)}원';
    final fiveYearLabel =
        '${_currencyFormat.format(_pointProjectionFiveYear ?? 0)}원';
    final tenYearLabel =
        '${_currencyFormat.format(_pointProjectionTenYear ?? 0)}원';
    return '이번달(최우선) 포인트 $monthlyLabel → 5년(연 '
        '$annualRate%): $fiveYearLabel · 10년: $tenYearLabel';
  }

  String _buildProjectionAvgLabel({
    required String periodLabel,
    required double? base,
    required double? fiveYear,
    required double? tenYear,
  }) {
    final baseLabel = '${_currencyFormat.format(base ?? 0)}원';
    final fiveYearLabel = '${_currencyFormat.format(fiveYear ?? 0)}원';
    final tenYearLabel = '${_currencyFormat.format(tenYear ?? 0)}원';
    return '참고(과거) $periodLabel 평균 $baseLabel → '
        '5년: $fiveYearLabel · 10년: $tenYearLabel';
  }

  String _formatSignedAmount(Transaction tx) =>
      '${tx.type.sign}${_currencyFormat.format(tx.amount)}원';

  String _searchResultSubtitle(StatsSearchResult result) {
    final formattedDate = _dateFormat.format(result.transaction.date);
    return '${result.accountName} · $formattedDate';
  }

  Widget _buildResultsList(
    ThemeData theme,
    List<StatsSearchResult> results,
    bool isLandscape,
  ) {
    return ListView.separated(
      itemCount: results.length > 50 ? 50 : results.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final result = results[index];
        final tx = result.transaction;
        final subtitle = _searchResultSubtitle(result);
        final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
        if (!isLandscape) {
          return ListTile(
            leading: Icon(
              statsIconForType(tx.type),
              color: statsColorForType(tx.type, theme),
            ),
            title: Text(tx.description),
            subtitle: Text(subtitle, style: subtitleStyle),
            trailing: Text(_formatSignedAmount(tx)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Icon(
                statsIconForType(tx.type),
                size: 18,
                color: statsColorForType(tx.type, theme),
              ),
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
                  subtitle,
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
    );
  }
}
