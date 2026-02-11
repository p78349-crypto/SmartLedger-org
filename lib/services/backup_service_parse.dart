part of 'backup_service.dart';

extension BackupServiceParse on BackupService {
  BackupPreview parseBackupPreview(String jsonStr) {
    final root = _decodeBackupRootOrThrow(jsonStr);
    _validateBackupShapeOrThrow(root, requireAccountName: false);

    String? sourceAccountName;
    final account = root['account'];
    if (account is Map) {
      final name = account['name'];
      if (name is String && name.trim().isNotEmpty) {
        sourceAccountName = name.trim();
      }
    }

    DateTime? exportedAt;
    DateTime? lastBackupDate;
    final backupMeta = root['backupMeta'];
    if (backupMeta is Map) {
      final rawExportedAt = backupMeta['exportedAt'];
      final rawLastBackupDate = backupMeta['lastBackupDate'];
      if (rawExportedAt is String) {
        exportedAt = DateTime.tryParse(rawExportedAt);
      }
      if (rawLastBackupDate is String) {
        lastBackupDate = DateTime.tryParse(rawLastBackupDate);
      }
    }

    int countList(String key) {
      final value = root[key];
      return value is List ? value.length : 0;
    }

    return BackupPreview(
      sourceAccountName: sourceAccountName,
      exportedAt: exportedAt,
      lastBackupDate: lastBackupDate,
      transactionCount: countList('transactions'),
      assetCount: countList('assets'),
      fixedCostCount: countList('fixedCosts'),
      shoppingCartItemCount: countList('shoppingCartItems'),
      savingsPlanCount: countList('savingsPlans'),
    );
  }

  Map<String, dynamic> _decodeBackupRootOrThrow(String jsonStr) {
    dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (e) {
      throw Exception('백업 파일이 JSON 형식이 아닙니다: $e');
    }
    if (decoded is! Map) {
      throw Exception('백업 파일 형식이 올바르지 않습니다(최상위가 객체가 아님)');
    }
    return Map<String, dynamic>.from(decoded);
  }

  void _validateBackupShapeOrThrow(
    Map<String, dynamic> data, {
    required bool requireAccountName,
  }) {
    bool isValidListOrAbsent(String key) {
      if (!data.containsKey(key)) return true;
      final value = data[key];
      return value == null || value is List;
    }

    bool isValidMapOrAbsent(String key) {
      if (!data.containsKey(key)) return true;
      final value = data[key];
      return value == null || value is Map;
    }

    // Keys we read as lists.
    const listKeys = <String>[
      'transactions',
      'assets',
      'assetMoves',
      'fixedCosts',
      'emergencyFundTransactions',
      'savingsPlans',
      'trashEntries',
      'shoppingCartItems',
      'shoppingCartHistory',
      'shoppingGroceryTemplateItems',
      'mainPageUiPrefs',
    ];
    for (final key in listKeys) {
      if (!isValidListOrAbsent(key)) {
        throw Exception('백업 파일 형식이 올바르지 않습니다: $key');
      }
    }

    // Keys we read as maps.
    const mapKeys = <String>[
      'account',
      'monthEnd',
      'incomeSplit',
      'backupMeta',
      'globalSettings',
      'favorites',
      'recentInputs',
      'uiState',
      'shoppingCategoryHints',
      'accountOptions',
    ];
    for (final key in mapKeys) {
      if (!isValidMapOrAbsent(key)) {
        throw Exception('백업 파일 형식이 올바르지 않습니다: $key');
      }
    }

    // Ensure this looks like *our* backup, not random JSON.
    final hasAnySignature =
        data.containsKey('transactions') ||
        data.containsKey('assets') ||
        data.containsKey('fixedCosts') ||
        data.containsKey('backupMeta') ||
        data.containsKey('shoppingCartItems');
    if (!hasAnySignature) {
      throw Exception('이 파일은 백업 파일이 아닐 수 있습니다(필수 섹션 누락)');
    }

    if (requireAccountName) {
      final account = data['account'];
      if (account is! Map) {
        throw Exception('백업 파일에 account 정보가 없습니다');
      }
      final name = account['name'];
      if (name is! String || name.trim().isEmpty) {
        throw Exception('백업 파일에 account.name 정보가 없습니다');
      }
    }
  }
}
