import 'package:flutter/material.dart';
import '../models/weather_snapshot.dart';

/// 날씨 조건 항목 데이터 클래스
class WeatherConditionItem {
  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const WeatherConditionItem(this.code, this.label, this.icon, this.color);
}

/// 날씨 조건 목록
const List<WeatherConditionItem> weatherConditions = [
  WeatherConditionItem('sunny', '맑음', Icons.wb_sunny, Colors.orange),
  WeatherConditionItem(
    'partly_cloudy',
    '구름조금',
    Icons.cloud_queue,
    Colors.blueGrey,
  ),
  WeatherConditionItem('cloudy', '흐림', Icons.cloud, Colors.grey),
  WeatherConditionItem('rain', '비', Icons.umbrella, Colors.blue),
  WeatherConditionItem(
    'heavy_rain',
    '폭우',
    Icons.thunderstorm,
    Colors.indigo,
  ),
  WeatherConditionItem('snow', '눈', Icons.ac_unit, Colors.cyan),
  WeatherConditionItem('fog', '안개', Icons.blur_on, Colors.blueGrey),
  WeatherConditionItem('windy', '바람', Icons.air, Colors.teal),
  WeatherConditionItem(
    'hot',
    '무더위',
    Icons.local_fire_department,
    Colors.red,
  ),
  WeatherConditionItem('cold', '한파', Icons.severe_cold, Colors.blue),
];

// ---------------------------------------------------------------------------
// 헬퍼 함수
// ---------------------------------------------------------------------------

/// 조건 코드 → 한글 라벨
String getConditionLabel(String condition) {
  return weatherConditions
          .where((c) => c.code == condition)
          .map((c) => c.label)
          .firstOrNull ??
      condition;
}

/// 조건 코드 → 아이콘
IconData getConditionIcon(String condition) {
  return weatherConditions
          .where((c) => c.code == condition)
          .map((c) => c.icon)
          .firstOrNull ??
      Icons.help_outline;
}

/// 조건 코드 → 색상
Color getConditionColor(String condition) {
  return weatherConditions
          .where((c) => c.code == condition)
          .map((c) => c.color)
          .firstOrNull ??
      Colors.grey;
}

// ---------------------------------------------------------------------------
// 위젯
// ---------------------------------------------------------------------------

/// 날씨 조건 선택 그리드
class WeatherConditionGrid extends StatelessWidget {
  const WeatherConditionGrid({
    super.key,
    required this.selectedCondition,
    required this.onSelected,
  });

  final String selectedCondition;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: weatherConditions.map((condition) {
        final isSelected = selectedCondition == condition.code;
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
              onSelected(condition.code);
            }
          },
        );
      }).toList(),
    );
  }
}

/// 날씨 히스토리 목록
class WeatherHistoryList extends StatelessWidget {
  const WeatherHistoryList({
    super.key,
    required this.history,
    required this.onDelete,
  });

  final List<WeatherSnapshot> history;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    // 최근 30건만 표시
    final displayHistory = history.take(30).toList();

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
              backgroundColor: getConditionColor(
                weather.condition,
              ).withValues(alpha: 0.2),
              child: Icon(
                getConditionIcon(weather.condition),
                color: getConditionColor(weather.condition),
              ),
            ),
            title: Text(getConditionLabel(weather.condition)),
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
                  onPressed: () => onDelete(index),
                  tooltip: '삭제',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 날씨 입력 도움말 다이얼로그 표시
void showWeatherInfoDialog(BuildContext context) {
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
            Text('• 장보기 전/후에 날씨를 입력하세요'),
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
