import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/repositories/app_repositories.dart';
import 'package:smart_ledger/repositories/consumable_inventory_repository.dart';
import 'package:smart_ledger/services/consumable_inventory_service.dart';

class _InMemoryConsumableInventoryRepository
    implements ConsumableInventoryRepository {
  List<ConsumableInventoryItem> _items = <ConsumableInventoryItem>[];

  @override
  Future<List<ConsumableInventoryItem>> loadItems() async =>
      List<ConsumableInventoryItem>.from(_items);

  @override
  Future<void> saveItems(List<ConsumableInventoryItem> items) async {
    _items = List<ConsumableInventoryItem>.from(items);
  }
}

ConsumableInventoryItem _buildItem({
  required String id,
  required double currentStock,
}) {
  final now = DateTime(2026, 2, 14);
  return ConsumableInventoryItem(
    id: id,
    name: '테스트품목',
    currentStock: currentStock,
    unit: '개',
    createdAt: now,
    lastUpdated: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConsumableInventoryRepository originalRepository;
  final service = ConsumableInventoryService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    originalRepository = AppRepositories.consumableInventory;
    AppRepositories.consumableInventory =
        _InMemoryConsumableInventoryRepository();
    service.items.value = <ConsumableInventoryItem>[];
  });

  tearDown(() {
    AppRepositories.consumableInventory = originalRepository;
    service.items.value = <ConsumableInventoryItem>[];
  });

  test('useItem with zero does not change stock/history', () async {
    await service.addOrUpdateItem(_buildItem(id: 'item-1', currentStock: 8));

    await service.useItem('item-1', 0);

    expect(service.items.value.single.currentStock, 8);
    expect(service.items.value.single.usageHistory, isEmpty);
  });

  test('useItem with negative value does not change stock/history', () async {
    await service.addOrUpdateItem(_buildItem(id: 'item-1', currentStock: 8));

    await service.useItem('item-1', -2);

    expect(service.items.value.single.currentStock, 8);
    expect(service.items.value.single.usageHistory, isEmpty);
  });

  test('useItem over stock clamps to actual used amount', () async {
    await service.addOrUpdateItem(_buildItem(id: 'item-1', currentStock: 5));

    await service.useItem('item-1', 9);

    final item = service.items.value.single;
    expect(item.currentStock, 0);
    expect(item.usageHistory.length, 1);
    expect(item.usageHistory.single.amount, 5);
  });

  test('multiple useItem calls accumulate usage history', () async {
    await service.addOrUpdateItem(_buildItem(id: 'item-1', currentStock: 20));

    await service.useItem('item-1', 3);
    await service.useItem('item-1', 5);
    await service.useItem('item-1', 2);

    final item = service.items.value.single;
    expect(item.currentStock, 10);
    expect(item.usageHistory.length, 3);
    expect(item.usageHistory[0].amount, 3);
    expect(item.usageHistory[1].amount, 5);
    expect(item.usageHistory[2].amount, 2);
  });

  test('useItem with extreme over-usage clamps correctly', () async {
    await service.addOrUpdateItem(_buildItem(id: 'item-1', currentStock: 2.5));

    await service.useItem('item-1', 1000);

    final item = service.items.value.single;
    expect(item.currentStock, 0);
    expect(item.usageHistory.length, 1);
    expect(item.usageHistory.single.amount, 2.5);
  });

  test('useItem with fractional usage amount', () async {
    await service.addOrUpdateItem(_buildItem(id: 'item-1', currentStock: 10.0));

    await service.useItem('item-1', 3.5);

    final item = service.items.value.single;
    expect(item.currentStock, 6.5);
    expect(item.usageHistory.length, 1);
    expect(item.usageHistory.single.amount, 3.5);
  });

  test('useItem exactly matching stock depletes to zero', () async {
    await service.addOrUpdateItem(_buildItem(id: 'item-1', currentStock: 7.0));

    await service.useItem('item-1', 7.0);

    final item = service.items.value.single;
    expect(item.currentStock, 0);
    expect(item.usageHistory.length, 1);
    expect(item.usageHistory.single.amount, 7.0);
  });
}
