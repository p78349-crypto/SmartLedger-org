class Recipe {
  final String id;
  /// Localized names by language code (non-null).
  /// e.g. { 'ko': '김치찌개', 'en': 'Kimchi Stew' }
  final Map<String, String> localizedNames;
  final String cuisine; // '한식', '양식', '일식', etc.
  final List<RecipeIngredient> ingredients;
  final int healthScore; // 1-5, 높을수록 건강

  Recipe({
    required this.id,
    Map<String, String>? localizedNames,
    String? name,
    this.cuisine = '한식',
    required this.ingredients,
    this.healthScore = 3,
  }) : localizedNames = localizedNames ??
           (name != null ? {'ko': name} : <String, String>{});

  Map<String, dynamic> toJson() => {
    'id': id,
    'localizedNames': localizedNames,
    'cuisine': cuisine,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'healthScore': healthScore,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final rawLocalized = json['localizedNames'];
    final Map<String, String> localized = rawLocalized != null
        ? Map<String, String>.from(rawLocalized as Map)
        : (json['name'] != null
            ? <String, String>{'en': json['name'] as String}
            : <String, String>{});

    return Recipe(
      id: json['id'] as String,
      localizedNames: localized,
      cuisine: json['cuisine'] as String? ?? '기타',
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      healthScore: json['healthScore'] as int? ?? 3,
    );
  }

  /// Computed compatibility `name` getter.
  String get name {
    return localizedNames['ko'] ??
        localizedNames['en'] ??
        (localizedNames.isNotEmpty ? localizedNames.values.first : '');
  }

  /// Return best display name for given language code.
  String nameForLocale(String languageCode) {
    if (localizedNames.containsKey(languageCode)) {
      return localizedNames[languageCode]!;
    }
    final langOnly = languageCode.split('-').first;
    if (localizedNames.containsKey(langOnly)) return localizedNames[langOnly]!;
    return localizedNames['en'] ?? name;
  }
}

class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
  };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }
}
