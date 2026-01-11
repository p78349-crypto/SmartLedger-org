import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/pref_keys.dart';

class PolicyService {
  PolicyService._();
  static final PolicyService _instance = PolicyService._();
  factory PolicyService() => _instance;

  Future<void> addHold({
    required String reason,
    Map<String, dynamic>? meta,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.policyHolds);
    final List<dynamic> list = raw != null
        ? jsonDecode(raw) as List<dynamic>
        : [];
    final entry = {
      'ts': DateTime.now().toIso8601String(),
      'reason': reason,
      'meta': meta ?? {},
    };
    list.insert(0, entry);
    await prefs.setString(PrefKeys.policyHolds, jsonEncode(list));
  }

  Future<void> addBlockingRule({
    required String key,
    required double avg,
    required int count,
    Map<String, dynamic>? meta,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.policyBlockingRules);
    final List<dynamic> list = raw != null
        ? jsonDecode(raw) as List<dynamic>
        : [];
    final rule = {
      'createdAt': DateTime.now().toIso8601String(),
      'key': key,
      'avg': avg,
      'count': count,
      'meta': meta ?? {},
    };
    list.insert(0, rule);
    await prefs.setString(PrefKeys.policyBlockingRules, jsonEncode(list));
  }

  Future<List<dynamic>> listHolds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.policyHolds);
    return raw != null ? jsonDecode(raw) as List<dynamic> : [];
  }

  Future<List<dynamic>> listBlockingRules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.policyBlockingRules);
    return raw != null ? jsonDecode(raw) as List<dynamic> : [];
  }
}
