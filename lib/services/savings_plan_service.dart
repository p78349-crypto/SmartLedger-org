import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/savings_plan.dart';
import '../models/transaction.dart';
import 'transaction_service.dart';
import '../utils/pref_keys.dart';

class SavingsPlanService {
  static final SavingsPlanService _instance = SavingsPlanService._internal();
  factory SavingsPlanService() => _instance;
  SavingsPlanService._internal();

  static String get _prefsKey => PrefKeys.savingsPlans;

  final Map<String, List<SavingsPlan>> _accountPlans = {};
  bool _initialized = false;
  Future<void>? _loading;

  Future<void> loadPlans() {
    if (_initialized) {
      return Future.value();
    }
    _loading ??= _doLoad();
    return _loading!;
  }

  List<SavingsPlan> getPlans(String accountName) {
    final list = _accountPlans[accountName];
    if (list == null) {
      return const <SavingsPlan>[];
    }
    return List.unmodifiable(list);
  }

  Future<void> addPlan(String accountName, SavingsPlan plan) async {
    await loadPlans();
    final list = _accountPlans.putIfAbsent(accountName, () => []);
    list.add(plan);
    await _persist();
  }

  Future<void> updatePlan(String accountName, SavingsPlan updated) async {
    await loadPlans();
    final list = _accountPlans[accountName];
    if (list == null) {
      return;
    }
    final index = list.indexWhere((plan) => plan.id == updated.id);
    if (index == -1) {
      return;
    }
    list[index] = updated;
    await _persist();
  }

  Future<void> deletePlan(String accountName, String planId) async {
    await loadPlans();
    final list = _accountPlans[accountName];
    if (list == null) {
      return;
    }
    list.removeWhere((plan) => plan.id == planId);
    await _persist();
  }

  Future<void> deleteAccount(String accountName) async {
    await loadPlans();
    if (_accountPlans.remove(accountName) != null) {
      await _persist();
    }
  }

  Future<void> replacePlans(String accountName, List<SavingsPlan> plans) async {
    await loadPlans();
    _accountPlans[accountName] = List<SavingsPlan>.from(plans);
    await _persist();
  }

  Future<void> syncDueDeposits(String accountName) async {
    await loadPlans();
    final plans = _accountPlans[accountName];
    if (plans == null || plans.isEmpty) {
      return;
    }

    await TransactionService().loadTransactions();
    var updated = false;
    final now = DateTime.now();
    for (var i = 0; i < plans.length; i++) {
      final plan = plans[i];
      final dueCount = plan.dueCount(now);
      if (dueCount <= 0) {
        continue;
      }
      final newPaidMonths = List<int>.from(plan.paidMonths);
      var planUpdated = false;
      for (var monthIndex = 0; monthIndex < dueCount; monthIndex++) {
        if (newPaidMonths.contains(monthIndex)) {
          continue;
        }
        final dueDate = plan.dueDateFor(monthIndex);
        final depositDate = dueDate.isAfter(now) ? now : dueDate;
        final transaction = Transaction(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: TransactionType.savings,
          description: '${plan.name} ${monthIndex + 1}회차',
          amount: plan.monthlyAmount,
          date: depositDate,
          unitPrice: plan.monthlyAmount,
          paymentMethod: '자동이체',
          memo: '예금 자동납입(${plan.id})',
        );
        await TransactionService().addTransaction(accountName, transaction);
        newPaidMonths.add(monthIndex);
        planUpdated = true;
      }
      if (planUpdated) {
        newPaidMonths.sort();
        plans[i] = plan.copyWith(paidMonths: newPaidMonths);
        updated = true;
      }
    }
    if (updated) {
      await _persist();
    }
  }

  Future<void> markManualPayment(
    String accountName,
    String planId,
    int monthIndex,
  ) async {
    await loadPlans();
    final plans = _accountPlans[accountName];
    if (plans == null) {
      return;
    }
    final index = plans.indexWhere((plan) => plan.id == planId);
    if (index == -1) {
      return;
    }
    final plan = plans[index];
    if (plan.paidMonths.contains(monthIndex)) {
      return;
    }
    final updatedPlan = plan.copyWith(
      paidMonths: [...plan.paidMonths, monthIndex]..sort(),
    );
    plans[index] = updatedPlan;
    await _persist();
  }

  Future<void> _doLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        _accountPlans
          ..clear()
          ..addAll(
            data.map(
              (key, value) => MapEntry(
                key,
                (value as List<dynamic>)
                    .map(
                      (item) =>
                          SavingsPlan.fromJson(item as Map<String, dynamic>),
                    )
                    .toList(),
              ),
            ),
          );
      } catch (_) {
        _accountPlans.clear();
      }
    }
    _initialized = true;
    _loading = null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _accountPlans.map(
      (key, value) =>
          MapEntry(key, value.map((plan) => plan.toJson()).toList()),
    );
    await prefs.setString(_prefsKey, jsonEncode(data));
  }
}
