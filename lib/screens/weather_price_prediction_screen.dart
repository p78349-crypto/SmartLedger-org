import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/weather_snapshot.dart';
import '../services/transaction_service.dart';
import '../utils/number_formats.dart';
import '../utils/weather_price_prediction_utils.dart';
import '../widgets/background_widget.dart';

part 'weather_price_prediction_screen_alerts.dart';
part 'weather_price_prediction_screen_search.dart';
part 'weather_price_prediction_screen_seasonal.dart';

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
                    buildWeatherHeader(theme),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          buildAlertsTab(theme),
                          buildSearchTab(theme),
                          buildSeasonalTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
