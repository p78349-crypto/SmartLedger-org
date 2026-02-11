// ignore_for_file: invalid_use_of_protected_member
part of 'weather_manual_input_screen.dart';

/// 날씨 입력 UI 위젯 빌더 (그리드, 히스토리, 다이얼로그)
extension WeatherManualInputUI on _WeatherManualInputScreenState {
  Widget _buildConditionGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _WeatherManualInputScreenState._conditions.map((condition) {
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
}
