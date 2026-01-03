class Recipe {
  final String id;
  final String name;
  final String cuisine; // '한식', '양식', '일식', etc.
  final List<RecipeIngredient> ingredients;

  Recipe({
    required this.id,
    required this.name,
    this.cuisine = '한식',
    required this.ingredients,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cuisine': cuisine,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
  };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      cuisine: json['cuisine'] as String? ?? '기타',
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
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
