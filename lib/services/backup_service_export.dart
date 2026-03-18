part of 'backup_service.dart';

extension BackupServiceExport on BackupService {
  Future<DateTime?> getLastBackupDate(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = PrefKeys.accountKey(accountName, 'lastBackup');
    final millis = prefs.getInt(key);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastBackupDate(String accountName, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = PrefKeys.accountKey(accountName, 'lastBackup');
    await prefs.setInt(key, date.millisecondsSinceEpoch);
  }

  Future<AutoBackupResult> autoBackupIfNeeded(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptionEnabled =
        prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false;
    String? encryptionPassword;
    if (encryptionEnabled) {
      encryptionPassword = await getStoredBackupEncryptionPassword();
      if (encryptionPassword == null || encryptionPassword.trim().isEmpty) {
        return AutoBackupResult.skippedEncryptionEnabled;
      }
    }

    final lastDate = await getLastBackupDate(accountName);
    final now = DateTime.now();
    final needsBackup =
        lastDate == null || now.difference(lastDate) >= const Duration(days: 1);

    if (needsBackup) {
      String? hint;
      if (encryptionPassword != null && encryptionPassword.isNotEmpty) {
        hint = generateMaskedPasswordHint(encryptionPassword);
      }

      await saveBackupToDownloads(
        accountName,
        encryptionPassword: encryptionPassword,
        passwordHint: hint,
      );
      return AutoBackupResult.performed;
    }

    return AutoBackupResult.notNeeded;
  }

  Future<String> exportAccountData(String accountName) async {
    // R3-2: WAL 체크포인트 — 백업 전 WAL 데이터를 메인 DB로 플러시
    await DatabaseProvider.instance.database.customStatement(
      'PRAGMA wal_checkpoint(TRUNCATE)',
    );
    await AccountService().loadAccounts();
    await TransactionService().loadTransactions();
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();
    await FixedCostService().loadFixedCosts();
    await BudgetService().loadBudgets();
    await EmergencyFundService().ensureLoaded();
    await IncomeSplitService().loadSplits();
    await SavingsPlanService().loadPlans();
    await TrashService().loadEntries();
    final account = AccountService().getAccountByName(accountName);
    final transactions = TransactionService().getTransactions(accountName);
    final assets = AssetService().getAssets(accountName);
    final assetMoves = AssetMoveService().getMoves(accountName);
    final fixedCosts = FixedCostService().getFixedCosts(accountName);
    final budget = BudgetService().getBudget(accountName);
    final emergencyTransactions = EmergencyFundService().getTransactions(
      accountName,
    );
    final incomeSplit = IncomeSplitService().getSplit(accountName);
    final savingsPlans = SavingsPlanService().getPlans(accountName);
    final trashEntries = TrashService().getEntries(accountName: accountName);
    // Ensure drafts are not included in backups: temporarily remove
    // per-account draft key before exporting any UserPref snapshots,
    // then restore it after assembling the export payload.
    final prefs = await SharedPreferences.getInstance();
    final draftKey = PrefKeys.accountKey(accountName, 'tx_draft_v1');
    final maybeDraftRaw = prefs.getString(draftKey);
    if (maybeDraftRaw != null) {
      await prefs.remove(draftKey);
    }

    final shoppingCartItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );
    final shoppingCartHistory = await UserPrefService.getShoppingCartHistory(
      accountName: accountName,
    );
    final shoppingGroceryTemplateItems =
        await UserPrefService.getShoppingGroceryTemplateItems(
          accountName: accountName,
        );
    final shoppingCategoryHints =
        await UserPrefService.getShoppingCategoryHints(
          accountName: accountName,
        );
    final mainPageUiPrefs = await UserPrefService.exportMainPageUiPrefsSnapshot(
      accountName: accountName,
    );
    final accountOptions = await AccountOptionService.exportOptions(
      accountName,
    );
    final recentMemos = await RecentInputService.loadMemos();
    final recentPaymentMethods = await RecentInputService.loadPaymentMethods();
    final recentCategories = await RecentInputService.loadCategories();
    final lastAccountName = await UserPrefService.getLastAccountName();
    final lastBackupDate = await getLastBackupDate(accountName);

    // prefs already obtained above; reuse it.
    final favorites = _exportFavoritesSnapshot(prefs, accountName);
    final globalSettings = <String, dynamic>{};
    for (final key in PrefKeys.settingKeys) {
      if (!prefs.containsKey(key)) continue;
      final stringValue = prefs.getString(key);
      if (stringValue != null) {
        globalSettings[key] = stringValue;
        continue;
      }
      final boolValue = prefs.getBool(key);
      if (boolValue != null) {
        globalSettings[key] = boolValue;
        continue;
      }
      final intValue = prefs.getInt(key);
      if (intValue != null) {
        globalSettings[key] = intValue;
        continue;
      }
      final doubleValue = prefs.getDouble(key);
      if (doubleValue != null) {
        globalSettings[key] = doubleValue;
        continue;
      }
      final stringListValue = prefs.getStringList(key);
      if (stringListValue != null) {
        globalSettings[key] = stringListValue;
        continue;
      }
    }

    final now = DateTime.now();
    final data = {
      'account': {
        'name': account?.name,
        'createdAt': account?.createdAt.toIso8601String(),
      },
      'monthEnd': <String, dynamic>{
        'carryoverAmount': account?.carryoverAmount ?? 0,
        'overdraftAmount': account?.overdraftAmount ?? 0,
        'lastCarryoverDate': account?.lastCarryoverDate?.toIso8601String(),
      },
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'assets': assets.map((a) => a.toJson()).toList(),
      'assetMoves': assetMoves.map((m) => m.toJson()).toList(),
      'fixedCosts': fixedCosts.map((c) => c.toJson()).toList(),
      'budget': budget,
      'emergencyFundTransactions': emergencyTransactions
          .map((t) => t.toJson())
          .toList(),
      'incomeSplit': incomeSplit?.toJson(),
      'savingsPlans': savingsPlans.map((p) => p.toJson()).toList(),
      'trashEntries': trashEntries.map((e) => e.toJson()).toList(),
      'shoppingCartItems': shoppingCartItems
          .map((i) => i.toJson())
          .toList(growable: false),
      'shoppingCartHistory': shoppingCartHistory
          .map((e) => e.toJson())
          .toList(growable: false),
      'shoppingGroceryTemplateItems': shoppingGroceryTemplateItems
          .map((i) => i.toJson())
          .toList(growable: false),
      'shoppingCategoryHints': <String, dynamic>{
        for (final e in shoppingCategoryHints.entries) e.key: e.value.toJson(),
      },
      'mainPageUiPrefs': mainPageUiPrefs,
      'accountOptions': accountOptions,
      'recentInputs': <String, dynamic>{
        'memos': recentMemos,
        'paymentMethods': recentPaymentMethods,
        'categories': recentCategories,
      },
      'favorites': favorites,
      'uiState': <String, dynamic>{'lastAccountName': lastAccountName},
      'backupMeta': <String, dynamic>{
        'lastBackupDate': lastBackupDate?.toIso8601String(),
        'exportedAt': now.toIso8601String(),
        'backupFormatVersion': _backupFormatVersion,
      },
      'globalSettings': globalSettings,
    };
    // Restore draft key if it existed before export.
    if (maybeDraftRaw != null) {
      await prefs.setString(draftKey, maybeDraftRaw);
    }

    return jsonEncode(data);
  }

  /// 지출 내역만 백업 (Transactions only - 개인정보 제거)
  /// GDPR/개인정보보호법 준수: 제3자 공유용 안전한 백업
  Future<String> exportTransactionsOnly(String accountName) async {
    await TransactionService().loadTransactions();
    await TrashService().loadEntries();

    // 지출만 필터링 (income, savings, refund 제외)
    final allTransactions = TransactionService().getTransactions(accountName);
    final transactions = allTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // 개인정보 제거: 익명화된 거래만 추출
    // GDPR Article 4: 개인식별정보 제거
    // 개인정보보호법: 민감정보 보호
    final anonymizedTransactions = transactions.map((t) {
      return {
        'id': t.id,
        'type': t.type.name,
        'amount': t.amount, // 금액만 포함 (개인식별 불가)
        'date': t.date.toIso8601String(), // 날짜 (개월 정보)
        'quantity': t.quantity, // 수량만 (가맹점명 제외)
        'unitPrice': t.unitPrice,
        'mainCategory': t.mainCategory, // 카테고리만 (구체적 상품명 제외)
        // ❌ 제외: description, memo, store, paymentMethod
        // ❌ 제외: 가맹점명, 상세정보 (개인식별정보)
      };
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final draftKey = PrefKeys.accountKey(accountName, 'tx_draft_v1');
    final maybeDraftRaw = prefs.getString(draftKey);
    if (maybeDraftRaw != null) {
      await prefs.remove(draftKey);
    }

    // ❌ 개인정보 제외:
    // - recentMemos (가맹점명, 개인기록)
    // - recentPaymentMethods (결제수단 - 민감정보)
    // - 쇼핑카트 데이터 (구매 패턴 - 민감정보)

    final now = DateTime.now();
    final data = {
      'backupType': 'transactions_only',
      'accountName': accountName,
      'transactionType': 'expense',
      'privacyLevel': 'anonymous', // GDPR/개인정보보호법 준수 표시
      'transactions': anonymizedTransactions, // 개인정보 제거됨
      'backupMeta': <String, dynamic>{
        'exportedAt': now.toIso8601String(),
        'backupFormatVersion': _backupFormatVersion,
        'privacyNotice': '이 백업은 개인식별정보를 제외하고 생성되었습니다. GDPR/개인정보보호법 준수.',
      },
    };

    if (maybeDraftRaw != null) {
      await prefs.setString(draftKey, maybeDraftRaw);
    }

    return jsonEncode(data);
  }

  /// 자산만 백업 (Assets only)
  Future<String> exportAssetsOnly(String accountName) async {
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();

    final assets = AssetService().getAssets(accountName);
    final assetMoves = AssetMoveService().getMoves(accountName);

    final now = DateTime.now();
    final data = {
      'backupType': 'assets_only',
      'accountName': accountName,
      'assets': assets.map((a) => a.toJson()).toList(),
      'assetMoves': assetMoves.map((m) => m.toJson()).toList(),
      'backupMeta': <String, dynamic>{
        'exportedAt': now.toIso8601String(),
        'backupFormatVersion': _backupFormatVersion,
      },
    };

    return jsonEncode(data);
  }

  /// WMS 재고만 백업 (생활용품 인벤토리)
  Future<String> exportWmsOnly(String accountName) async {
    await ConsumableInventoryService.instance.load();

    final items = ConsumableInventoryService.instance.items.value;

    final now = DateTime.now();
    final data = {
      'backupType': 'wms_only',
      'accountName': accountName,
      'wmsItems': items.map((item) {
        return {
          'id': item.id,
          'name': item.name,
          'category': item.category,
          'currentStock': item.currentStock,
          'unit': item.unit,
          'threshold': item.threshold,
          'bundleSize': item.bundleSize,
          'location': item.location,
          'expiryDate': item.expiryDate?.toIso8601String(),
          'lastUpdated': item.lastUpdated.toIso8601String(),
        };
      }).toList(),
      'backupMeta': <String, dynamic>{
        'exportedAt': now.toIso8601String(),
        'backupFormatVersion': _backupFormatVersion,
      },
    };

    return jsonEncode(data);
  }
}
