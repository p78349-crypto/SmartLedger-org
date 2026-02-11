part of 'backup_service.dart';

extension BackupServiceImport on BackupService {
  /// 새 계정으로 데이터 복원 (기존 데이터 보존)
  Future<void> importAccountDataAsNew(
    String jsonStr,
    String newAccountName,
  ) async {
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

    final root = _decodeBackupRootOrThrow(jsonStr);
    _validateBackupShapeOrThrow(root, requireAccountName: false);
    final data = root;

    // 새 계정 생성
    DateTime? createdAt;
    final accountJson = data['account'];
    if (accountJson is Map) {
      final rawCreatedAt = accountJson['createdAt'];
      if (rawCreatedAt is String) {
        createdAt = DateTime.tryParse(rawCreatedAt);
      }
    }

    final account = Account(name: newAccountName, createdAt: createdAt);
    final existing = AccountService().getAccountByName(newAccountName);
    if (existing != null) {
      throw Exception('이미 존재하는 계정명입니다');
    }
    await AccountService().addAccount(account);

    // Ensure the newly restored account is selected.
    await UserPrefService.setLastAccountName(newAccountName);

    // Restore backup metadata (optional).
    final backupMeta = data['backupMeta'];
    if (backupMeta is Map) {
      final rawDate = backupMeta['lastBackupDate'];
      final parsed = rawDate is String ? DateTime.tryParse(rawDate) : null;
      if (parsed != null) {
        await setLastBackupDate(newAccountName, parsed);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(PrefKeys.accountKey(newAccountName, 'lastBackup'));
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.accountKey(newAccountName, 'lastBackup'));
    }

    final monthEnd = data['monthEnd'];
    if (monthEnd is Map) {
      final carryoverAmount =
          (monthEnd['carryoverAmount'] as num?)?.toDouble() ?? 0;
      final overdraftAmount =
          (monthEnd['overdraftAmount'] as num?)?.toDouble() ?? 0;
      final rawDate = monthEnd['lastCarryoverDate'];
      final lastCarryoverDate = rawDate is String
          ? DateTime.tryParse(rawDate)
          : null;
      await AccountService().restoreMonthEndSnapshot(
        newAccountName,
        carryoverAmount: carryoverAmount,
        overdraftAmount: overdraftAmount,
        lastCarryoverDate: lastCarryoverDate,
      );
    } else {
      await AccountService().clearMonthEndSnapshot(newAccountName);
    }

    // 거래 내역 복원
    final txList = (data['transactions'] as List<dynamic>? ?? [])
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();
    for (final t in txList) {
      await TransactionService().addTransaction(newAccountName, t);
    }

    // 자산 복원
    final assetList = (data['assets'] as List<dynamic>? ?? [])
        .map((a) => Asset.fromJson(a as Map<String, dynamic>))
        .toList();
    await AssetService().replaceAssets(newAccountName, assetList);

    // 자산 이동(타임라인) 복원 (하위 호환: 키가 없으면 빈 리스트)
    final assetMoveList = (data['assetMoves'] as List<dynamic>? ?? [])
        .map((m) => AssetMove.fromJson(m as Map<String, dynamic>))
        .toList();
    await AssetMoveService().replaceMoves(newAccountName, assetMoveList);

    // 고정비 복원
    final fixedCostList = (data['fixedCosts'] as List<dynamic>? ?? [])
        .map((c) => FixedCost.fromJson(c as Map<String, dynamic>))
        .toList();
    await FixedCostService().replaceFixedCosts(newAccountName, fixedCostList);

    // 예산 복원
    final budgetValue = (data['budget'] as num?)?.toDouble() ?? 0;
    if (budgetValue > 0) {
      await BudgetService().setBudget(newAccountName, budgetValue);
    }

    // 비상금 복원 (하위 호환: 키가 없으면 빈 리스트)
    final emergencyList =
        (data['emergencyFundTransactions'] as List<dynamic>? ?? [])
            .map(
              (t) => EmergencyTransaction.fromJson(t as Map<String, dynamic>),
            )
            .toList();
    await EmergencyFundService().replaceTransactions(
      newAccountName,
      emergencyList,
    );

    final incomeSplitJson = data['incomeSplit'];
    final incomeSplit = incomeSplitJson is Map<String, dynamic>
        ? IncomeSplit.fromJson(incomeSplitJson)
        : null;
    await IncomeSplitService().replaceSplit(newAccountName, incomeSplit);

    // 예금계획 복원 (하위 호환: 키가 없으면 빈 리스트)
    final savingsPlanList = (data['savingsPlans'] as List<dynamic>? ?? [])
        .map((p) => SavingsPlan.fromJson(p as Map<String, dynamic>))
        .toList();
    await SavingsPlanService().replacePlans(newAccountName, savingsPlanList);

    // 휴지통 복원 (하위 호환: 키가 없으면 빈 리스트)
    final trashList = (data['trashEntries'] as List<dynamic>? ?? [])
        .map((e) => TrashEntry.fromJson(e as Map<String, dynamic>))
        .map((entry) {
          final updatedPayload = Map<String, dynamic>.from(entry.payload);
          if (updatedPayload.containsKey('accountName')) {
            updatedPayload['accountName'] = newAccountName;
          }
          return TrashEntry.forPayload(
            id: entry.id,
            entityId: entry.entityId,
            accountName: newAccountName,
            entityType: entry.entityType,
            payload: updatedPayload,
            deletedAt: entry.deletedAt,
          );
        })
        .toList();
    await TrashService().replaceAccountEntries(newAccountName, trashList);

    final cartItems = (data['shoppingCartItems'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ShoppingCartItem.fromJson)
        .toList(growable: false);
    await UserPrefService.setShoppingCartItems(
      accountName: newAccountName,
      items: cartItems,
    );

    final cartHistory = (data['shoppingCartHistory'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ShoppingCartHistoryEntry.fromJson)
        .toList(growable: false);
    await UserPrefService.setShoppingCartHistory(
      accountName: newAccountName,
      entries: cartHistory,
    );

    final groceryTemplateItems =
        (data['shoppingGroceryTemplateItems'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ShoppingTemplateItem.fromJson)
            .toList(growable: false);
    await UserPrefService.setShoppingGroceryTemplateItems(
      accountName: newAccountName,
      items: groceryTemplateItems,
    );

    final hintsRaw = data['shoppingCategoryHints'];
    final hints = <String, CategoryHint>{};
    if (hintsRaw is Map) {
      for (final entry in hintsRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! Map) continue;
        hints[key] = CategoryHint.fromJson(Map<String, dynamic>.from(value));
      }
    }
    await UserPrefService.setShoppingCategoryHints(
      accountName: newAccountName,
      hints: hints,
    );

    final mainPageUiPrefsSnapshot =
        data['mainPageUiPrefs'] as List<dynamic>? ?? const [];
    await UserPrefService.importMainPageUiPrefsSnapshot(
      accountName: newAccountName,
      snapshot: mainPageUiPrefsSnapshot,
    );

    final accountOptionsRaw = data['accountOptions'];
    if (accountOptionsRaw is Map) {
      await AccountOptionService.importOptions(
        newAccountName,
        Map<String, dynamic>.from(accountOptionsRaw),
      );
    } else {
      await AccountOptionService.importOptions(newAccountName, const {});
    }

    final recentInputs = data['recentInputs'];
    if (recentInputs is Map) {
      final memos = recentInputs['memos'];
      if (memos is List) {
        await RecentInputService.replaceValues(
          PrefKeys.recentMemos,
          memos.map((e) => e.toString()).toList(growable: false),
        );
      } else {
        await RecentInputService.clearValues(PrefKeys.recentMemos);
      }

      final paymentMethods = recentInputs['paymentMethods'];
      if (paymentMethods is List) {
        await RecentInputService.replaceValues(
          PrefKeys.recentPaymentMethods,
          paymentMethods.map((e) => e.toString()).toList(growable: false),
        );
      } else {
        await RecentInputService.clearValues(PrefKeys.recentPaymentMethods);
      }

      final categories = recentInputs['categories'];
      if (categories is List) {
        await RecentInputService.replaceValues(
          PrefKeys.recentCategories,
          categories.map((e) => e.toString()).toList(growable: false),
        );
      } else {
        await RecentInputService.clearValues(PrefKeys.recentCategories);
      }
    } else {
      await RecentInputService.clearValues(PrefKeys.recentMemos);
      await RecentInputService.clearValues(PrefKeys.recentPaymentMethods);
      await RecentInputService.clearValues(PrefKeys.recentCategories);
    }

    await _importFavoritesSnapshot(
      accountName: newAccountName,
      rawSnapshot: data['favorites'],
    );

    final globalSettings = data['globalSettings'];
    final gs = globalSettings is Map
        ? Map<String, dynamic>.from(globalSettings)
        : null;
    final prefs = await SharedPreferences.getInstance();
    for (final key in PrefKeys.settingKeys) {
      if (gs != null && gs.containsKey(key)) {
        final value = gs[key];
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List) {
          await prefs.setStringList(
            key,
            value.map((e) => e.toString()).toList(growable: false),
          );
        } else {
          await prefs.remove(key);
        }
      } else {
        await prefs.remove(key);
      }
    }
  }
}
