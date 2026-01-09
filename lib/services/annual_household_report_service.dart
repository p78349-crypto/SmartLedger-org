import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_guardrail_service.dart';

@immutable
class AnnualHouseholdReport {
  final int windowDays;
  final int totalEvents;
  final int distinctItems;
  final String topItemName;
  final double topItemAmount;
  final List<MapEntry<String, double>> topItems;

  const AnnualHouseholdReport({
    required this.windowDays,
    required this.totalEvents,
    required this.distinctItems,
    required this.topItemName,
    required this.topItemAmount,
    required this.topItems,
  });
}

class AnnualHouseholdReportService {
  AnnualHouseholdReportService._();

  static DateTime _startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static Future<List<HealthConsumptionRecord>> _loadLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(HealthGuardrailService.consumptionLogPrefsKey);
    if (raw == null || raw.trim().isEmpty) return <HealthConsumptionRecord>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <HealthConsumptionRecord>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HealthConsumptionRecord.fromJson)
          .where((r) => r.itemName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return <HealthConsumptionRecord>[];
    }
  }

  static Future<AnnualHouseholdReport?> buildReport({
    int windowDays = 365,
  }) async {
    final w = windowDays.clamp(30, 365);
    final now = DateTime.now();
    final since = _startOfDay(now).subtract(Duration(days: w));

    final records = (await _loadLog())
        .where((r) => r.timestamp.isAfter(since))
        .toList();
    if (records.isEmpty) return null;

    final totals = <String, double>{};
    for (final r in records) {
      totals[r.itemName] = (totals[r.itemName] ?? 0.0) + r.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.isNotEmpty
        ? sorted.first
        : const MapEntry<String, double>('', 0.0);
    final topItems = sorted.take(5).toList();

    return AnnualHouseholdReport(
      windowDays: w,
      totalEvents: records.length,
      distinctItems: totals.keys.length,
      topItemName: top.key,
      topItemAmount: top.value,
      topItems: topItems,
    );
  }
}
