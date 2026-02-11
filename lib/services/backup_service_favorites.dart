part of 'backup_service.dart';

extension BackupServiceFavorites on BackupService {
  Map<String, dynamic> _exportFavoritesSnapshot(
    SharedPreferences prefs,
    String accountName,
  ) {
    final descriptions = <String, List<String>>{};
    final memos = <String, List<String>>{};
    final payments = <String, List<String>>{};

    final legacyDescriptionsKey =
        '${AppConstants.favoriteDescriptionsKeyPrefix}_$accountName';
    final legacyMemosKey =
        '${AppConstants.favoriteMemosKeyPrefix}_$accountName';
    final legacyPaymentsKey =
        '${AppConstants.favoritePaymentsKeyPrefix}_$accountName';

    for (final type in TransactionType.values) {
      final typeName = type.name;

      final descriptionsKey =
          '${AppConstants.favoriteDescriptionsKeyPrefix}_'
          '${accountName}_$typeName';
      descriptions[typeName] = _readFavoritesWithLegacyFallback(
        prefs,
        newKey: descriptionsKey,
        legacyKey: legacyDescriptionsKey,
      );

      final memosKey =
          '${AppConstants.favoriteMemosKeyPrefix}_'
          '${accountName}_$typeName';
      memos[typeName] = _readFavoritesWithLegacyFallback(
        prefs,
        newKey: memosKey,
        legacyKey: legacyMemosKey,
      );

      if (type == TransactionType.savings) {
        payments[typeName] = const <String>[];
        continue;
      }
      final paymentsKey =
          '${AppConstants.favoritePaymentsKeyPrefix}_'
          '${accountName}_$typeName';
      payments[typeName] = _readFavoritesWithLegacyFallback(
        prefs,
        newKey: paymentsKey,
        legacyKey: legacyPaymentsKey,
      );
    }

    return <String, dynamic>{
      'descriptions': descriptions,
      'memos': memos,
      'payments': payments,
    };
  }

  List<String> _readFavoritesWithLegacyFallback(
    SharedPreferences prefs, {
    required String newKey,
    required String legacyKey,
  }) {
    final current = prefs.getStringList(newKey);
    if (current != null && current.isNotEmpty) {
      return List<String>.from(current);
    }
    final legacy = prefs.getStringList(legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      return List<String>.from(legacy);
    }
    return const <String>[];
  }

  Future<void> _importFavoritesSnapshot({
    required String accountName,
    required dynamic rawSnapshot,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    Future<void> clearAll() async {
      await prefs.remove(
        '${AppConstants.favoriteDescriptionsKeyPrefix}_$accountName',
      );
      await prefs.remove('${AppConstants.favoriteMemosKeyPrefix}_$accountName');
      await prefs.remove(
        '${AppConstants.favoritePaymentsKeyPrefix}_$accountName',
      );

      for (final type in TransactionType.values) {
        final typeName = type.name;

        final descriptionsKey =
            '${AppConstants.favoriteDescriptionsKeyPrefix}_'
            '${accountName}_$typeName';
        final memosKey =
            '${AppConstants.favoriteMemosKeyPrefix}_'
            '${accountName}_$typeName';
        final paymentsKey =
            '${AppConstants.favoritePaymentsKeyPrefix}_'
            '${accountName}_$typeName';

        await prefs.remove(descriptionsKey);
        await prefs.remove(memosKey);
        await prefs.remove(paymentsKey);
      }
    }

    if (rawSnapshot is! Map) {
      await clearAll();
      return;
    }

    final snapshot = Map<String, dynamic>.from(rawSnapshot);
    final rawDescriptions = snapshot['descriptions'];
    final rawMemos = snapshot['memos'];
    final rawPayments = snapshot['payments'];

    List<String> readListFrom(dynamic mapLike, String typeName) {
      if (mapLike is! Map) return const <String>[];
      final value = mapLike[typeName];
      if (value is! List) return const <String>[];
      return value.map((e) => e.toString()).toList(growable: false);
    }

    // Always remove legacy keys; we only restore the per-type keys.
    await prefs.remove(
      '${AppConstants.favoriteDescriptionsKeyPrefix}_$accountName',
    );
    await prefs.remove('${AppConstants.favoriteMemosKeyPrefix}_$accountName');
    await prefs.remove(
      '${AppConstants.favoritePaymentsKeyPrefix}_$accountName',
    );

    for (final type in TransactionType.values) {
      final typeName = type.name;

      final descriptionsKey =
          '${AppConstants.favoriteDescriptionsKeyPrefix}_'
          '${accountName}_$typeName';
      final memosKey =
          '${AppConstants.favoriteMemosKeyPrefix}_'
          '${accountName}_$typeName';
      final paymentsKey =
          '${AppConstants.favoritePaymentsKeyPrefix}_'
          '${accountName}_$typeName';

      final descriptions = readListFrom(rawDescriptions, typeName);
      final memos = readListFrom(rawMemos, typeName);
      final payments = readListFrom(rawPayments, typeName);

      if (descriptions.isEmpty) {
        await prefs.remove(descriptionsKey);
      } else {
        await prefs.setStringList(descriptionsKey, descriptions);
      }

      if (memos.isEmpty) {
        await prefs.remove(memosKey);
      } else {
        await prefs.setStringList(memosKey, memos);
      }

      if (type == TransactionType.savings || payments.isEmpty) {
        await prefs.remove(paymentsKey);
      } else {
        await prefs.setStringList(paymentsKey, payments);
      }
    }
  }
}
