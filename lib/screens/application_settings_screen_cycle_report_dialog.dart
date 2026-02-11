part of 'application_settings_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension ApplicationSettingsCycleReportDialog
    on _ApplicationSettingsScreenState {
  Future<void> _showReplacementCycleNotificationDialog() async {
    final settings = await ReplacementCycleNotificationService.instance
        .loadSettings();

    var enabled = settings.enabled;
    var maxWindowDays = settings.maxWindowDays;
    var leadDays = settings.leadDays;
    var minCycleDays = settings.minCycleDays;

    final leadController = TextEditingController(text: leadDays.toString());
    final minCycleController = TextEditingController(
      text: minCycleDays.toString(),
    );

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('교체 주기 알림'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('기능 사용'),
                    value: enabled,
                    onChanged: (v) => setDialogState(() => enabled = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: maxWindowDays,
                    decoration: const InputDecoration(
                      labelText: '분석 최대(일)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 60, child: Text('60일')),
                      DropdownMenuItem(value: 180, child: Text('180일(6개월)')),
                      DropdownMenuItem(value: 365, child: Text('365일(1년)')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => maxWindowDays = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: leadController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    decoration: const InputDecoration(
                      labelText: '미리 알림(일)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) {
                        setDialogState(() => leadDays = n.clamp(0, 60));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: minCycleController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    decoration: const InputDecoration(
                      labelText: '최소 주기(일) (짧은 소모품 제외)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) {
                        setDialogState(() => minCycleDays = n.clamp(7, 180));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '팁: 칫솔/필터/대용량 세제 같은 품목은 차감 기록이 드물어도\n'
                    '90~365일 데이터가 쌓이면 교체 시점을 잡아낼 수 있습니다.',
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

    leadController.dispose();
    minCycleController.dispose();

    if (saved != true) return;

    final next = ReplacementCycleNotificationSettings(
      enabled: enabled,
      maxWindowDays: maxWindowDays,
      leadDays: leadDays,
      minCycleDays: minCycleDays,
    );
    await ReplacementCycleNotificationService.instance.saveSettings(next);

    try {
      await ReplacementCycleNotificationService.instance.rescheduleFromPrefs();
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('교체 주기 알림 설정을 저장했습니다.')));
  }

  Future<void> _showAnnualReportDialog() async {
    final report = await AnnualHouseholdReportService.buildReport();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String body;
        if (report == null) {
          body =
              '아직 연간 리포트를 만들 데이터가 부족합니다.\n'
              '품목을 차감(-1)하거나 수량을 줄이면 데이터가 쌓입니다.';
        } else {
          final topItemAmountText = report.topItemAmount.toStringAsFixed(0);
          final topItemLine = '${report.topItemName}: $topItemAmountText';
          final topLines = report.topItems
              .map((e) => '- ${e.key}: ${e.value.toStringAsFixed(0)}')
              .join('\n');
          body =
              '최근 ${report.windowDays}일 기준\n'
              '총 차감 이벤트: ${report.totalEvents}건\n'
              '관리한 품목 수(고유): ${report.distinctItems}개\n\n'
              '가장 많이 차감한 품목\n'
              '$topItemLine\n\n'
              'TOP 5\n$topLines';
        }

        return AlertDialog(
          title: const Text('연간 리포트(베타)'),
          content: Text(body, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}
