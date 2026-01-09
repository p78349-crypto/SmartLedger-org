import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/account.dart';
import '../utils/pref_keys.dart';

class AccountService {
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  static const String _legacyPrefsKey = 'accounts';
  static String get _monthEndPrefsKey => PrefKeys.accountMonthEnd;

  final AppDatabase _database = DatabaseProvider.instance.database;

  final List<Account> _accounts = [];
  final Map<String, _MonthEndAccountData> _monthEndByAccount = {};
  bool _initialized = false;
  Future<void>? _loading;

  List<Account> get accounts => List.unmodifiable(_accounts);

  Future<void> loadAccounts() {
    if (_initialized) {
      return Future.value();
    }
    _loading ??= _doLoad();
    return _loading!;
  }

  Future<bool> addAccount(Account account) async {
    await loadAccounts();
    if (_accounts.any((a) => a.name == account.name)) {
      return false;
    }
    final entry = DbAccountsCompanion.insert(
      name: account.name,
      createdAt: Value(account.createdAt),
    );
    await _database.insertAccount(entry);
    _accounts.add(account);

    // Clear any stale month-end cache for newly created accounts.
    if (_monthEndByAccount.remove(account.name) != null) {
      await _persistMonthEnd();
    }
    return true;
  }

  Account? getAccountByName(String name) {
    try {
      return _accounts.firstWhere((a) => a.name == name);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAccount(String name) async {
    await loadAccounts();
    final removedRows = await _database.deleteAccountByName(name);
    if (removedRows > 0) {
      _accounts.removeWhere((a) => a.name == name);
      if (_monthEndByAccount.remove(name) != null) {
        await _persistMonthEnd();
      }
      return true;
    }
    return false;
  }

  Future<bool> updateMonthEndData(
    String accountName, {
    required double carryoverAmount,
    required double overdraftAmount,
    DateTime? completedAt,
  }) async {
    await loadAccounts();
    final index = _accounts.indexWhere((a) => a.name == accountName);
    if (index == -1) {
      return false;
    }

    final old = _accounts[index];
    final updated = Account(
      name: old.name,
      createdAt: old.createdAt,
      carryoverAmount: carryoverAmount,
      overdraftAmount: overdraftAmount,
      lastCarryoverDate: completedAt ?? DateTime.now(),
    );

    _accounts[index] = updated;
    _monthEndByAccount[accountName] = _MonthEndAccountData(
      carryoverAmount: carryoverAmount,
      overdraftAmount: overdraftAmount,
      lastCarryoverDate: updated.lastCarryoverDate,
    );
    await _persistMonthEnd();
    return true;
  }

  /// Restores month-end snapshot for an account from backup data.
  ///
  /// This differs from [updateMonthEndData] in that it does NOT default
  /// [lastCarryoverDate] to `DateTime.now()` when missing.
  Future<void> restoreMonthEndSnapshot(
    String accountName, {
    required double carryoverAmount,
    required double overdraftAmount,
    required DateTime? lastCarryoverDate,
  }) async {
    await loadAccounts();

    _monthEndByAccount[accountName] = _MonthEndAccountData(
      carryoverAmount: carryoverAmount,
      overdraftAmount: overdraftAmount,
      lastCarryoverDate: lastCarryoverDate,
    );
    await _persistMonthEnd();

    final index = _accounts.indexWhere((a) => a.name == accountName);
    if (index == -1) return;
    final old = _accounts[index];
    _accounts[index] = Account(
      name: old.name,
      createdAt: old.createdAt,
      carryoverAmount: carryoverAmount,
      overdraftAmount: overdraftAmount,
      lastCarryoverDate: lastCarryoverDate,
    );
  }

  /// Clears the month-end snapshot for an account.
  Future<void> clearMonthEndSnapshot(String accountName) async {
    await loadAccounts();
    final removed = _monthEndByAccount.remove(accountName) != null;
    if (removed) {
      await _persistMonthEnd();
    }

    final index = _accounts.indexWhere((a) => a.name == accountName);
    if (index == -1) return;
    final old = _accounts[index];
    _accounts[index] = Account(name: old.name, createdAt: old.createdAt);
  }

  Future<void> _doLoad() async {
    await _loadMonthEnd();
    var rows = await _database.getAllAccounts();
    if (rows.isEmpty) {
      final migrated = await _migrateFromLegacyStorage();
      if (migrated) {
        rows = await _database.getAllAccounts();
      }
    }
    _accounts
      ..clear()
      ..addAll(rows.map(_mapRowToAccount));
    _initialized = true;
    _loading = null;
  }

  Account _mapRowToAccount(DbAccount row) {
    final monthEnd = _monthEndByAccount[row.name];
    return Account(
      name: row.name,
      createdAt: row.createdAt,
      carryoverAmount: monthEnd?.carryoverAmount ?? 0,
      overdraftAmount: monthEnd?.overdraftAmount ?? 0,
      lastCarryoverDate: monthEnd?.lastCarryoverDate,
    );
  }

  Future<void> _loadMonthEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_monthEndPrefsKey);
    _monthEndByAccount.clear();
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final map = entry.value;
        if (map is Map<String, dynamic>) {
          _monthEndByAccount[entry.key] = _MonthEndAccountData.fromJson(map);
        }
      }
    } catch (_) {
      _monthEndByAccount.clear();
    }
  }

  Future<void> _persistMonthEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _monthEndByAccount.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_monthEndPrefsKey, jsonEncode(data));
  }

  Future<bool> _migrateFromLegacyStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyPrefsKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }
    try {
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      for (final item in data) {
        final legacy = Account.fromJson(item as Map<String, dynamic>);
        await _database.insertAccount(
          DbAccountsCompanion.insert(
            name: legacy.name,
            createdAt: Value(legacy.createdAt),
          ),
        );
      }
      await prefs.remove(_legacyPrefsKey);
      return data.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class _MonthEndAccountData {
  const _MonthEndAccountData({
    required this.carryoverAmount,
    required this.overdraftAmount,
    required this.lastCarryoverDate,
  });

  final double carryoverAmount;
  final double overdraftAmount;
  final DateTime? lastCarryoverDate;

  factory _MonthEndAccountData.fromJson(Map<String, dynamic> json) {
    return _MonthEndAccountData(
      carryoverAmount: (json['carryoverAmount'] as num?)?.toDouble() ?? 0,
      overdraftAmount: (json['overdraftAmount'] as num?)?.toDouble() ?? 0,
      lastCarryoverDate: json['lastCarryoverDate'] != null
          ? DateTime.tryParse(json['lastCarryoverDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carryoverAmount': carryoverAmount,
      'overdraftAmount': overdraftAmount,
      'lastCarryoverDate': lastCarryoverDate?.toIso8601String(),
    };
  }
}
