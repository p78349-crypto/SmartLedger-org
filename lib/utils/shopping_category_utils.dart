import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/category_definitions.dart';
import 'package:smart_ledger/utils/shopping_category_rules.dart';

/// Shopping-category suggestion utilities.
///
/// SSOT: keep rules/normalization in one place so screens/services can reuse.
class ShoppingCategoryUtils {
  const ShoppingCategoryUtils._();

  static String _pairKey(({String mainCategory, String? subCategory}) pair) {
    final sub = (pair.subCategory ?? '').trim();
    return '${pair.mainCategory}::${sub.isEmpty ? '-' : sub}';
  }

  static String normalizeHintKey(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '');
  }

  static ({String mainCategory, String? subCategory}) validateSuggestion(
    ({String mainCategory, String? subCategory}) suggestion,
  ) {
    const options = CategoryDefinitions.categoryOptions;
    final main = suggestion.mainCategory;
    if (!options.containsKey(main)) {
      return (mainCategory: Transaction.defaultMainCategory, subCategory: null);
    }

    final subs = options[main] ?? const <String>[];
    final sub = suggestion.subCategory;

    if (sub == null || sub.trim().isEmpty) {
      return (mainCategory: main, subCategory: null);
    }
    if (!subs.contains(sub)) {
      return (mainCategory: main, subCategory: null);
    }
    return (mainCategory: main, subCategory: sub);
  }

  static ({String mainCategory, String? subCategory})? hintFromLearned(
    ShoppingCartItem item,
    Map<String, CategoryHint> learnedHints,
  ) {
    final normalized = normalizeHintKey(item.name);
    if (normalized.isEmpty) return null;

    final exact = learnedHints[normalized];
    if (exact != null) {
      return (mainCategory: exact.mainCategory, subCategory: exact.subCategory);
    }

    for (final entry in learnedHints.entries) {
      final key = entry.key;
      if (key.isEmpty) continue;
      if (normalized.contains(key) || key.contains(normalized)) {
        final hint = entry.value;
        return (mainCategory: hint.mainCategory, subCategory: hint.subCategory);
      }
    }

    return null;
  }

  static ({String mainCategory, String? subCategory}) suggestBuiltIn(
    ShoppingCartItem item,
  ) {
    final name = item.name.trim();
    if (name.isEmpty) {
      return (mainCategory: Transaction.defaultMainCategory, subCategory: null);
    }

    for (final group in ShoppingCategoryRules.groups) {
      for (final entry in group.entries) {
        if (name.contains(entry.key)) {
          return validateSuggestion((
            mainCategory: entry.value.mainCategory,
            subCategory: entry.value.subCategory,
          ));
        }
      }
    }

    return (mainCategory: Transaction.defaultMainCategory, subCategory: null);
  }

  static ({String mainCategory, String? subCategory}) suggest(
    ShoppingCartItem item, {
    required Map<String, CategoryHint> learnedHints,
  }) {
    final learned = hintFromLearned(item, learnedHints);
    if (learned != null) return validateSuggestion(learned);
    return suggestBuiltIn(item);
  }

  /// Returns multiple candidate suggestions for UI pickers.
  ///
  /// Order:
  /// 1) Learned hint (if any)
  /// 2) All rule matches (group order)
  /// 3) Safe fallbacks (keeps UI usable when no match)
  static List<({String mainCategory, String? subCategory})> suggestCandidates(
    ShoppingCartItem item, {
    required Map<String, CategoryHint> learnedHints,
    int maxCount = 8,
  }) {
    final out = <({String mainCategory, String? subCategory})>[];
    final seen = <String>{};

    void add(({String mainCategory, String? subCategory}) pair) {
      final validated = validateSuggestion(pair);
      final k = _pairKey(validated);
      if (seen.contains(k)) return;
      seen.add(k);
      out.add(validated);
    }

    final learned = hintFromLearned(item, learnedHints);
    if (learned != null) add(learned);

    final name = item.name.trim();
    if (name.isNotEmpty) {
      for (final group in ShoppingCategoryRules.groups) {
        for (final entry in group.entries) {
          if (name.contains(entry.key)) {
            add((
              mainCategory: entry.value.mainCategory,
              subCategory: entry.value.subCategory,
            ));
            if (out.length >= maxCount) return out;
          }
        }
      }
    }

    // Fallbacks: keep the first pick easy even if no keyword matches.
    add(ShoppingCategoryRules.foodGrocery);
    add(ShoppingCategoryRules.foodProcessed);
    add(ShoppingCategoryRules.foodMeat);

    if (out.length > maxCount) {
      return out.take(maxCount).toList(growable: false);
    }
    return out;
  }
}

