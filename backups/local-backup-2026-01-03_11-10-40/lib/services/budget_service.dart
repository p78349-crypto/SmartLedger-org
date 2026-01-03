import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  static String get _prefsKey => PrefKeys.budgets;

  final Map<String, double> _monthlyBudget = {};
  bool _initialized = false;
  Future<void>? _loading;

  double getBudget(String accountName) {
    return _monthlyBudget[accountName] ?? 0;
  }

  Future<void> loadBudgets() {
    if (_initialized) {
      return Future.value();
    }
    _loading ??= _doLoad();
    return _loading!;
  }

  Future<void> setBudget(String accountName, double amount) async {
    await loadBudgets();
    _monthlyBudget[accountName] = amount;
    await _persist();
  }

  Future<void> removeBudget(String accountName) async {
    await loadBudgets();
    if (_monthlyBudget.remove(accountName) != null) {
      await _persist();
    }
  }

  Future<void> _doLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        _monthlyBudget
          ..clear()
          ..addAll(
            data.map((key, value) => MapEntry(key, (value as num).toDouble())),
          );
      } catch (_) {
        _monthlyBudget.clear();
      }
    }
    _initialized = true;
    _loading = null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_monthlyBudget);
    await prefs.setString(_prefsKey, encoded);
  }
}
