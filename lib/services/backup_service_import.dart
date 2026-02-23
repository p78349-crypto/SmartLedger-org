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
      // NOTE: 보안 관리자 규정 - 백업의 레거시 비밀번호는 사용하지 않음
      // 복원된 계정은 비밀번호 보호 없이 생성되며, 사용자가 필요시 새로 설정 가능
    }

    final account = Account(
      name: newAccountName, 
      createdAt: createdAt,
    );
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

    // 거래 내역 복현
    final backupType = data['backupType'] as String? ?? 'full';
    final transactionType = data['transactionType'] as String? ?? 'all';
    final privacyLevel = data['privacyLevel'] as String?;  // 'anonymous' = 개인정보 제거됨
    
    // WMS 전용 백업인 경우 조기 반환
    if (backupType == 'wms_only') {
      // WMS 데이터만 복원
      final wmsItems = data['wmsItems'] as List<dynamic>? ?? [];
      for (final itemJson in wmsItems) {
        final item = ConsumableInventoryItem.fromJson(itemJson as Map<String, dynamic>);
        await ConsumableInventoryService.instance.addOrUpdateItem(item);
      }
      
      // 감사 로그: WMS 백업 복원
      await _recordRestoreAuditLog(newAccountName, action: 'import_wms_only');
      return;  // 다른 데이터는 복원하지 않음
    }
    
    List<Transaction> txList = (data['transactions'] as List<dynamic>? ?? [])
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();
    
    // 지출 백업: expense type만 필터링
    if (backupType == 'transactions_only' && transactionType == 'expense') {
      txList = txList.where((t) => t.type == TransactionType.expense).toList();
      
      // 개인정보 제거 백업임을 사용자에게 알림
      if (privacyLevel == 'anonymous') {
        // 개인식별정보가 제거된 백업임을 기록
        final prefs = await SharedPreferences.getInstance();
        final key = PrefKeys.accountKey(newAccountName, 'backup_anonymized');
        await prefs.setBool(key, true);
      }
    }
    
    for (final t in txList) {
      await TransactionService().addTransaction(newAccountName, t);
    }

    // 자산 복원 (백업 타입 확인)
    if (backupType != 'transactions_only') {  // 지출만 백업이 아니면 자산 복원
      final assetList = (data['assets'] as List<dynamic>? ?? [])
          .map((a) => Asset.fromJson(a as Map<String, dynamic>))
          .toList();
      await AssetService().replaceAssets(newAccountName, assetList);

      // 자산 이동(타임라인) 복원
      final assetMoveList = (data['assetMoves'] as List<dynamic>? ?? [])
          .map((m) => AssetMove.fromJson(m as Map<String, dynamic>))
          .toList();
      await AssetMoveService().replaceMoves(newAccountName, assetMoveList);
    }

    // 고정비, 예산, 비상금, 소득분배는 전체 백업일 때만 복원
    if (backupType == 'full') {
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

      // 비상금 복원
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

      // 예금계획 복원
      final savingsPlanList = (data['savingsPlans'] as List<dynamic>? ?? [])
          .map((p) => SavingsPlan.fromJson(p as Map<String, dynamic>))
          .toList();
      await SavingsPlanService().replacePlans(newAccountName, savingsPlanList);
    }

    // 휴지통 복원 (백업 타입에 따라 필터링)
    final allTrashList = (data['trashEntries'] as List<dynamic>? ?? [])
        .map((e) => TrashEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    
    List<TrashEntry> trashList = allTrashList;
    if (backupType == 'transactions_only') {
      // 지출 백업: 거래 관련 휴지통만
      trashList = trashList
          .where((e) => e.entityType == TrashEntityType.transaction)
          .toList();
    } else if (backupType == 'assets_only') {
      // 자산 백업: 자산 관련 휴지통만
      trashList = trashList
          .where((e) => e.entityType == TrashEntityType.asset)
          .toList();
    }
    
    final processedTrashList = trashList
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
    await TrashService().replaceAccountEntries(newAccountName, processedTrashList);

    // 쇼핑카트 데이터 복원 (지출 백업 또는 전체 백업일 때만)
    if (backupType != 'assets_only') {
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
    }

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

    // 글로벌 보안 규정: 복원 이력 기록 (감시 로그)
    await _recordRestoreAuditLog(newAccountName);
    
    // 글로벌 보안 규정: 복원된 계정 재인증 필요 플래그 설정
    await _markAccountNeedsReauth(newAccountName);
  }

  /// 복원 이력을 감시 로그에 기록 (GDPR/ISO27001 감사추적)
  Future<void> _recordRestoreAuditLog(
    String restoredAccountName, {
    String action = 'account_restored',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 기존 로그 읽기
    final logJson = prefs.getString(PrefKeys.restoreAuditLog) ?? '[]';
    final List<dynamic> logs = json.decode(logJson) ?? [];
    
    // 새 복원 기록 추가
    logs.add({
      'timestamp': DateTime.now().toIso8601String(),
      'accountName': restoredAccountName,
      'action': action,
      'requiresReauth': true,
    });
    
    // 최근 100개 이력만 유지 (저장소 효율성)
    final trimmedLogs = logs.length > 100
        ? logs.sublist(logs.length - 100)
        : logs;
    
    // 로그 저장
    await prefs.setString(
      PrefKeys.restoreAuditLog,
      json.encode(trimmedLogs),
    );
  }

  /// 복원된 계정에 재인증 필요 플래그 추가 (글로벌 규정: 복원 후 재인증)
  Future<void> _markAccountNeedsReauth(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 재인증 필요 계정 목록 읽기
    final reauthJson = prefs.getString(PrefKeys.restoredAccountsNeedReauth) ?? '[]';
    final List<String> reauthAccounts = 
        (json.decode(reauthJson) as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
    
    // 아직 없으면 추가
    if (!reauthAccounts.contains(accountName)) {
      reauthAccounts.add(accountName);
      await prefs.setString(
        PrefKeys.restoredAccountsNeedReauth,
        json.encode(reauthAccounts),
      );
    }
  }
}
