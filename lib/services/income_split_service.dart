import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/asset_move.dart';
import 'package:smart_ledger/services/asset_move_service.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/utils/date_formatter.dart';

/// 수입 항목
class IncomeItem {
  final String id;
  final String name; // 급여, 보너스, 부업 등
  final double amount;
  final String category; // salary, bonus, sideincome, other

  IncomeItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'amount': amount, 'category': category};
  }

  factory IncomeItem.fromJson(Map<String, dynamic> json) {
    return IncomeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
    );
  }
}

/// 수입 배분 설정 (예금/예산/비상금)
class IncomeSplit {
  final String accountName;
  final List<IncomeItem> incomeItems; // 급여, 보너스 등 수입 항목들
  final double savingsAmount;
  final double budgetAmount;
  final double emergencyAmount;
  final double assetTransferAmount;
  final Map<String, double> categoryBudgets;

  IncomeSplit({
    required this.accountName,
    required this.incomeItems,
    required this.savingsAmount,
    required this.budgetAmount,
    required this.emergencyAmount,
    required this.assetTransferAmount,
    Map<String, double>? categoryBudgets,
  }) : categoryBudgets = categoryBudgets ?? <String, double>{};

  double get totalIncome =>
      incomeItems.fold(0, (sum, item) => sum + item.amount);

  double get categoryBudgetTotal =>
      categoryBudgets.values.fold(0, (sum, amount) => sum + amount);

  Map<String, dynamic> toJson() {
    return {
      'accountName': accountName,
      'incomeItems': incomeItems.map((item) => item.toJson()).toList(),
      'savingsAmount': savingsAmount,
      'budgetAmount': budgetAmount,
      'emergencyAmount': emergencyAmount,
      'assetTransferAmount': assetTransferAmount,
      'categoryBudgets': categoryBudgets,
    };
  }

  factory IncomeSplit.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['incomeItems'] as List<dynamic>?;
    final items = itemsJson != null
        ? itemsJson
              .map((item) => IncomeItem.fromJson(item as Map<String, dynamic>))
              .toList()
        : <IncomeItem>[];

    return IncomeSplit(
      accountName: json['accountName'] as String,
      incomeItems: items,
      savingsAmount: (json['savingsAmount'] as num?)?.toDouble() ?? 0,
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0,
      emergencyAmount: (json['emergencyAmount'] as num?)?.toDouble() ?? 0,
      assetTransferAmount:
          (json['assetTransferAmount'] as num?)?.toDouble() ?? 0,
      categoryBudgets:
          (json['categoryBudgets'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          <String, double>{},
    );
  }
}

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
      // Rationale: Locating the app documents directory requires platform
      // access and runs asynchronously; doing so here prevents blocking the
      // main UI thread during a small config load.
      // ignore: avoid_slow_async_io
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/income_splits.json');
      // Rationale: Checking for file existence performs small IO and is async.
      // We keep it async to avoid UI thread blocking while reading config data.
      // ignore: avoid_slow_async_io
      if (await file.exists()) {
        // Rationale: Reading the JSON file is async; content is expected to be
        // small and the IO is performed asynchronously to prevent UI jank.
        // ignore: avoid_slow_async_io
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content) as List;
        _splits.clear();
        for (final json in jsonList) {
          final split = IncomeSplit.fromJson(json as Map<String, dynamic>);
          _splits[split.accountName] = split;
        }
        // notify listeners that splits have been loaded
        _changes.add(null);
      }
    } catch (e) {
      // 수입 배분 로드 실패: 로그로 남기지 않음(프로덕션용)
    }
  }

  Future<void> saveSplits() async {
    try {
      // Rationale: Persisting the split configuration uses async IO to avoid
      // blocking the UI thread. These are small JSON settings; for larger
      // payloads, prefer background processing using Isolates.
      // ignore: avoid_slow_async_io
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/income_splits.json');
      final jsonList = _splits.values.map((s) => s.toJson()).toList();
      // Rationale: Writing small JSON settings to disk asynchronously avoids
      // blocking UI and is acceptable for the app's current expected file
      // sizes. For heavy-file scenarios, consider moving work to an Isolate.
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
    // notify listeners about the change
    _changes.add(null);

    if (createAssetMoves) {
      // 각 분배 항목마다 AssetMove 기록 생성
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
    final assetService = AssetService();
    final assetMoveService = AssetMoveService();
    await assetService.loadAssets();
    await assetMoveService.loadMoves();

    final now = DateTime.now();
    final dateLabel = '[${DateFormatter.formatDate(now)}]';
    var assets = assetService.getAssets(accountName);

    // 현금 자산 확보 (없으면 생성)
    Asset? cashAsset;
    final cashList = assets
        .where((a) => a.category == AssetCategory.cash)
        .toList();
    if (cashList.isNotEmpty) {
      cashAsset = cashList.first;
    }
    final Asset actualCashAsset =
        cashAsset ??
        Asset(
          id: '${now.microsecondsSinceEpoch}_cash',
          name: '현금',
          amount: 0,
          category: AssetCategory.cash,
          memo: '기본 현금 자산',
          date: now,
        );

    if (!assets.any((a) => a.id == actualCashAsset.id)) {
      await assetService.addAsset(accountName, actualCashAsset);
      assets = assetService.getAssets(accountName);
    }

    // 1. 저축 자산으로 이동
    if (savingsAmount > 0) {
      final Asset savingsAsset = assets.firstWhere(
        (a) => a.category == AssetCategory.deposit && a.name.contains('저축'),
        orElse: () => Asset(
          id: '${now.microsecondsSinceEpoch}_savings',
          name: '$dateLabel 저축',
          amount: 0,
          category: AssetCategory.deposit,
          memo: '수입 분배: 저축',
          date: now,
        ),
      );

      if (!assets.contains(savingsAsset)) {
        await assetService.addAsset(accountName, savingsAsset);
        assets = assetService.getAssets(accountName);
      }

      // AssetMove 기록 생성 (현금→저축)
      final move = AssetMove(
        id: '${now.microsecondsSinceEpoch}_savings_move',
        accountName: accountName,
        fromAssetId: actualCashAsset.id,
        toAssetId: savingsAsset.id,
        amount: savingsAmount,
        type: AssetMoveType.deposit,
        memo: '수입 분배: 저축 (${incomeItems.map((i) => i.name).join(', ')})',
        date: now,
        createdAt: now,
      );
      await assetMoveService.addMove(accountName, move);
    }

    // 2. 예산 자산으로 이동
    if (budgetAmount > 0) {
      final Asset budgetAsset = assets.firstWhere(
        (a) => a.category == AssetCategory.cash && a.name.contains('예산'),
        orElse: () => Asset(
          id: '${now.microsecondsSinceEpoch}_budget',
          name: '$dateLabel 예산',
          amount: 0,
          category: AssetCategory.cash,
          memo: '수입 분배: 지출 예산',
          date: now,
        ),
      );

      if (!assets.contains(budgetAsset)) {
        await assetService.addAsset(accountName, budgetAsset);
        assets = assetService.getAssets(accountName);
      }

      // AssetMove 기록 생성 (현금→예산)
      final move = AssetMove(
        id: '${now.microsecondsSinceEpoch}_budget_move',
        accountName: accountName,
        fromAssetId: actualCashAsset.id,
        toAssetId: budgetAsset.id,
        amount: budgetAmount,
        type: AssetMoveType.transfer,
        memo: '수입 분배: 지출 예산 (${incomeItems.map((i) => i.name).join(', ')})',
        date: now,
        createdAt: now,
      );
      await assetMoveService.addMove(accountName, move);
    }

    // 3. 비상금 자산으로 이동
    if (emergencyAmount > 0) {
      final Asset emergencyAsset = assets.firstWhere(
        (a) => a.category == AssetCategory.deposit && a.name.contains('비상금'),
        orElse: () => Asset(
          id: '${now.microsecondsSinceEpoch}_emergency',
          name: '$dateLabel 비상금',
          amount: 0,
          category: AssetCategory.deposit,
          memo: '수입 분배: 비상금',
          date: now,
        ),
      );

      if (!assets.contains(emergencyAsset)) {
        await assetService.addAsset(accountName, emergencyAsset);
        assets = assetService.getAssets(accountName);
      }

      // AssetMove 기록 생성 (현금→비상금)
      final move = AssetMove(
        id: '${now.microsecondsSinceEpoch}_emergency_move',
        accountName: accountName,
        fromAssetId: actualCashAsset.id,
        toAssetId: emergencyAsset.id,
        amount: emergencyAmount,
        type: AssetMoveType.deposit,
        memo: '수입 분배: 비상금 (${incomeItems.map((i) => i.name).join(', ')})',
        date: now,
        createdAt: now,
      );
      await assetMoveService.addMove(accountName, move);
    }

    // 4. 투자 자산으로 이동 (현금→주식)
    if (assetTransferAmount > 0) {
      final Asset investmentAsset = assets.firstWhere(
        (a) => a.category == AssetCategory.stock,
        orElse: () => Asset(
          id: '${now.microsecondsSinceEpoch}_investment',
          name: '$dateLabel 투자',
          amount: 0,
          category: AssetCategory.stock,
          memo: '수입 분배: 투자',
          date: now,
        ),
      );

      if (!assets.contains(investmentAsset)) {
        await assetService.addAsset(accountName, investmentAsset);
        assets = assetService.getAssets(accountName);
      }

      // AssetMove 기록 생성 (현금→투자/주식)
      final move = AssetMove(
        id: '${now.microsecondsSinceEpoch}_investment_move',
        accountName: accountName,
        fromAssetId: actualCashAsset.id,
        toAssetId: investmentAsset.id,
        amount: assetTransferAmount,
        type: AssetMoveType.purchase,
        memo: '수입 분배: 투자 (${incomeItems.map((i) => i.name).join(', ')})',
        date: now,
        createdAt: now,
      );
      await assetMoveService.addMove(accountName, move);
    }
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

