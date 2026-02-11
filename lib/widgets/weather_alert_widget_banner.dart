part of 'weather_alert_widget.dart';

/// 간단한 날씨 알림 배너 (홈 화면용)
class WeatherAlertBanner extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback? onTap;

  const WeatherAlertBanner({super.key, required this.weather, this.onTap});

  @override
  Widget build(BuildContext context) {
    final condition = weather.effectiveCondition;
    final isExtreme = isExtremeWeather(condition);

    if (!isExtreme) {
      return const SizedBox.shrink();
    }

    final riskLevel = getWeatherRiskLevel(condition);
    final prepItems = weatherPrepDatabase[condition] ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getRiskColor(riskLevel).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getRiskColor(riskLevel), width: 2),
        ),
        child: Row(
          children: [
            Icon(
              _getRiskIcon(riskLevel),
              color: _getRiskColor(riskLevel),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getAlertTitle(condition),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getRiskColor(riskLevel),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '대비 품목 ${prepItems.length}개 확인 필요',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _getRiskColor(riskLevel)),
          ],
        ),
      ),
    );
  }
}
