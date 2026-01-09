import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monthly_agg_cache_service.dart';

@immutable
class QuickSimpleExpenseInputEntry {
  final DateTime createdAt;
  final String raw;
  final String description;
  final int quantity;
  final double amount;
  final String payment;
  final String store;

  const QuickSimpleExpenseInputEntry({
    required this.createdAt,
    required this.raw,
    required this.description,
    required this.quantity,
    required this.amount,
    required this.payment,
    required this.store,
  });

  Map<String, Object?> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'raw': raw,
    'description': description,
    'quantity': quantity,
    'amount': amount,
    'payment': payment,
    'store': store,
  };

  static QuickSimpleExpenseInputEntry? fromJson(Object? json) {
    if (json is! Map) return null;

    final createdAtRaw = json['createdAt'];
    final raw = json['raw'];
    final description = json['description'];
    final quantity = json['quantity'];
    final amount = json['amount'];
    final payment = json['payment'];
    final store = json['store'];

    if (createdAtRaw is! String ||
        raw is! String ||
        description is! String ||
        quantity is! int ||
        (amount is! num) ||
        payment is! String ||
        store is! String) {
      return null;
    }

    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) return null;

    return QuickSimpleExpenseInputEntry(
      createdAt: createdAt,
      raw: raw,
      description: description,
      quantity: quantity,
      amount: amount.toDouble(),
      payment: payment,
      store: store,
    );
  }
}

class QuickSimpleExpenseInputHistoryService {
  static final QuickSimpleExpenseInputHistoryService _instance =
      QuickSimpleExpenseInputHistoryService._internal();

  factory QuickSimpleExpenseInputHistoryService() => _instance;

  QuickSimpleExpenseInputHistoryService._internal();

  static const int _maxEntries = 200;

  String _keyFor(String accountName) {
    final safe = accountName.trim();
    return 'quick_simple_expense_input_history_v1_$safe';
  }

  Future<List<QuickSimpleExpenseInputEntry>> loadEntries(
    String accountName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(accountName));
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final out = <QuickSimpleExpenseInputEntry>[];
      for (final item in decoded) {
        final entry = QuickSimpleExpenseInputEntry.fromJson(item);
        if (entry != null) out.add(entry);
      }

      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> addEntry(
    String accountName, {
    required String raw,
    required String description,
    required int quantity,
    required double amount,
    required String payment,
    required String store,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final nextEntry = QuickSimpleExpenseInputEntry(
      createdAt: DateTime.now(),
      raw: raw.trim(),
      description: description.trim(),
      quantity: quantity <= 0 ? 1 : quantity,
      amount: amount,
      payment: payment.trim(),
      store: store.trim(),
    );

    final existing = await loadEntries(accountName);
    final next = <QuickSimpleExpenseInputEntry>[nextEntry, ...existing];

    final capped = next.length <= _maxEntries
        ? next
        : next.sublist(0, _maxEntries);

    final encoded = jsonEncode(capped.map((e) => e.toJson()).toList());
    await prefs.setString(_keyFor(accountName), encoded);

    final ym = MonthlyAggCacheService.yearMonthOf(nextEntry.createdAt);
    await MonthlyAggCacheService().markDirty(accountName, <String>{ym});
  }
}
