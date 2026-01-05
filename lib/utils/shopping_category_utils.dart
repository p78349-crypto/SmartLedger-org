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

  static String normalizeHintKey(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '');
  }

  static ShoppingCategoryPair validateSuggestion(
    ShoppingCategoryPair suggestion,
  ) {
    const options = CategoryDefinitions.categoryOptions;
    final main = suggestion.mainCategory;
    if (!options.containsKey(main)) {
      return (
        mainCategory: Transaction.defaultMainCategory,
        subCategory: null,
        detailCategory: null,
      );
    }

    final subs = options[main] ?? const <String>[];
    final sub = suggestion.subCategory;

    if (sub == null || sub.trim().isEmpty) {
      return (mainCategory: main, subCategory: null, detailCategory: null);
    }
    if (!subs.contains(sub)) {
      return (mainCategory: main, subCategory: null, detailCategory: null);
    }
    // Note: We don't strictly validate detailCategory against a list yet,
    // but we pass it through if it exists.
    return (
      mainCategory: main,
      subCategory: sub,
      detailCategory: suggestion.detailCategory,
    );
  }

  static ShoppingCategoryPair? hintFromLearned(
    ShoppingCartItem item,
    Map<String, CategoryHint> learnedHints,
  ) {
    final normalized = normalizeHintKey(item.name);
    if (normalized.isEmpty) return null;

    final exact = learnedHints[normalized];
    if (exact != null) {
      return (
        mainCategory: exact.mainCategory,
        subCategory: exact.subCategory,
        detailCategory: exact.detailCategory,
      );
    }

    for (final entry in learnedHints.entries) {
      final key = entry.key;
      if (key.isEmpty) continue;
      if (normalized.contains(key) || key.contains(normalized)) {
        final hint = entry.value;
        return (
          mainCategory: hint.mainCategory,
          subCategory: hint.subCategory,
          detailCategory: hint.detailCategory,
        );
      }
    }

    return null;
  }

  static ShoppingCategoryPair suggestBuiltIn(
    ShoppingCartItem item,
  ) {
    final name = item.name.trim();
    if (name.isEmpty) {
      return (
        mainCategory: Transaction.defaultMainCategory,
        subCategory: null,
        detailCategory: null,
      );
    }

    for (final group in ShoppingCategoryRules.groups) {
      for (final entry in group.entries) {
        if (name.contains(entry.key)) {
          return validateSuggestion(entry.value);
        }
      }
    }

    return (
      mainCategory: Transaction.defaultMainCategory,
      subCategory: null,
      detailCategory: null,
    );
  }

  static ShoppingCategoryPair suggest(
    ShoppingCartItem item, {
    required Map<String, CategoryHint> learnedHints,
  }) {
    final learned = hintFromLearned(item, learnedHints);
    if (learned != null) {
      final validated = validateSuggestion(learned);
      if (CategoryDefinitions.shoppingMainCategories.contains(
        validated.mainCategory,
      )) {
        return validated;
      }
    }
    final builtIn = suggestBuiltIn(item);
    if (CategoryDefinitions.shoppingMainCategories.contains(
      builtIn.mainCategory,
    )) {
      return builtIn;
    }
    return (
      mainCategory: CategoryDefinitions.defaultCategory,
      subCategory: null,
      detailCategory: null,
    );
  }
}
