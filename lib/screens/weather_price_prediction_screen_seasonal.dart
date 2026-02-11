part of 'weather_price_prediction_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension WeatherPredictionSeasonalAnalysis
    on _WeatherPricePredictionScreenState {
  Widget buildCorrelationCard(
    WeatherPriceCorrelation correlation,
    ThemeData theme,
  ) {
    final strength = correlation.strength;
    final color = strength > 0.5
        ? Colors.red
        : strength > 0.3
        ? Colors.orange
        : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '날씨-가격 상관관계',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: strength,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(strength * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(correlation.explanation),
          ],
        ),
      ),
    );
  }

  Widget buildSeasonalStatsCard(
    List<SeasonalPriceStat> stats,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '계절별 가격 분석',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...stats.map((stat) {
              final seasonLabel = WeatherPricePredictionUtils.getSeasonLabel(
                stat.season,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 100, child: Text(seasonLabel)),
                    Expanded(
                      child: Text(
                        '평균 ${_currencyFormat.format(stat.avgPrice)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '(${stat.sampleCount}건)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // === TAB 3: 제철 식품 ===
  Widget buildSeasonalTab(ThemeData theme) {
    final now = DateTime.now();
    final currentSeason = WeatherPricePredictionUtils.getSeason(now);
    final seasonLabel = WeatherPricePredictionUtils.getSeasonLabel(
      currentSeason,
    );
    final recommendations =
        WeatherPricePredictionUtils.getSeasonalRecommendations(now);

    // 전체 카테고리별 제철 식품
    const allCategories = WeatherPricePredictionUtils.weatherSensitiveItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이달의 제철 식품
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '${now.month}월 제철 식품',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(seasonLabel, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recommendations
                        .map(
                          (item) => Chip(
                            avatar: const Icon(Icons.check_circle, size: 18),
                            label: Text(item),
                            backgroundColor: Colors.green.shade100,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '제철 식품은 맛이 좋고 가격이 저렴해요!',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 카테고리별 날씨 민감 품목
          Text(
            '🌡️ 날씨에 민감한 식료품',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...allCategories.entries.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Icon(_getCategoryIcon(entry.key)),
                title: Text(entry.key),
                subtitle: Text('${entry.value.length}개 품목'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((item) {
                        final sensitivity =
                            WeatherPricePredictionUtils
                                .itemWeatherSensitivity[item] ??
                            0.5;
                        final sensitivityLabel = sensitivity >= 0.7
                            ? '높음'
                            : sensitivity >= 0.5
                            ? '중간'
                            : '낮음';
                        final color = sensitivity >= 0.7
                            ? Colors.red
                            : sensitivity >= 0.5
                            ? Colors.orange
                            : Colors.green;

                        return ActionChip(
                          avatar: CircleAvatar(
                            radius: 10,
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Text(
                              sensitivityLabel[0],
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          label: Text(item),
                          onPressed: () {
                            setState(() {
                              _searchQuery = item;
                              _tabController.animateTo(1);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 민감도 범례
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('높', Colors.red, '날씨 영향 큼'),
                  _buildLegendItem('중', Colors.orange, '날씨 영향 보통'),
                  _buildLegendItem('낮', Colors.green, '날씨 영향 적음'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
