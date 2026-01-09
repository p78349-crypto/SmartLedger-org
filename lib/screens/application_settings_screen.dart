import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background_settings_screen.dart';
import 'theme_settings_screen.dart';
import '../services/activity_household_estimator_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/replacement_cycle_notification_service.dart';
import '../services/annual_household_report_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';

class ApplicationSettingsScreen extends StatefulWidget {
  const ApplicationSettingsScreen({super.key});

  @override
  State<ApplicationSettingsScreen> createState() =>
      _ApplicationSettingsScreenState();
}

class _ApplicationSettingsScreenState extends State<ApplicationSettingsScreen>
    with WidgetsBindingObserver {
  bool _hasPermissions = false;
  bool _isChecking = true;

  bool _txRecentEnabled = true;
  bool _txRecentAutofill = true;
  int _txRecentMaxCount = 30;

  int _stockAutoAddDaysFood = 3;
  int _stockAutoAddDaysHousehold = 5;
  bool _stockDepletionNotifyEnabled = true;

  final TextEditingController _foodExpiryFeedbackTemplateController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _loadTxRecentInputSettings();
    _loadStockUseSettings();
    _loadFoodExpiryFeedbackTemplate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foodExpiryFeedbackTemplateController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      _loadTxRecentInputSettings();
      _loadStockUseSettings();
      _loadFoodExpiryFeedbackTemplate();
    }
  }

  Future<void> _loadFoodExpiryFeedbackTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(PrefKeys.foodExpirySavedFeedbackTemplateV1) ?? '';
    if (!mounted) return;
    setState(() {
      _foodExpiryFeedbackTemplateController.text = t;
    });
  }

  Future<void> _saveFoodExpiryFeedbackTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final t = _foodExpiryFeedbackTemplateController.text.trim();
    if (t.isEmpty) {
      await prefs.remove(PrefKeys.foodExpirySavedFeedbackTemplateV1);
    } else {
      await prefs.setString(PrefKeys.foodExpirySavedFeedbackTemplateV1, t);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('피드백 문구 템플릿을 저장했습니다.')),
    );
  }

  Future<void> _resetFoodExpiryFeedbackTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.foodExpirySavedFeedbackTemplateV1);
    if (!mounted) return;
    setState(() {
      _foodExpiryFeedbackTemplateController.text = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('피드백 문구 템플릿을 기본값으로 되돌렸습니다.')),
    );
  }

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

  Future<void> _loadStockUseSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final vFood = prefs.getInt(PrefKeys.stockUseAutoAddDepletionDaysFoodV1);
    final vHousehold = prefs.getInt(
      PrefKeys.stockUseAutoAddDepletionDaysHouseholdV1,
    );

    final notifyEnabled = prefs.getBool(
      PrefKeys.stockUsePredictedDepletionNotifyEnabledV1,
    );

    final legacy = prefs.getInt(PrefKeys.stockUseAutoAddDepletionDaysV1);
    if (!mounted) return;
    setState(() {
      _stockAutoAddDaysFood = (vFood ?? legacy ?? 3).clamp(1, 30);
      _stockAutoAddDaysHousehold = (vHousehold ?? legacy ?? 5).clamp(1, 30);
      _stockDepletionNotifyEnabled = notifyEnabled ?? true;
    });
  }

  Future<void> _setStockDepletionNotifyEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.stockUsePredictedDepletionNotifyEnabledV1, v);
    if (!mounted) return;
    setState(() {
      _stockDepletionNotifyEnabled = v;
    });
  }

  Future<void> _setStockAutoAddDaysFood(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.stockUseAutoAddDepletionDaysFoodV1, v);
    if (!mounted) return;
    setState(() {
      _stockAutoAddDaysFood = v;
    });
  }

  Future<void> _setStockAutoAddDaysHousehold(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.stockUseAutoAddDepletionDaysHouseholdV1, v);
    if (!mounted) return;
    setState(() {
      _stockAutoAddDaysHousehold = v;
    });
  }

  Future<void> _loadTxRecentInputSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.txRecentInputsEnabledV1);
    final autofill = prefs.getBool(PrefKeys.txRecentInputsAutofillEnabledV1);
    final maxCount = prefs.getInt(PrefKeys.txRecentInputsMaxCountV1);

    if (!mounted) return;
    setState(() {
      _txRecentEnabled = enabled ?? true;
      _txRecentAutofill = autofill ?? true;
      _txRecentMaxCount = (maxCount ?? 30).clamp(1, 100);
    });
  }

  Future<void> _setTxRecentEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.txRecentInputsEnabledV1, v);
    if (!mounted) return;
    setState(() {
      _txRecentEnabled = v;
    });
  }

  Future<void> _setTxRecentAutofill(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.txRecentInputsAutofillEnabledV1, v);
    if (!mounted) return;
    setState(() {
      _txRecentAutofill = v;
    });
  }

  Future<void> _setTxRecentMaxCount(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.txRecentInputsMaxCountV1, v);
    if (!mounted) return;
    setState(() {
      _txRecentMaxCount = v;
    });
  }

  Future<void> _clearTxRecentInputs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('입력내용 삭제'),
        content: const Text('저장된 상품명/결제수단/메모 입력내용을 모두 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_descriptions', const <String>[]);
    await prefs.setStringList('recent_payments', const <String>[]);
    await prefs.setStringList('recent_memos', const <String>[]);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('저장된 입력내용을 삭제했습니다.')));
  }

  Future<void> _checkPermissions() async {
    // Android 13+ (API 33+) uses Permission.photos and Permission.notification
    // Older versions use Permission.storage
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    final notificationStatus = await Permission.notification.status;
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    final microphoneStatus = await Permission.microphone.status;

    if (mounted) {
      setState(() {
        // We consider permissions "granted" if all essential permissions
        // are granted
        _hasPermissions =
            (photosStatus.isGranted ||
                storageStatus.isGranted ||
                photosStatus.isLimited) &&
            (notificationStatus.isGranted ||
                notificationStatus.isProvisional) &&
            cameraStatus.isGranted &&
            locationStatus.isGranted &&
            microphoneStatus.isGranted;
        _isChecking = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.photos,
      Permission.storage,
      Permission.notification,
      Permission.camera,
      Permission.location,
      Permission.microphone,
    ].request();

    _checkPermissions();
  }

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
                    '팁: 달걀(0.5개/일), 쌀(예: 120g/일)처럼 “자주 쓰는 기준품목”을 넣을수록 안정적입니다.',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('애플리케이션 설정')),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                ListTile(
                  leading: const Icon(Icons.health_and_safety_outlined),
                  title: const Text('건강 가드레일'),
                  subtitle: const Text('태그 기반 과소비 경고(주/월 한도)'),
                  onTap: _showHealthGuardrailDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('교체 주기 알림'),
                  subtitle: const Text('소모품/교체형 품목의 예상 교체 시점 알림'),
                  onTap: _showReplacementCycleNotificationDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('연간 리포트(베타)'),
                  subtitle: const Text('최근 365일 차감 데이터를 요약'),
                  onTap: _showAnnualReportDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('활동 가족 수(실질 인원) 추정'),
                  subtitle: const Text('식재료 소진 데이터를 기반으로 추정'),
                  onTap: _showActiveHouseholdEstimatorDialog,
                ),
                const SizedBox(height: 8),
                if (!_hasPermissions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scheme.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: scheme.error,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '앱의 모든 기능을 사용하려면 저장소, 알림, 카메라, '
                                '위치, 마이크 권한이 필요합니다.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _requestPermissions,
                            icon: const Icon(Icons.security),
                            label: const Text('권한 허용하기'),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildSectionHeader(context, '테마'),
                AbsorbPointer(
                  absorbing: !_hasPermissions,
                  child: Opacity(
                    opacity: _hasPermissions ? 1.0 : 0.5,
                    child: Card(
                      elevation: 0,
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const ThemeSettingsSection(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '대시보드 & 배경'),
                _buildSettingsCard(
                  context,
                  icon: Icons.wallpaper_outlined,
                  title: '배경 설정',
                  subtitle: '월페이퍼, 이미지, 블러 효과를 변경합니다.',
                  enabled: _hasPermissions,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BackgroundSettingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '권한 및 시스템'),
                _buildSettingsCard(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: '기기 앱 설정 열기',
                  subtitle: '권한(알림/파일 등)은 기기 설정에서 변경합니다.',
                  onTap: () async {
                    await openAppSettings();
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '지출 입력'),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('입력내용 기억'),
                        subtitle: const Text(
                          '상품명/결제수단/메모 입력내용을 저장해 다음에 불러옵니다.',
                        ),
                        value: _txRecentEnabled,
                        onChanged: _setTxRecentEnabled,
                      ),
                      SwitchListTile(
                        title: const Text('자동 채우기'),
                        subtitle: const Text(
                          '지출입력 화면에서 결제수단/메모를 최근 값으로 미리 채웁니다.',
                        ),
                        value: _txRecentAutofill,
                        onChanged: _txRecentEnabled
                            ? _setTxRecentAutofill
                            : null,
                      ),
                      ListTile(
                        title: const Text('기억 개수'),
                        subtitle: const Text('최근 입력내용을 최대 몇 개까지 저장할지 선택합니다.'),
                        enabled: _txRecentEnabled,
                        trailing: DropdownButton<int>(
                          value: _txRecentMaxCount,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10개')),
                            DropdownMenuItem(value: 20, child: Text('20개')),
                            DropdownMenuItem(value: 30, child: Text('30개')),
                          ],
                          onChanged: !_txRecentEnabled
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  _setTxRecentMaxCount(v);
                                },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(IconCatalog.deleteOutline),
                        title: const Text('저장된 입력내용 삭제'),
                        subtitle: const Text('상품명/결제수단/메모 입력내용을 초기화합니다.'),
                        onTap: _clearTxRecentInputs,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '식료품/생활용품'),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('예상 소진 알림'),
                        subtitle: const Text('예상 소진 임박 시 로컬 알림을 표시합니다.'),
                        value: _stockDepletionNotifyEnabled,
                        onChanged: _setStockDepletionNotifyEnabled,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('예상 소진 자동 추가 기준 (식료품)'),
                        subtitle: const Text(
                          '식료품(유통기한 설정 품목)은 예상 소진 N일 전 자동으로 쇼핑준비에 추가합니다.',
                        ),
                        trailing: DropdownButton<int>(
                          value: _stockAutoAddDaysFood,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1일')),
                            DropdownMenuItem(value: 2, child: Text('2일')),
                            DropdownMenuItem(value: 3, child: Text('3일')),
                            DropdownMenuItem(value: 5, child: Text('5일')),
                            DropdownMenuItem(value: 7, child: Text('7일')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            _setStockAutoAddDaysFood(v);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('예상 소진 자동 추가 기준 (생활용품)'),
                        subtitle: const Text(
                          '생활용품(유통기한 없는 품목)은 예상 소진 N일 전 자동으로 쇼핑준비에 추가합니다.',
                        ),
                        trailing: DropdownButton<int>(
                          value: _stockAutoAddDaysHousehold,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1일')),
                            DropdownMenuItem(value: 2, child: Text('2일')),
                            DropdownMenuItem(value: 3, child: Text('3일')),
                            DropdownMenuItem(value: 5, child: Text('5일')),
                            DropdownMenuItem(value: 7, child: Text('7일')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            _setStockAutoAddDaysHousehold(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '피드백'),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '유통기한 저장 후 메시지',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '아래 템플릿이 비어있으면 기본 문구를 사용합니다.\n'
                          '치환: {item} = 품목명, {date} = 오늘/내일/모레/1월 20일',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _foodExpiryFeedbackTemplateController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: '{item} 저장 완료. 유통기한: {date}.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _resetFoodExpiryFeedbackTemplate,
                              child: const Text('기본값'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: _saveFoodExpiryFeedbackTemplate,
                              child: const Text('저장'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconCatalog.chevronRight,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
