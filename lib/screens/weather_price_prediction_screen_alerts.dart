part of 'weather_price_prediction_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension WeatherPredictionAlerts on _WeatherPricePredictionScreenState {
  Widget buildWeatherHeader(ThemeData theme) {
    if (_currentWeather == null) return const SizedBox.shrink();

    final weather = _currentWeather!;
    final temp = weather.tempC ?? 20.0;
    final isHot = temp >= 30;
    final isCold = temp <= -5;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHot
              ? [Colors.orange.shade300, Colors.red.shade300]
              : isCold
              ? [Colors.blue.shade300, Colors.blue.shade600]
              : [Colors.blue.shade200, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isHot
                ? Icons.wb_sunny
                : isCold
                ? Icons.ac_unit
                : Icons.cloud,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 날씨: ${weather.condition}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '기온: ${temp.toStringAsFixed(1)}°C',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (isHot)
                  Text(
                    '⚠️ 폭염 주의 - 엽채류 가격 상승 예상',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.yellow.shade100,
                    ),
                  ),
                if (isCold)
                  Text(
                    '⚠️ 한파 주의 - 일부 품목 가격 변동',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.yellow.shade100,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === TAB 1: 알림 ===
  Widget buildAlertsTab(ThemeData theme) {
    if (_currentWeather == null) {
      return _buildEmptyState(theme, '날씨 정보를 불러오는 중...');
    }

    final alerts = WeatherPricePredictionUtils.generateAlerts(
      transactions: _allTransactions,
      currentWeather: _currentWeather!,
    );

    // AI 리포트
    final report = WeatherPricePredictionUtils.generateWeatherPriceReport(
      transactions: _allTransactions,
      currentWeather: _currentWeather!,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 리포트 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI 분석 리포트',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(report, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 가격 알림 목록
          Text(
            '⚠️ 가격 변동 알림',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (alerts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '현재 주요 품목 가격이 안정적입니다',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...alerts.map((alert) => _buildAlertCard(alert, theme)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(WeatherPriceAlert alert, ThemeData theme) {
    final isRising = alert.expectedTrend == PriceTrend.rising;
    final color = isRising ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(
            isRising ? Icons.trending_up : Icons.trending_down,
            color: color,
          ),
        ),
        title: Text(
          alert.itemName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${alert.expectedChangePercent >= 0 ? '+' : ''}'
              '${alert.expectedChangePercent.toStringAsFixed(1)}% 예상',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            Text('${alert.triggerWeather} · ${alert.daysUntilImpact}일 내'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '💡 ${alert.recommendation}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
