import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../utils/pref_keys.dart';

class CartTransactionPrefill {
  CartTransactionPrefill._();

  static const String _suffix = 'cart_tx_prefill_v1';

  static String _key(String accountName) =>
      PrefKeys.accountKey(accountName, _suffix);

  static Future<void> savePrefill({
    required String accountName,
    required List<Transaction> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load existing data (Map<DateString, List>)
    final raw = prefs.getString(_key(accountName));
    Map<String, dynamic> storedMap = {};
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          // Migration: if old format (ts, items), ignore or convert.
          if (decoded.containsKey('ts') && decoded.containsKey('items')) {
            storedMap = {}; // Reset old format
          } else {
            storedMap = decoded;
          }
        }
      } catch (_) {
        storedMap = {};
      }
    }

    // 2. Limit to max 15 date groups (remove oldest if exceeded)
    // 날짜 스트링(YYYY-MM-DD) 기준 정렬
    final sortedKeys = storedMap.keys.toList()..sort();
    if (sortedKeys.length > 15) {
      // 15개 초과분만큼 앞에서부터(오래된 날짜) 삭제
      final removeCount = sortedKeys.length - 15;
      for (var i = 0; i < removeCount; i++) {
        storedMap.remove(sortedKeys[i]);
      }
    }

    // 3. Group new items by date and append
    for (final item in items) {
      // Use Transaction's date. Default to today if null (though it's required in model).
      final dateKey = item.date.toIso8601String().split('T').first;

      final currentList =
          (storedMap[dateKey] as List?)?.cast<Map<String, dynamic>>() ?? [];
      currentList.add(item.toJson());
      storedMap[dateKey] = currentList;
    }

    // 추가 후 다시 체크 (새로 추가된 날짜 때문에 16개가 될 수 있음)
    final finalKeys = storedMap.keys.toList()..sort();
    if (finalKeys.length > 15) {
      final removeCount = finalKeys.length - 15;
      for (var i = 0; i < removeCount; i++) {
        storedMap.remove(finalKeys[i]);
      }
    }

    await prefs.setString(_key(accountName), jsonEncode(storedMap));
  }

  /// Read all prefill data (flattens date groups).
  /// Returns [] if empty.
  /// Set [clear] to true to wipe data after reading (default: true).
  static Future<List<Transaction>> readPrefill({
    required String accountName,
    bool clear = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(accountName));
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      final allTransactions = <Transaction>[];

      if (decoded is Map<String, dynamic>) {
        // Check for old format (ts, items)
        if (decoded.containsKey('ts') && decoded.containsKey('items')) {
          final listRaw = decoded['items'];
          if (listRaw is List) {
            allTransactions.addAll(
              listRaw.whereType<Map<String, dynamic>>().map(
                Transaction.fromJson,
              ),
            );
          }
        } else {
          // New format: Map<DateString, List>
          for (final key in decoded.keys) {
            final list = decoded[key];
            if (list is List) {
              allTransactions.addAll(
                list.whereType<Map<String, dynamic>>().map(
                  Transaction.fromJson,
                ),
              );
            }
          }
        }
      }

      if (clear && allTransactions.isNotEmpty) {
        await prefs.remove(_key(accountName));
      }

      return allTransactions;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> clearPrefill({required String accountName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(accountName));
  }
}
