import '../../models/consumable_inventory_item.dart';
import '../consumable_inventory_repository.dart';

class FirebaseConsumableInventoryRepository
    implements ConsumableInventoryRepository {
  FirebaseConsumableInventoryRepository({required this.familyId});

  final String familyId;

  @override
  Future<List<ConsumableInventoryItem>> loadItems() async {
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }

  @override
  Future<void> saveItems(List<ConsumableInventoryItem> items) async {
    // ignore: unused_local_variable
    final _ = items;
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }
}
