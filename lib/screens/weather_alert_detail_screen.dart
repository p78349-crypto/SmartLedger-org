// 날씨 알림 상세 화면
//
// 극한 날씨 정보와 대비 품목을 상세히 표시

import 'package:flutter/material.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_alert_widget.dart';

class WeatherAlertDetailScreen extends StatelessWidget {
  final WeatherData weather;

  const WeatherAlertDetailScreen({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('날씨 알림'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 공유 기능 (향후 구현)
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('공유 기능 준비 중입니다')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날씨 알림 위젯
              WeatherAlertWidget(weather: weather),
              const SizedBox(height: 24),

              // 가격 변동 예측
              _buildPricePredictionSection(context),
              const SizedBox(height: 24),

              // 음성 비서 명령어 안내
              _buildVoiceCommandSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 가격 변동 예측 섹션
  Widget _buildPricePredictionSection(BuildContext context) {
    final predictions = WeatherUtils.predictPriceChanges(
      weather: weather,
      minSensitivity: 0.5, // 50% 이상 민감도만
    );

    if (predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    final rising = WeatherUtils.getAvoidRecommendations(predictions);
    final falling = WeatherUtils.getBuyRecommendations(predictions);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, size: 20),
                SizedBox(width: 8),
                Text(
                  '가격 변동 예측',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 가격 상승 품목
            if (rising.isNotEmpty) ...[
              const Text(
                '🔴 가격 상승 예상 (미리 구매하세요)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ...rising.map(
                (p) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.arrow_upward,
                    color: Colors.red,
                    size: 20,
                  ),
                  title: Text(p.itemName),
                  trailing: Text(
                    '+${p.predictedChange.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    p.reason,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 가격 하락 품목
            if (falling.isNotEmpty) ...[
              const Text(
                '🟢 가격 하락 예상 (지금 구매 적기)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              ...falling.map(
                (p) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.arrow_downward,
                    color: Colors.green,
                    size: 20,
                  ),
                  title: Text(p.itemName),
                  trailing: Text(
                    '${p.predictedChange.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    p.reason,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 음성 비서 명령어 섹션
  Widget _buildVoiceCommandSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mic, size: 20),
                SizedBox(width: 8),
                Text(
                  '음성 명령어',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVoiceCommand('빅스비, 날씨 알림'),
            _buildVoiceCommand('빅스비, 태풍 대비'),
            _buildVoiceCommand('빅스비, 한파 준비'),
            _buildVoiceCommand('빅스비, 날씨 물가'),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCommand(String command) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(command, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
