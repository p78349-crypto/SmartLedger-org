part of transaction_service;

extension _TransactionServiceStorage on TransactionService {
  Future<void> _doLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final backend =
        (prefs.getString(PrefKeys.txStorageBackendV1) ??
                TransactionService._backendDb)
            .trim()
            .toLowerCase();

    if ((prefs.getString(PrefKeys.txStorageBackendV1) ?? '').trim().isEmpty) {
      await prefs.setString(
        PrefKeys.txStorageBackendV1,
        TransactionService._backendDb,
      );
    }

    if (backend == TransactionService._backendDb) {
      try {
        await TransactionDbMigrationService().ensureMigratedFromPrefs();
      } catch (_) {
        // Migration failures should not prevent app from starting.
      }

      _accountTransactions.clear();
      final accounts = await DatabaseProvider.instance.database
          .getAllAccounts();
      for (final account in accounts) {
        final name = account.name;
        final txs = await _dbStore.getAllTransactionsForAccount(name);
        _accountTransactions[name] = txs;
      }

      _initialized = true;
      _loading = null;
      return;
    }

    final raw = prefs.getString(TransactionService._prefsKey);
    final alreadyMigrated =
        prefs.getBool(TransactionService._storeMigrationFlagKey) ?? false;

    var needsPersist = false;
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _accountTransactions
          ..clear()
          ..addAll(
            data.map((key, value) {
              return MapEntry(
                key,
                (value as List<dynamic>).map((item) {
                  final tx = Transaction.fromJson(item as Map<String, dynamic>);
                  if (alreadyMigrated) {
                    return tx;
                  }
                  final store = tx.store?.trim() ?? '';
                  if (store.isNotEmpty) return tx;
                  final extracted = StoreMemoUtils.extractStoreKey(tx.memo);
                  if (extracted == null || extracted.trim().isEmpty) {
                    return tx;
                  }
                  needsPersist = true;
                  return tx.copyWith(store: extracted.trim());
                }).toList(),
              );
            }),
          );
      } catch (_) {
        _accountTransactions.clear();
      }
    }

    if (!alreadyMigrated) {
      await prefs.setBool(TransactionService._storeMigrationFlagKey, true);
    }

    if (needsPersist) {
      await _persistInternal();
    }

    _initialized = true;
    _loading = null;
  }

  Future<void> _persist({Future<void> Function(String backend)? dbUpsert}) {
    final scheduled = _persistChain.then(
      (_) => _persistInternal(dbUpsert: dbUpsert),
    );

    _persistChain = scheduled.then<void>(
      (_) {},
      onError: (error, stackTrace) {
        _persistChain = Future.value();
        return Future<void>.error(error, stackTrace);
      },
    );

    return scheduled;
  }

  Future<void> _persistInternal({
    Future<void> Function(String backend)? dbUpsert,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final backend =
        (prefs.getString(PrefKeys.txStorageBackendV1) ??
                TransactionService._backendDb)
            .trim()
            .toLowerCase();

    if (backend == TransactionService._backendDb) {
      if (dbUpsert != null) {
        await dbUpsert(backend);
      }

      await TransactionFtsIndexService.bumpTransactionsPersistStamp();
      return;
    }

    final data = _accountTransactions.map((key, value) {
      return MapEntry(key, value.map((t) => t.toJson()).toList());
    });
    await prefs.setString(TransactionService._prefsKey, jsonEncode(data));

    await TransactionFtsIndexService.bumpTransactionsPersistStamp();
  }
}
