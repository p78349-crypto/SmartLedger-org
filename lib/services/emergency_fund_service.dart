import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/models/asset_move.dart';
import 'package:smart_ledger/models/emergency_transaction.dart';
import 'package:smart_ledger/services/asset_move_service.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class EmergencyFundService {
  EmergencyFundService._();

  static final EmergencyFundService _instance = EmergencyFundService._();
  factory EmergencyFundService() => _instance;

  final Map<String, List<EmergencyTransaction>> _transactionsByAccount = {};
  bool _isLoaded = false;

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    await _load();
    _isLoaded = true;
  }

  List<EmergencyTransaction> getTransactions(String accountName) {
    return List<EmergencyTransaction>.unmodifiable(
      _transactionsByAccount[accountName] ?? const <EmergencyTransaction>[],
    );
  }

  Future<void> addTransaction(
    String accountName,
    EmergencyTransaction transaction,
  ) async {
    await ensureLoaded();
    final current = List<EmergencyTransaction>.from(
      _transactionsByAccount[accountName] ?? const <EmergencyTransaction>[],
    );
    current.add(transaction);
    _transactionsByAccount[accountName] = current;
    await _persist();
  }

  Future<void> upsertTransaction(
    String accountName,
    EmergencyTransaction transaction,
  ) async {
    await ensureLoaded();
    final current = List<EmergencyTransaction>.from(
      _transactionsByAccount[accountName] ?? const <EmergencyTransaction>[],
    );
    final index = current.indexWhere((t) => t.id == transaction.id);
    if (index == -1) {
      current.add(transaction);
    } else {
      current[index] = transaction;
    }
    _transactionsByAccount[accountName] = current;
    await _persist();
  }

  Future<void> replaceTransactions(
    String accountName,
    List<EmergencyTransaction> transactions,
  ) async {
    await ensureLoaded();
    _transactionsByAccount[accountName] = List<EmergencyTransaction>.from(
      transactions,
    );
    await _persist();
  }

  Future<void> deleteTransaction(
    String accountName,
    String transactionId,
  ) async {
    await ensureLoaded();
    final current = List<EmergencyTransaction>.from(
      _transactionsByAccount[accountName] ?? const <EmergencyTransaction>[],
    );
    current.removeWhere((t) => t.id == transactionId);
    _transactionsByAccount[accountName] = current;
    await _persist();
  }

  Future<void> deleteTransactions(
    String accountName,
    Iterable<String> transactionIds,
  ) async {
    await ensureLoaded();
    final ids = transactionIds.toSet();
    final current = List<EmergencyTransaction>.from(
      _transactionsByAccount[accountName] ?? const <EmergencyTransaction>[],
    );
    current.removeWhere((t) => ids.contains(t.id));
    _transactionsByAccount[accountName] = current;
    await _persist();
  }

  /// Delete one or more emergency fund transactions and reflect the same
  /// net amount change into a target cash asset.
  ///
  /// Rationale:
  /// - Removing an EmergencyTransaction changes the emergency fund balance by
  ///   `-transaction.amount`.
  /// - To preserve "자산 순환" between Emergency Fund and Cash, we apply
  ///   `+transaction.amount` to the chosen cash asset.
  ///
  /// When multiple transactions are deleted, the cash adjustment uses the sum.
  Future<void> deleteTransactionsAndAdjustCashAsset(
    String accountName,
    Iterable<String> transactionIds, {
    required String cashAssetId,
    String memo = '비상금 거래 삭제(환불/취소) 반영',
  }) async {
    await ensureLoaded();
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();

    final ids = transactionIds.toSet();
    final current = List<EmergencyTransaction>.from(
      _transactionsByAccount[accountName] ?? const <EmergencyTransaction>[],
    );

    final toDelete = current.where((t) => ids.contains(t.id)).toList();
    if (toDelete.isEmpty) {
      return;
    }

    final delta = toDelete.fold<double>(0.0, (sum, t) => sum + t.amount);

    current.removeWhere((t) => ids.contains(t.id));
    _transactionsByAccount[accountName] = current;
    await _persist();

    // Apply delta to cash asset.
    final assetService = AssetService();
    final assets = assetService.getAssets(accountName);
    final cashAsset = assets.firstWhere((a) => a.id == cashAssetId);
    final updatedCash = cashAsset.copyWith(amount: cashAsset.amount + delta);
    await assetService.updateAsset(accountName, updatedCash);

    // Record an asset move so the circulation appears in timelines.
    if (delta != 0) {
      final isCashIncoming = delta > 0;
      final move = AssetMove(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        accountName: accountName,
        fromAssetId: isCashIncoming ? 'emergency_fund' : cashAssetId,
        toAssetId: isCashIncoming ? cashAssetId : null,
        toCategoryName: isCashIncoming ? '비상금' : '비상금',
        amount: delta.abs(),
        memo: memo,
        date: DateTime.now(),
      );
      await AssetMoveService().addMove(accountName, move);
    }
  }

  Future<void> deleteAccount(String accountName) async {
    await ensureLoaded();
    _transactionsByAccount.remove(accountName);
    await _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.emergencyFundTransactions);
    if (raw == null || raw.trim().isEmpty) {
      _transactionsByAccount.clear();
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      _transactionsByAccount.clear();
      return;
    }

    final Map<String, List<EmergencyTransaction>> parsed = {};

    for (final entry in decoded.entries) {
      final accountName = entry.key;
      final value = entry.value;
      if (value is! List) continue;

      final txs = <EmergencyTransaction>[];
      for (final item in value) {
        if (item is Map) {
          txs.add(
            EmergencyTransaction.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      parsed[accountName] = txs;
    }

    _transactionsByAccount
      ..clear()
      ..addAll(parsed);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> data = {
      for (final entry in _transactionsByAccount.entries)
        entry.key: entry.value.map((t) => t.toJson()).toList(),
    };

    await prefs.setString(PrefKeys.emergencyFundTransactions, jsonEncode(data));
  }
}
