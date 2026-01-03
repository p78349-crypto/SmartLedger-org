import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class FixedCostService {
  static final FixedCostService _instance = FixedCostService._internal();
  factory FixedCostService() => _instance;
  FixedCostService._internal();

  static String get _prefsKey => PrefKeys.fixedCosts;

  final Map<String, List<FixedCost>> _accountFixedCosts = {};
  bool _initialized = false;
  Future<void>? _loading;
  Future<void> _persistChain = Future.value();

  Future<void> loadFixedCosts() {
    if (_initialized) {
      return Future.value();
    }
    _loading ??= _doLoad();
    return _loading!;
  }

  List<FixedCost> getFixedCosts(String accountName) {
    final list = _accountFixedCosts[accountName];
    if (list == null) {
      return const <FixedCost>[];
    }
    return List.unmodifiable(list);
  }

  List<String> getTrackedAccountNames() {
    return List.unmodifiable(_accountFixedCosts.keys);
  }

  Future<void> addFixedCost(String accountName, FixedCost cost) async {
    await loadFixedCosts();
    final list = _accountFixedCosts.putIfAbsent(accountName, () => []);
    list.add(cost);
    await _persist();
  }

  Future<void> replaceFixedCosts(
    String accountName,
    List<FixedCost> costs,
  ) async {
    await loadFixedCosts();
    _accountFixedCosts[accountName] = List<FixedCost>.from(costs);
    await _persist();
  }

  Future<void> deleteAccount(String accountName) async {
    await loadFixedCosts();
    if (_accountFixedCosts.remove(accountName) != null) {
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
        _accountFixedCosts
          ..clear()
          ..addAll(
            data.map(
              (key, value) => MapEntry(
                key,
                (value as List<dynamic>)
                    .map(
                      (item) =>
                          FixedCost.fromJson(item as Map<String, dynamic>),
                    )
                    .toList(),
              ),
            ),
          );
      } catch (_) {
        _accountFixedCosts.clear();
      }
    }
    _initialized = true;
    _loading = null;
  }

  Future<void> _persist() {
    final scheduled = _persistChain.then((_) => _persistInternal());
    _persistChain = scheduled.then<void>(
      (_) {},
      onError: (error, stackTrace) {
        _persistChain = Future.value();
        return Future<void>.error(error, stackTrace);
      },
    );
    return scheduled;
  }

  Future<void> _persistInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _accountFixedCosts.map(
      (key, value) =>
          MapEntry(key, value.map((cost) => cost.toJson()).toList()),
    );
    await prefs.setString(_prefsKey, jsonEncode(data));
  }
}
