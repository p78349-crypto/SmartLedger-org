import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_snapshot.dart';
import '../utils/snackbar_utils.dart';

part 'weather_manual_input_screen_data.dart';
part 'weather_manual_input_screen_ui.dart';

/// 수동 날씨 입력 화면
///
/// 사용자가 현재 날씨를 직접 입력하여 저장합니다.
/// 저장된 날씨 데이터는 날씨-가격 예측 시스템에 활용됩니다.
class WeatherManualInputScreen extends StatefulWidget {
  const WeatherManualInputScreen({super.key});

  @override
  State<WeatherManualInputScreen> createState() =>
      _WeatherManualInputScreenState();
}

class _WeatherManualInputScreenState extends State<WeatherManualInputScreen> {
  static const String _weatherHistoryKey = 'weather_history';
  static const int _maxHistoryCount = 365; // 최대 1년치 저장

  String _selectedCondition = 'sunny';
  final _tempController = TextEditingController();
  final _humidityController = TextEditingController();
  final _memoController = TextEditingController();

  List<WeatherSnapshot> _weatherHistory = [];
  bool _isLoading = true;

  // 날씨 조건 목록
  static const List<_WeatherConditionItem> _conditions = [
    _WeatherConditionItem('sunny', '맑음', Icons.wb_sunny, Colors.orange),
    _WeatherConditionItem(
      'partly_cloudy',
      '구름조금',
      Icons.cloud_queue,
      Colors.blueGrey,
    ),
    _WeatherConditionItem('cloudy', '흐림', Icons.cloud, Colors.grey),
    _WeatherConditionItem('rain', '비', Icons.umbrella, Colors.blue),
    _WeatherConditionItem(
      'heavy_rain',
      '폭우',
      Icons.thunderstorm,
      Colors.indigo,
    ),
    _WeatherConditionItem('snow', '눈', Icons.ac_unit, Colors.cyan),
    _WeatherConditionItem('fog', '안개', Icons.blur_on, Colors.blueGrey),
    _WeatherConditionItem('windy', '바람', Icons.air, Colors.teal),
    _WeatherConditionItem(
      'hot',
      '무더위',
      Icons.local_fire_department,
      Colors.red,
    ),
    _WeatherConditionItem('cold', '한파', Icons.severe_cold, Colors.blue),
  ];

  @override
  void initState() {
    super.initState();
    _loadWeatherHistory();
  }

  @override
  void dispose() {
    _tempController.dispose();
    _humidityController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('날씨 입력'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: '도움말',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날씨 조건 선택
                  Text(
                    '현재 날씨',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildConditionGrid(),

                  const SizedBox(height: 24),

                  // 기온 입력
                  Text(
                    '기온 (선택)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tempController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: '예: 25, -5',
                      suffixText: '°C',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 습도 입력
                  Text(
                    '습도 (선택)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _humidityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0~100',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveWeather,
                      icon: const Icon(Icons.save),
                      label: const Text('날씨 저장'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 히스토리
                  Row(
                    children: [
                      Text(
                        '최근 기록',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_weatherHistory.length}건)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_weatherHistory.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            '저장된 날씨 기록이 없습니다',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildHistoryList(),
                ],
              ),
            ),
    );
  }
}

class _WeatherConditionItem {
  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const _WeatherConditionItem(this.code, this.label, this.icon, this.color);
}
