import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/screens/settings_screen.dart';
import 'package:smart_ledger/services/food_expiry_notification_service.dart';
import 'package:smart_ledger/services/food_expiry_prediction_engine.dart';
import 'package:smart_ledger/services/food_expiry_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/interaction_blockers.dart';

/// 식품 유통기한 관리 전용 메인 네비게이션 화면
class FoodExpiryMainScreen extends StatefulWidget {
  const FoodExpiryMainScreen({super.key});

  @override
  State<FoodExpiryMainScreen> createState() => _FoodExpiryMainScreenState();
}

class _FoodExpiryMainScreenState extends State<FoodExpiryMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    FoodExpiryService.instance.load();
  }

  late final List<Widget> _screens = <Widget>[
    const _FoodExpiryItemsScreen(),
    const _FoodExpiryNotificationsScreen(),
    const _FoodExpiryPlaceholderScreen(title: '소비 기록'),
    const _FoodExpiryPlaceholderScreen(title: '통계'),
    const _FoodExpiryPlaceholderScreen(title: '구매-환불'),
    const SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(IconCatalog.shoppingCart),
      label: '상품 관리',
    ),
    BottomNavigationBarItem(icon: Icon(IconCatalog.warningAmber), label: '알림'),
    BottomNavigationBarItem(icon: Icon(IconCatalog.history), label: '소비 기록'),
    BottomNavigationBarItem(icon: Icon(IconCatalog.barChart), label: '통계'),
    BottomNavigationBarItem(
      icon: Icon(IconCatalog.receiptLong),
      label: '구매-환불',
    ),
    BottomNavigationBarItem(icon: Icon(IconCatalog.settings), label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: InteractionBlockers.gateValue<int>((index) {
          setState(() {
            _currentIndex = index;
          });
        }),
        items: _navItems,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class _FoodExpiryPlaceholderScreen extends StatelessWidget {
  final String title;

  const _FoodExpiryPlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title 화면은 준비 중입니다.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _FoodExpiryItemsScreen extends StatelessWidget {
  const _FoodExpiryItemsScreen();

  Future<void> _openUpsertDialog(
    BuildContext context, {
    FoodExpiryItem? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final memoController = TextEditingController(text: existing?.memo ?? '');
    final now = DateTime.now();
    var purchaseDate = existing?.purchaseDate ?? now;
    DateTime? picked = existing?.expiryDate;

    FoodExpiryPrediction? prediction() {
      return FoodExpiryPredictionEngine.predict(
        name: nameController.text,
        memo: memoController.text,
        purchaseDate: purchaseDate,
      );
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final p = prediction();
          final suggestedText = p == null
              ? null
              : '${DateFormat('yyyy-MM-dd').format(p.suggestedExpiryDate)} '
                  '(+${p.adjustedDays}일, ${p.category})';

          String riskLabel(FoodExpiryRisk r) {
            switch (r) {
              case FoodExpiryRisk.safe:
                return 'Safe';
              case FoodExpiryRisk.caution:
                return 'Caution';
              case FoodExpiryRisk.danger:
                return 'Danger';
              case FoodExpiryRisk.stable:
                return 'Stable';
            }
          }

          Color riskColor(ThemeData theme, FoodExpiryRisk r) {
            switch (r) {
              case FoodExpiryRisk.danger:
                return theme.colorScheme.error;
              case FoodExpiryRisk.caution:
                return theme.colorScheme.tertiary;
              case FoodExpiryRisk.safe:
              case FoodExpiryRisk.stable:
                return theme.colorScheme.primary;
            }
          }

          return AlertDialog(
            title: Text(existing == null ? '유통기한 추가' : '유통기한 수정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '상품명',
                      hintText: '예: 우유, 계란, 두부',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: memoController,
                    decoration: const InputDecoration(
                      labelText: '메모(선택)',
                      hintText: '예: 냉동 / 임박 / 마감세일',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '구매일: ${DateFormat('yyyy-MM-dd').format(purchaseDate)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: purchaseDate,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (d == null) return;
                          setState(() {
                            purchaseDate = d;
                          });
                        },
                        child: const Text('변경'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (p != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'AI Prediction',
                                  style: Theme.of(ctx).textTheme.titleSmall,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  riskLabel(p.risk),
                                  style: TextStyle(
                                    color: riskColor(Theme.of(ctx), p.risk),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(suggestedText ?? ''),
                            const SizedBox(height: 6),
                            ...p.reasons.take(3).map(
                                  (e) => Text(
                                    '• $e',
                                    style: Theme.of(ctx).textTheme.bodySmall,
                                  ),
                                ),
                            const SizedBox(height: 8),
                            Text(
                              '중요: 이 예측은 “구매일 기준”이라 실제와 다를 수 있습니다.\n등록 전 반드시 확인/수정해주세요.',
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '알림은 “저장된 유통기한 날짜” 기준으로 예약되며, 항목 수정 시 자동으로 갱신됩니다.',
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          picked == null
                              ? (p == null
                                  ? '유통기한 날짜 선택'
                                  : '유통기한(예측): ${DateFormat('yyyy-MM-dd').format(p.suggestedExpiryDate)}')
                              : '유통기한(수동): ${DateFormat('yyyy-MM-dd').format(picked!)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: picked ?? p?.suggestedExpiryDate ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (d != null) {
                            setState(() {
                              picked = d;
                            });
                          }
                        },
                        child: const Text('직접 선택'),
                      ),
                      if (p != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              picked = p.suggestedExpiryDate;
                            });
                          },
                          child: const Text('예측 적용'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(ctx).pop,
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final effective = picked ?? p?.suggestedExpiryDate;
                  if (name.isEmpty || effective == null) {
                    Navigator.of(ctx).pop(false);
                    return;
                  }
                  Navigator.of(ctx).pop(true);
                },
                child: Text(existing == null ? '이대로 등록' : '저장'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final p = prediction();
      final effective = picked ?? p?.suggestedExpiryDate;
      if (name.isEmpty || effective == null) return;

      if (existing == null) {
        await FoodExpiryService.instance.addItem(
          name: name,
          purchaseDate: purchaseDate,
          expiryDate: effective,
          memo: memoController.text,
        );
      } else {
        await FoodExpiryService.instance.updateItem(
          id: existing.id,
          name: name,
          purchaseDate: purchaseDate,
          expiryDate: effective,
          memo: memoController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('유통기한 관리'),
        actions: [
          IconButton(
            onPressed: FoodExpiryService.instance.load,
            icon: const Icon(IconCatalog.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<FoodExpiryItem>>(
        valueListenable: FoodExpiryService.instance.items,
        builder: (context, items, child) {
          final content = items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '등록된 유통기한 항목이 없습니다.\n하단 버튼으로 추가하세요.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        final left = it.daysLeft(now);
                        final leftText =
                            left < 0 ? '지남 ${-left}일' : '남음 $left' '일';
                        final color = left < 0
                            ? theme.colorScheme.error
                            : (left <= 2
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.primary);
                        return ListTile(
                          title: Text(
                            it.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            it.memo.trim().isEmpty
                                ? '구매일: ${DateFormat('yyyy-MM-dd').format(it.purchaseDate)}  /  유통기한: ${DateFormat('yyyy-MM-dd').format(it.expiryDate)}'
                                : '구매일: ${DateFormat('yyyy-MM-dd').format(it.purchaseDate)}  /  유통기한: ${DateFormat('yyyy-MM-dd').format(it.expiryDate)}\n메모: ${it.memo.trim()}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () =>
                              _openUpsertDialog(context, existing: it),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(leftText, style: TextStyle(color: color)),
                              IconButton(
                                icon: const Icon(IconCatalog.deleteOutline),
                                tooltip: '삭제',
                                onPressed: () =>
                                    FoodExpiryService.instance.deleteById(it.id),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );

          return Stack(
            children: [
              Positioned.fill(child: content),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openUpsertDialog(context),
                        icon: const Icon(IconCatalog.addCircle),
                        label: const Text('유통기한 추가'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FoodExpiryNotificationsScreen extends StatefulWidget {
  const _FoodExpiryNotificationsScreen();

  @override
  State<_FoodExpiryNotificationsScreen> createState() =>
      _FoodExpiryNotificationsScreenState();
}

class _FoodExpiryNotificationsScreenState
    extends State<_FoodExpiryNotificationsScreen> {
  FoodExpiryNotificationSettings? _settings;
  int? _lastScheduledCount;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await FoodExpiryNotificationService.instance.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = s;
    });
    await _reschedule();
  }

  Future<void> _update(FoodExpiryNotificationSettings next) async {
    setState(() {
      _settings = next;
      _saving = true;
    });
    await FoodExpiryNotificationService.instance.saveSettings(next);
    await _reschedule();
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
  }

  Future<void> _reschedule() async {
    final items = FoodExpiryService.instance.items.value;
    final count = await FoodExpiryNotificationService.instance
        .rescheduleFromPrefs(items);
    if (!mounted) return;
    setState(() {
      _lastScheduledCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _settings;

    if (s == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('유통기한 알림'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _load,
            icon: const Icon(IconCatalog.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('알림 사용'),
            subtitle: const Text('유통기한 임박 시 로컬 알림을 표시합니다.'),
            value: s.enabled,
            onChanged: _saving ? null : (v) => _update(s.copyWith(enabled: v)),
          ),
          ListTile(
            enabled: s.enabled && !_saving,
            title: const Text('며칠 전 알림'),
            subtitle: Text('현재: ${s.daysBefore}일 전'),
            trailing: DropdownButton<int>(
              value: s.daysBefore,
              items: List.generate(
                8,
                (i) => DropdownMenuItem<int>(
                  value: i,
                  child: Text('$i일'),
                ),
              ),
              onChanged: (!s.enabled || _saving)
                  ? null
                  : (v) {
                      if (v == null) return;
                      _update(s.copyWith(daysBefore: v));
                    },
            ),
          ),
          ListTile(
            enabled: s.enabled && !_saving,
            title: const Text('알림 시각'),
            subtitle: Text(s.time.format(context)),
            trailing: const Icon(IconCatalog.chevronRight),
            onTap: (!s.enabled || _saving)
                ? null
                : () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: s.time,
                    );
                    if (picked == null) return;
                    await _update(s.copyWith(time: picked));
                  },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _lastScheduledCount == null
                  ? '스케줄을 계산 중입니다.'
                  : s.enabled
                      ? '예약된 알림: $_lastScheduledCount건'
                      : '알림이 꺼져 있어 예약된 알림이 없습니다.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '참고: 알림 권한을 거부하면 알림이 예약되지 않습니다.\n항목 추가/수정/삭제 시 알림은 자동으로 다시 예약됩니다.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

