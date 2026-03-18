part of 'weather_price_prediction_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension WeatherPredictionSearch on _WeatherPricePredictionScreenState {
  // === TAB 2: 품목 검색 ===
  Widget buildSearchTab(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: '품목명을 입력하세요 (예: 배추, 사과)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),

        // 추천 품목 칩
        if (_searchQuery.isEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['배추', '시금치', '상추', '사과', '수박', '고추', '양파']
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(item),
                        onPressed: () {
                          setState(() => _searchQuery = item);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        const SizedBox(height: 16),

        // 검색 결과
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildEmptyState(theme, '품목을 검색하여 가격 예측을 확인하세요')
              : _buildPredictionResult(theme),
        ),
      ],
    );
  }

  Widget _buildPredictionResult(ThemeData theme) {
    if (_currentWeather == null) {
      return _buildEmptyState(theme, '날씨 정보 로딩 중...');
    }

    final prediction = WeatherPricePredictionUtils.predictPrice(
      itemName: _searchQuery,
      transactions: _allTransactions,
      currentWeather: _currentWeather!,
    );

    final correlation = WeatherPricePredictionUtils.analyzeWeatherCorrelation(
      _searchQuery,
      _allTransactions,
    );

    final seasonalStats = WeatherPricePredictionUtils.calculateSeasonalStats(
      _searchQuery,
      _allTransactions,
    );

    if (prediction == null) {
      return _buildEmptyState(
        theme,
        '\'$_searchQuery\'에 대한 구매 기록이 부족합니다.\n더 많은 데이터가 쌓이면 예측이 가능합니다.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 예측 결과 카드
          _buildPredictionCard(prediction, theme),

          const SizedBox(height: 16),

          // 날씨 상관관계
          if (correlation != null) buildCorrelationCard(correlation, theme),

          const SizedBox(height: 16),

          // 계절별 가격
          if (seasonalStats.isNotEmpty)
            buildSeasonalStatsCard(seasonalStats, theme),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(PricePrediction prediction, ThemeData theme) {
    final isRising = prediction.trend == PriceTrend.rising;
    final isFalling = prediction.trend == PriceTrend.falling;
    final trendColor = isRising
        ? Colors.red
        : isFalling
        ? Colors.green
        : theme.colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRising
                      ? Icons.trending_up
                      : isFalling
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  color: trendColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.itemName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('7일 후 가격 예측', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 가격 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPriceColumn(
                  '현재 평균가',
                  _currencyFormat.format(prediction.currentPrice),
                  theme,
                ),
                Icon(Icons.arrow_forward, color: theme.colorScheme.outline),
                _buildPriceColumn(
                  '예상가',
                  _currencyFormat.format(prediction.predictedPrice),
                  theme,
                  color: trendColor,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 변동률
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${prediction.changePercent >= 0 ? '+' : ''}'
                  '${prediction.changePercent.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 분석 이유
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 분석 근거', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(prediction.reason),
                ],
              ),
            ),

            // 추천
            if (prediction.recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...prediction.recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                ),
              ),
            ],

            // 신뢰도
            const SizedBox(height: 12),
            Row(
              children: [
                Text('신뢰도: ', style: theme.textTheme.bodySmall),
                Expanded(
                  child: LinearProgressIndicator(
                    value: prediction.confidence,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
