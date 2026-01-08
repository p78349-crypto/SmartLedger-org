import 'package:smart_ledger/models/shopping_cart_history_entry.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/repositories/shopping_cart_repository.dart';

class FirebaseShoppingCartRepository implements ShoppingCartRepository {
  FirebaseShoppingCartRepository({required this.familyId});

  final String familyId;

  @override
  Future<List<ShoppingCartItem>> getItems({required String accountName}) async {
    // ignore: unused_local_variable
    final _ = accountName;
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }

  @override
  Future<void> setItems({
    required String accountName,
    required List<ShoppingCartItem> items,
  }) async {
    // ignore: unused_local_variable
    final _ = (accountName, items);
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }

  @override
  Future<void> clearItems({required String accountName}) async {
    // ignore: unused_local_variable
    final _ = accountName;
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }

  @override
  Future<List<ShoppingCartHistoryEntry>> getHistory({
    required String accountName,
    int limit = 200,
  }) async {
    // ignore: unused_local_variable
    final _ = (accountName, limit);
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }

  @override
  Future<void> setHistory({
    required String accountName,
    required List<ShoppingCartHistoryEntry> entries,
    int maxItems = 500,
  }) async {
    // ignore: unused_local_variable
    final _ = (accountName, entries, maxItems);
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }

  @override
  Future<void> addHistoryEntry({
    required String accountName,
    required ShoppingCartHistoryEntry entry,
    int maxItems = 500,
  }) async {
    // ignore: unused_local_variable
    final _ = (accountName, entry, maxItems);
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }

  @override
  Future<void> clearHistory({required String accountName}) async {
    // ignore: unused_local_variable
    final _ = accountName;
    throw UnsupportedError(
      'Firebase is disabled in basic mode (familyId=$familyId).',
    );
  }
}
