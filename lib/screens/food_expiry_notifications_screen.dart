import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/food_expiry_item.dart';
import '../services/consumable_inventory_service.dart';
import '../services/food_expiry_notification_service.dart';
import '../utils/icon_catalog.dart';

class FoodExpiryNotificationsScreen extends StatefulWidget {
  const FoodExpiryNotificationsScreen({super.key});

  @override
  State<FoodExpiryNotificationsScreen> createState() =>
      _FoodExpiryNotificationsScreenState();
}

class _FoodExpiryNotificationsScreenState
    extends State<FoodExpiryNotificationsScreen> {
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
    final inventoryItems = ConsumableInventoryService.instance.items.value;
    // Convert ConsumableInventoryItems with expiryDate to FoodExpiryItems for notification scheduling
    final items = inventoryItems
        .where((item) => item.expiryDate != null)
        .map((item) => FoodExpiryItem(
          id: item.id,
          name: item.name,
          purchaseDate: item.purchaseDate ?? item.createdAt,
          expiryDate: item.expiryDate!,
          createdAt: item.createdAt,
          quantity: item.currentStock,
          unit: item.unit,
          category: item.category,
          location: item.location,
          price: item.price ?? 0.0,
          supplier: item.supplier ?? '',
          healthTags: item.healthTags,
        ))
        .toList();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          if (defaultTargetPlatform == TargetPlatform.android)
            ListTile(
              title: const Text('정확 알림 권한(선택)'),
              subtitle: const Text(
                '일부 기기(Android 12+)에서는 정확한 시간 알림을 위해\n'
                '시스템의 “알람 및 리마인더” 권한이 필요할 수 있습니다.',
              ),
              trailing: TextButton(
                onPressed: _saving ? null : openAppSettings,
                child: const Text('설정 열기'),
              ),
            ),
          ListTile(
            enabled: s.enabled && !_saving,
            title: const Text('며칠 전 알림'),
            subtitle: Text('현재: ${s.daysBefore}일 전'),
            trailing: DropdownButton<int>(
              value: s.daysBefore,
              items: List.generate(
                8,
                (i) => DropdownMenuItem<int>(value: i, child: Text('$i일')),
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
              '참고: 알림 권한을 거부하면 알림이 예약되지 않습니다.\n'
              '항목 추가/수정/삭제 시 알림은 자동으로 다시 예약됩니다.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
