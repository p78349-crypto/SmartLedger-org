import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/investment_goal.dart';

class InvestmentGoalService {
  String _key(String accountName) => 'investment_goals_v1_$accountName';

  Future<List<InvestmentGoal>> getGoals(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(accountName));
    if (raw == null || raw.isEmpty) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .map((e) => InvestmentGoal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setGoals(String accountName, List<InvestmentGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final data = goals.map((g) => g.toJson()).toList();
    await prefs.setString(_key(accountName), json.encode(data));
  }

  Future<List<InvestmentGoal>> addGoal(
    String accountName,
    InvestmentGoal goal,
  ) async {
    final goals = await getGoals(accountName);
    goals.add(goal);
    await setGoals(accountName, goals);
    return goals;
  }

  Future<List<InvestmentGoal>> updateGoal(
    String accountName,
    InvestmentGoal goal,
  ) async {
    final goals = await getGoals(accountName);
    final idx = goals.indexWhere((g) => g.id == goal.id);
    if (idx >= 0) {
      goals[idx] = goal;
      await setGoals(accountName, goals);
    }
    return goals;
  }

  Future<List<InvestmentGoal>> removeGoal(
    String accountName,
    String id,
  ) async {
    final goals = await getGoals(accountName);
    goals.removeWhere((g) => g.id == id);
    await setGoals(accountName, goals);
    return goals;
  }
}
