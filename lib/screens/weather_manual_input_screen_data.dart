// ignore_for_file: invalid_use_of_protected_member
part of 'weather_manual_input_screen.dart';

/// 날씨 데이터 로드/저장/삭제 및 헬퍼 메서드
extension WeatherManualInputData on _WeatherManualInputScreenState {
  Future<void> _loadWeatherHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_WeatherManualInputScreenState._weatherHistoryKey) ?? [];

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
    if (newHistory.length > _WeatherManualInputScreenState._maxHistoryCount) {
      newHistory.removeRange(_WeatherManualInputScreenState._maxHistoryCount, newHistory.length);
    }

    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    final historyJson = newHistory.map((w) => jsonEncode(w.toJson())).toList();
    await prefs.setStringList(_WeatherManualInputScreenState._weatherHistoryKey, historyJson);

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
    await prefs.setStringList(_WeatherManualInputScreenState._weatherHistoryKey, historyJson);

    setState(() {
      _weatherHistory = newHistory;
    });

    if (mounted) {
      SnackbarUtils.showInfo(context, '삭제되었습니다');
    }
  }

  String _getConditionLabel(String condition) {
    return _WeatherManualInputScreenState._conditions
            .where((c) => c.code == condition)
            .map((c) => c.label)
            .firstOrNull ??
        condition;
  }

  IconData _getConditionIcon(String condition) {
    return _WeatherManualInputScreenState._conditions
            .where((c) => c.code == condition)
            .map((c) => c.icon)
            .firstOrNull ??
        Icons.help_outline;
  }

  Color _getConditionColor(String condition) {
    return _WeatherManualInputScreenState._conditions
            .where((c) => c.code == condition)
            .map((c) => c.color)
            .firstOrNull ??
        Colors.grey;
  }
}
