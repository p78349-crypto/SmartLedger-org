part of 'application_settings_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension ApplicationSettingsHouseholdDialog
    on _ApplicationSettingsScreenState {
  String _buildActivityHouseholdEstimateText({
    required ActivityHouseholdEstimate estimate,
    required ActivityHouseholdTrendComparison? trend,
  }) {
    final indicators = estimate.usedIndicators.join(', ');
    final trendText = trend == null
        ? ''
        : '\n\n현재/평소 비교\n'
              '최근 ${trend.shortWindow.usedWindowDays}일은 '
              '최근 ${trend.baselineWindow.usedWindowDays}일 대비 '
              '${trend.ratio}배 소비 중입니다.';

    return '최근 ${estimate.usedWindowDays}일 추정: '
        '약 ${estimate.estimatedPeople}명 (신뢰도 ${estimate.confidence})\n'
        '근거 품목: $indicators'
        '$trendText';
  }

  Future<void> _showActiveHouseholdEstimatorDialog() async {
    final settings = await ActivityHouseholdEstimatorService.loadSettings();
    final estimate = await ActivityHouseholdEstimatorService.estimateNow();
    final trend = await ActivityHouseholdEstimatorService.compareTrend();

    var enabled = settings.enabled;
    var windowDays = settings.windowDays;
    var maxWindowDays = settings.maxWindowDays;

    final windowDaysController = TextEditingController(
      text: windowDays.toString(),
    );

    final indicators = [...settings.indicators];
    final controllers = <int, Map<String, TextEditingController>>{};

    void buildControllers() {
      controllers.clear();
      for (var i = 0; i < indicators.length; i++) {
        final it = indicators[i];
        controllers[i] = {
          'name': TextEditingController(text: it.name),
          'unit': TextEditingController(text: it.unit),
          'ppd': TextEditingController(
            text: it.perPersonPerDay <= 0 ? '' : it.perPersonPerDay.toString(),
          ),
        };
      }
    }

    buildControllers();

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('활동 가족 수(실질 인원) 추정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (estimate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _buildActivityHouseholdEstimateText(
                          estimate: estimate,
                          trend: trend,
                        ),
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '아직 사용/차감 데이터가 부족합니다.\n'
                        '식재료/생활용품을 -1 차감하거나 수량을 줄이면 추정이 시작됩니다.',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('기능 사용'),
                    value: enabled,
                    onChanged: (v) => setDialogState(() => enabled = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: const TextInputType.numberWithOptions(),
                    decoration: InputDecoration(
                      labelText: '분석 기간(일) (3~$maxWindowDays)',
                      border: const OutlineInputBorder(),
                    ),
                    controller: windowDaysController,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) {
                        setDialogState(() {
                          windowDays = n.clamp(3, maxWindowDays);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: maxWindowDays,
                    decoration: const InputDecoration(
                      labelText: '자동 확장 최대(일)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 60, child: Text('60일')),
                      DropdownMenuItem(value: 180, child: Text('180일(6개월)')),
                      DropdownMenuItem(value: 365, child: Text('365일(1년)')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        maxWindowDays = v;
                        if (windowDays > maxWindowDays) {
                          windowDays = maxWindowDays;
                          windowDaysController.text = windowDays.toString();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '지표 품목(1인당/일 기준)',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < indicators.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: controllers[i]!['name'],
                            decoration: const InputDecoration(
                              labelText: '품목명(부분일치)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: controllers[i]!['unit'],
                            decoration: const InputDecoration(
                              labelText: '단위',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers[i]!['ppd'],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '1인당/일 소비량',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: '삭제',
                          onPressed: indicators.length <= 1
                              ? null
                              : () {
                                  setDialogState(() {
                                    indicators.removeAt(i);
                                    buildControllers();
                                  });
                                },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          indicators.add(
                            const ActivityIndicatorItem(
                              name: '',
                              unit: '',
                              perPersonPerDay: 0,
                            ),
                          );
                          buildControllers();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('지표 품목 추가'),
                    ),
                  ),
                  Text(
                    '팁: 달걀(0.5개/일), 쌀(예: 120g/일)처럼 "자주 쓰는 기준품목"을 넣을수록 안정적입니다.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('저장'),
              ),
            ],
          );
        },
      ),
    );

    windowDaysController.dispose();

    for (final row in controllers.values) {
      for (final c in row.values) {
        c.dispose();
      }
    }

    if (saved != true) return;

    final nextIndicators = <ActivityIndicatorItem>[];
    for (var i = 0; i < indicators.length; i++) {
      final name = (controllers[i]?['name']?.text ?? '').trim();
      final unit = (controllers[i]?['unit']?.text ?? '').trim();
      final ppdText = (controllers[i]?['ppd']?.text ?? '').trim();
      final ppd = double.tryParse(ppdText) ?? 0.0;
      final it = ActivityIndicatorItem(
        name: name,
        unit: unit,
        perPersonPerDay: ppd,
      );
      if (it.isValid) nextIndicators.add(it);
    }

    final next = ActivityHouseholdEstimatorSettings(
      enabled: enabled,
      windowDays: windowDays,
      maxWindowDays: maxWindowDays,
      indicators: nextIndicators.isEmpty ? settings.indicators : nextIndicators,
    );
    await ActivityHouseholdEstimatorService.saveSettings(next);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('활동 가족 수 추정 설정을 저장했습니다.')));
  }
}
