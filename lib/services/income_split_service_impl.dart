part of income_split_service;

/// 수입 배분 관리 서비스
class IncomeSplitService {
  static final IncomeSplitService _instance = IncomeSplitService._internal();
  factory IncomeSplitService() => _instance;
  IncomeSplitService._internal();

  final Map<String, IncomeSplit> _splits = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Stream that notifies when splits are added/updated/removed.
  Stream<void> get onChange => _changes.stream;

  Future<void> loadSplits() async {
    try {
      // Rationale: locating the app documents directory requires platform
      // access and runs asynchronously to avoid blocking the UI thread.
      // ignore: avoid_slow_async_io
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/income_splits.json');

      // Rationale: checking for file existence performs small IO.
      // ignore: avoid_slow_async_io
      if (await file.exists()) {
        // Rationale: reading the JSON file is async; content is expected
        // to be small and avoids UI jank.
        // ignore: avoid_slow_async_io
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content) as List;
        _splits.clear();
        for (final json in jsonList) {
          final split = IncomeSplit.fromJson(json as Map<String, dynamic>);
          _splits[split.accountName] = split;
        }

        _changes.add(null);
      }
    } catch (e) {
      // 수입 배분 로드 실패: 로그로 남기지 않음(프로덕션용)
    }
  }

  Future<void> saveSplits() async {
    try {
      // Rationale: persisting configuration uses async IO to avoid
      // blocking the UI thread.
      // ignore: avoid_slow_async_io
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/income_splits.json');
      final jsonList = _splits.values.map((s) => s.toJson()).toList();

      // Rationale: writing small JSON settings asynchronously avoids UI
      // blocking and is acceptable for expected file sizes.
      // ignore: avoid_slow_async_io
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      // 수입 배분 저장 실패: 로그로 남기지 않음(프로덕션용)
    }
  }

  IncomeSplit? getSplit(String accountName) {
    return _splits[accountName];
  }

  Future<void> deleteAccount(String accountName) async {
    await loadSplits();
    final removed = _splits.remove(accountName) != null;
    if (!removed) return;
    await saveSplits();
    _changes.add(null);
  }

  Future<void> setSplit({
    required String accountName,
    required List<IncomeItem> incomeItems,
    required double savingsAmount,
    required double budgetAmount,
    required double emergencyAmount,
    double assetTransferAmount = 0,
    Map<String, double> categoryBudgets = const {},
    bool persistToStorage = true,
    bool createAssetMoves = true,
  }) async {
    _splits[accountName] = IncomeSplit(
      accountName: accountName,
      incomeItems: incomeItems,
      savingsAmount: savingsAmount,
      budgetAmount: budgetAmount,
      emergencyAmount: emergencyAmount,
      assetTransferAmount: assetTransferAmount,
      categoryBudgets: categoryBudgets,
    );

    if (persistToStorage) {
      await saveSplits();
    }

    _changes.add(null);

    if (createAssetMoves) {
      await _createAssetMovesForDistribution(
        accountName,
        incomeItems,
        savingsAmount,
        budgetAmount,
        emergencyAmount,
        assetTransferAmount,
      );
    }
  }

  /// 수입 분배의 각 항목을 AssetMove로 기록
  Future<void> _createAssetMovesForDistribution(
    String accountName,
    List<IncomeItem> incomeItems,
    double savingsAmount,
    double budgetAmount,
    double emergencyAmount,
    double assetTransferAmount,
  ) async {
    return _createAssetMovesForIncomeDistribution(
      accountName: accountName,
      incomeItems: incomeItems,
      savingsAmount: savingsAmount,
      budgetAmount: budgetAmount,
      emergencyAmount: emergencyAmount,
      assetTransferAmount: assetTransferAmount,
    );
  }

  Future<void> deleteSplit(String accountName) async {
    _splits.remove(accountName);
    await saveSplits();
    _changes.add(null);
  }

  /// Replace (or remove) a single account's split configuration.
  ///
  /// This is intended for backup/restore flows and MUST NOT create AssetMove
  /// records or mutate assets.
  Future<void> replaceSplit(String accountName, IncomeSplit? split) async {
    await loadSplits();

    if (split == null) {
      _splits.remove(accountName);
      await saveSplits();
      _changes.add(null);
      return;
    }

    _splits[accountName] = IncomeSplit(
      accountName: accountName,
      incomeItems: List<IncomeItem>.from(split.incomeItems),
      savingsAmount: split.savingsAmount,
      budgetAmount: split.budgetAmount,
      emergencyAmount: split.emergencyAmount,
      assetTransferAmount: split.assetTransferAmount,
      categoryBudgets: Map<String, double>.from(split.categoryBudgets),
    );
    await saveSplits();
    _changes.add(null);
  }
}
