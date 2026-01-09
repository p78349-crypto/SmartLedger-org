import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../services/store_alias_service.dart';
import 'store_memo_utils.dart';

@immutable
class MemoSuggestionUtils {
  const MemoSuggestionUtils._();

  static DateTime scanStartForNow(DateTime now) {
    return now.subtract(const Duration(days: 183));
  }

  static String normalizeForMatch(String raw) {
    return StoreMemoUtils.normalizeMemoForMatch(raw);
  }

  static String? filterStoreKey(String? raw) {
    return StoreMemoUtils.extractStoreKey(raw);
  }

  static List<String> suggestChips({
    required List<Transaction> transactions,
    required String currentMemo,
    Map<String, String>? storeAliasMap,
    int maxChips = 5,
  }) {
    final now = DateTime.now();
    final scanStart = scanStartForNow(now);

    final rawStoreKey = StoreMemoUtils.extractStoreKey(currentMemo);
    final resolvedStoreKey = rawStoreKey == null
        ? null
        : (storeAliasMap == null
              ? rawStoreKey
              : StoreAliasService.resolve(rawStoreKey, storeAliasMap));
    final storeKey = resolvedStoreKey == null
        ? null
        : normalizeForMatch(resolvedStoreKey);

    final chips = <String>[];

    if (storeKey != null && storeKey.length >= 2) {
      final counts = <String, int>{};

      for (final t in transactions) {
        if (t.type != TransactionType.expense) continue;
        if (t.isRefund) continue;
        if (t.date.isBefore(scanStart)) continue;

        final txStore = t.store?.trim();
        final txStoreResolved = (txStore != null && txStore.isNotEmpty)
            ? (storeAliasMap == null
                  ? txStore
                  : StoreAliasService.resolve(txStore, storeAliasMap))
            : null;
        final txStoreNorm =
            (txStoreResolved != null && txStoreResolved.isNotEmpty)
            ? normalizeForMatch(txStoreResolved)
            : null;

        final memo = normalizeForMatch(t.memo);
        if (memo.isEmpty) continue;

        final matchesStore = (txStoreNorm != null && txStoreNorm.isNotEmpty)
            ? txStoreNorm == storeKey
            : memo.contains(storeKey);
        if (!matchesStore) continue;

        final extra = _extractExtraMemoPart(memo, storeKey);
        if (extra == null) continue;

        for (final k in _tokenizeKeywords(extra)) {
          if (k == storeKey) continue;
          counts[k] = (counts[k] ?? 0) + 1;
        }
      }

      final ranked = counts.entries.toList(growable: false)
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final e in ranked) {
        if (chips.length >= maxChips) break;
        chips.add(e.key);
      }
    }

    return chips;
  }

  static String? _extractExtraMemoPart(String memo, String storeKey) {
    if (memo == storeKey) return null;

    var text = memo;
    text = text.replaceAll(storeKey, '').trim();
    text = text.replaceAll(RegExp(r'^[\s\-:|,/]+'), '').trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.isEmpty ? null : text;
  }

  static Iterable<String> _tokenizeKeywords(String text) sync* {
    final parts = text
        .split(RegExp(r'[\s\-:|,/]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    for (final p in parts) {
      final k = _normalizeToken(p);
      if (k.isEmpty) continue;
      if (_isStopToken(k)) continue;
      yield k;
    }
  }

  static String _normalizeToken(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return '';

    if (t.length > 18) {
      t = t.substring(0, 18);
    }

    return t;
  }

  static bool _isStopToken(String t) {
    const stop = <String>{'구매', '결제', '카드', '현금', '영수증', '메모'};
    if (stop.contains(t)) return true;
    if (RegExp(r'^\d+$').hasMatch(t)) return true;
    return false;
  }
}
