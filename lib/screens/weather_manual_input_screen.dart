import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_snapshot.dart';
import '../utils/snackbar_utils.dart';

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

  Future<void> _loadWeatherHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_weatherHistoryKey) ?? [];

    final history = <WeatherSnapshot>[];
    for (final json in historyJson) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        history.add(WeatherSnapshot.fromJson(map));
      } catch (_) {
        // 파싱 실패 시 무시
      }
    }

    // 최신순 정렬
    history.sort((a, b) {
      final aTime = a.capturedAt ?? DateTime(1970);
      final bTime = b.capturedAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    setState(() {
      _weatherHistory = history;
      _isLoading = false;
    });
  }

  Future<void> _saveWeather() async {
    // 기온 파싱
    final tempText = _tempController.text.trim();
    double? tempC;
    if (tempText.isNotEmpty) {
      tempC = double.tryParse(tempText);
      if (tempC == null) {
        SnackbarUtils.showError(context, '기온을 숫자로 입력해주세요');
        return;
      }
    }

    // 습도 파싱
    final humidityText = _humidityController.text.trim();
    int? humidityPct;
    if (humidityText.isNotEmpty) {
      humidityPct = int.tryParse(humidityText);
      if (humidityPct == null || humidityPct < 0 || humidityPct > 100) {
        SnackbarUtils.showError(context, '습도는 0~100 사이 숫자로 입력해주세요');
        return;
      }
    }

    final weather = WeatherSnapshot(
      condition: _selectedCondition,
      tempC: tempC,
      humidityPct: humidityPct,
      capturedAt: DateTime.now(),
    );

    // 히스토리에 추가
    final newHistory = [weather, ..._weatherHistory];

    // 최대 개수 제한
    if (newHistory.length > _maxHistoryCount) {
      newHistory.removeRange(_maxHistoryCount, newHistory.length);
    }

    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    final historyJson = newHistory.map((w) => jsonEncode(w.toJson())).toList();
    await prefs.setStringList(_weatherHistoryKey, historyJson);

    setState(() {
      _weatherHistory = newHistory;
      _tempController.clear();
      _humidityController.clear();
      _memoController.clear();
    });

    if (mounted) {
      SnackbarUtils.showSuccess(context, '날씨 정보가 저장되었습니다');
    }
  }

  Future<void> _deleteWeather(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 날씨 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newHistory = List<WeatherSnapshot>.from(_weatherHistory);
    newHistory.removeAt(index);

    final prefs = await SharedPreferences.getInstance();
    final historyJson = newHistory.map((w) => jsonEncode(w.toJson())).toList();
    await prefs.setStringList(_weatherHistoryKey, historyJson);

    setState(() {
      _weatherHistory = newHistory;
    });

    if (mounted) {
      SnackbarUtils.showInfo(context, '삭제되었습니다');
    }
  }

  String _getConditionLabel(String condition) {
    return _conditions
            .where((c) => c.code == condition)
            .map((c) => c.label)
            .firstOrNull ??
        condition;
  }

  IconData _getConditionIcon(String condition) {
    return _conditions
            .where((c) => c.code == condition)
            .map((c) => c.icon)
            .firstOrNull ??
        Icons.help_outline;
  }

  Color _getConditionColor(String condition) {
    return _conditions
            .where((c) => c.code == condition)
            .map((c) => c.color)
            .firstOrNull ??
        Colors.grey;
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

  Widget _buildConditionGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _conditions.map((condition) {
        final isSelected = _selectedCondition == condition.code;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                condition.icon,
                size: 18,
                color: isSelected ? Colors.white : condition.color,
              ),
              const SizedBox(width: 4),
              Text(condition.label),
            ],
          ),
          selected: isSelected,
          selectedColor: condition.color,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedCondition = condition.code;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildHistoryList() {
    // 최근 30건만 표시
    final displayHistory = _weatherHistory.take(30).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayHistory.length,
      itemBuilder: (context, index) {
        final weather = displayHistory[index];
        final date = weather.capturedAt;
        final dateStr = date == null
            ? '날짜 없음'
            : () {
                final hh = date.hour.toString().padLeft(2, '0');
                final mm = date.minute.toString().padLeft(2, '0');
                return '${date.month}/${date.day} $hh:$mm';
              }();

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getConditionColor(
                weather.condition,
              ).withValues(alpha: 0.2),
              child: Icon(
                _getConditionIcon(weather.condition),
                color: _getConditionColor(weather.condition),
              ),
            ),
            title: Text(_getConditionLabel(weather.condition)),
            subtitle: Text(dateStr),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (weather.tempC != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${weather.tempC!.toStringAsFixed(0)}°C',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (weather.humidityPct != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${weather.humidityPct}%',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteWeather(index),
                  tooltip: '삭제',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('날씨 입력 도움말'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('날씨 데이터 활용', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 식료품 가격 변동 예측에 활용됩니다'),
              Text('• 계절별 구매 패턴 분석에 사용됩니다'),
              Text('• 날씨와 지출 관계를 파악합니다'),
              SizedBox(height: 16),
              Text('입력 팁', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 장보기 전/후에 날씨를 기록하세요'),
              Text('• 기온/습도는 선택 입력입니다'),
              Text('• 최대 1년치 데이터가 저장됩니다'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
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
