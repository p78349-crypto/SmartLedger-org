// ignore_for_file: invalid_use_of_protected_member

part of 'points_motivation_stats_screen.dart';

extension PointsMotivationStatsHelpersSection
    on _PointsMotivationStatsScreenState {
  Widget _buildMotivationCard(
    ThemeData theme, {
    required String horizonLabel,
    required double fvTotal,
    required double simpleTotal,
    required String topCategory,
    required double topValue,
    required double fvTotal10y,
    required double simpleTotal10y,
    required String topCategory10y,
    required double topValue10y,
  }) {
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconCatalog.localOffer, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '작은 절약의 10년 효과',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '현재 패턴이면 $horizonLabel 뒤: ${_formatWon(fvTotal)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '단순 누적(이자 0%): ${_formatWon(simpleTotal)}'
              '  · 가장 큰 유입원: $topCategory ${_formatWon(topValue)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '10년 뒤(항상): ${_formatWon(fvTotal10y)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '단순 누적(이자 0%): ${_formatWon(simpleTotal10y)}'
              '  · 유입원 TOP: $topCategory10y ${_formatWon(topValue10y)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '포인트로 더 저렴하게 산 "가격 차이"를 모으면, 10년 뒤에는 꽤 큰 돈이 됩니다.\n'
              '부자가 되려면 작은 돈이 여러 곳에서 흘러들어오는 구조를 만들고, 꾸준히 유지하는 것이 핵심입니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(IconCatalog.localOffer, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '포인트(혜택) 데이터가 없습니다',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '최근 $_lookbackDaysForRate일 동안 혜택/포인트 절감액이 잡히면 '
                  '카드/마트/쇼핑몰/편의점/기타로 자동 표시됩니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '팁: 거래 메모에 "혜택:카드=1200, 마트=500" 처럼 기록하거나 '
                  'benefit 입력 기능을 사용하면 더 정확해집니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizonChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _horizons.length; i++)
          ChoiceChip(
            label: Text(_horizons[i].label),
            selected: _selectedIndex == i,
            onSelected: (v) {
              if (!v) return;
              setState(() => _selectedIndex = i);
            },
          ),
      ],
    );
  }
}
