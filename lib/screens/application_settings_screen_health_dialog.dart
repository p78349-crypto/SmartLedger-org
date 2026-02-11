part of 'application_settings_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension ApplicationSettingsHealthDialog on _ApplicationSettingsScreenState {
  Future<void> _showHealthGuardrailDialog() async {
    final settings = await HealthGuardrailService.loadSettings();

    var enabled = settings.enabled;
    final weeklyControllers = <String, TextEditingController>{};
    final monthlyControllers = <String, TextEditingController>{};

    for (final tag in HealthGuardrailService.defaultTags) {
      final w = settings.weeklyLimits[tag] ?? 0.0;
      final m = settings.monthlyLimits[tag] ?? 0.0;
      weeklyControllers[tag] = TextEditingController(
        text: w <= 0 ? '' : w.toStringAsFixed(0),
      );
      monthlyControllers[tag] = TextEditingController(
        text: m <= 0 ? '' : m.toStringAsFixed(0),
      );
    }

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('건강 가드레일 설정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('과소비/중독 경고 사용'),
                    value: enabled,
                    onChanged: (v) => setDialogState(() => enabled = v),
                  ),
                  const SizedBox(height: 8),
                  for (final tag in HealthGuardrailService.defaultTags) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tag,
                        style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weeklyControllers[tag],
                            keyboardType:
                                const TextInputType.numberWithOptions(),
                            decoration: const InputDecoration(
                              labelText: '주간 한도(비우면 무제한)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: monthlyControllers[tag],
                            keyboardType:
                                const TextInputType.numberWithOptions(),
                            decoration: const InputDecoration(
                              labelText: '월간 한도(비우면 무제한)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '경고는 (태그된 품목의 사용/차감 기록) 기준입니다.',
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

    if (saved != true) {
      for (final c in weeklyControllers.values) {
        c.dispose();
      }
      for (final c in monthlyControllers.values) {
        c.dispose();
      }
      return;
    }

    double parseLimit(TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) return 0.0;
      return double.tryParse(t) ?? 0.0;
    }

    final weekly = <String, double>{};
    final monthly = <String, double>{};
    for (final tag in HealthGuardrailService.defaultTags) {
      weekly[tag] = parseLimit(weeklyControllers[tag]!);
      monthly[tag] = parseLimit(monthlyControllers[tag]!);
    }

    await HealthGuardrailService.saveSettings(
      HealthGuardrailSettings(
        enabled: enabled,
        weeklyLimits: weekly,
        monthlyLimits: monthly,
      ),
    );

    for (final c in weeklyControllers.values) {
      c.dispose();
    }
    for (final c in monthlyControllers.values) {
      c.dispose();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('건강 가드레일 설정을 저장했습니다.')));
  }
}
