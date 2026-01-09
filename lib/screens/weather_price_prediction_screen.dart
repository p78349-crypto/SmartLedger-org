import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/weather_snapshot.dart';
import '../services/transaction_service.dart';
import '../utils/number_formats.dart';
import '../utils/weather_price_prediction_utils.dart';
import '../widgets/background_widget.dart';

/// 날씨 기반 식료품 가격 예측 화면
///
/// - 현재 날씨 기반 가격 알림
/// - 품목별 가격 예측
/// - 제철 식품 추천
/// - 계절별 가격 분석
class WeatherPricePredictionScreen extends StatefulWidget {
  final String accountName;

  const WeatherPricePredictionScreen({super.key, required this.accountName});

  @override
  State<WeatherPricePredictionScreen> createState() =>
      _WeatherPricePredictionScreenState();
}

class _WeatherPricePredictionScreenState
    extends State<WeatherPricePredictionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaction> _allTransactions = [];
  bool _loading = true;
  WeatherSnapshot? _currentWeather;
  String _searchQuery = '';

  final NumberFormat _currencyFormat = NumberFormats.currency;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    await TransactionService().loadTransactions();
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );

    // 현재 날씨 (시뮬레이션 - 실제로는 API 호출)
    final now = DateTime.now();
    final mockWeather = WeatherSnapshot(
      condition: now.month >= 6 && now.month <= 8 ? '맑음' : '흐림',
      tempC: _getSeasonalTemp(now),
      capturedAt: now,
      source: 'simulated',
    );

    if (!mounted) return;
    setState(() {
      _allTransactions = transactions;
      _currentWeather = mockWeather;
      _loading = false;
    });
  }

  double _getSeasonalTemp(DateTime date) {
    // 계절별 평균 기온 시뮬레이션
    final month = date.month;
    if (month >= 6 && month <= 8) return 28.0 + (date.day % 5);
    if (month >= 12 || month <= 2) return -2.0 + (date.day % 8);
    if (month >= 3 && month <= 5) return 15.0 + (date.day % 5);
    return 18.0 + (date.day % 5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('날씨 기반 가격 예측'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.notifications_active), text: '알림'),
                Tab(icon: Icon(Icons.search), text: '품목 검색'),
                Tab(icon: Icon(Icons.eco), text: '제철 식품'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: '새로고침',
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildWeatherHeader(theme),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAlertsTab(theme),
                          _buildSearchTab(theme),
                          _buildSeasonalTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildWeatherHeader(ThemeData theme) {
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
  Widget _buildAlertsTab(ThemeData theme) {
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

  // === TAB 2: 품목 검색 ===
  Widget _buildSearchTab(ThemeData theme) {
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
          if (correlation != null) _buildCorrelationCard(correlation, theme),

          const SizedBox(height: 16),

          // 계절별 가격
          if (seasonalStats.isNotEmpty)
            _buildSeasonalStatsCard(seasonalStats, theme),
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

  Widget _buildPriceColumn(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCorrelationCard(
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

  Widget _buildSeasonalStatsCard(
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
  Widget _buildSeasonalTab(ThemeData theme) {
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

  Widget _buildLegendItem(String label, Color color, String description) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(description, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category) {
      '채소' => Icons.grass,
      '과일' => Icons.apple,
      '수산물' => Icons.set_meal,
      '육류' => Icons.restaurant,
      _ => Icons.category,
    };
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
