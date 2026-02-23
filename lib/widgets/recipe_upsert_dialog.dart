import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/shopping_cart_history_entry.dart';
import '../services/recipe_service.dart';
import '../services/user_pref_service.dart';
import 'recipe_upsert_sub_dialogs.dart';

class RecipeUpsertDialog extends StatefulWidget {
  final Recipe? existing;
  const RecipeUpsertDialog({super.key, this.existing});

  @override
  State<RecipeUpsertDialog> createState() => _RecipeUpsertDialogState();
}

class _RecipeUpsertDialogState extends State<RecipeUpsertDialog> {
  final List<String> _supportedLocales = [
    'ko',
    'en',
    'ja',
    'it',
    'fr',
    'es',
    'pl',
    'ru',
  ];
  late Map<String, TextEditingController> _localeControllers;
  final List<RecipeIngredient> _ingredients = [];
  String _cuisine = 'Korean';
  final List<String> _cuisines = [
    'Korean',
    'Western',
    'Japanese',
    'Chinese',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _localeControllers = {
      for (var l in _supportedLocales) l: TextEditingController()
    };
    if (widget.existing != null) {
      for (var e in widget.existing!.localizedNames.entries) {
        if (_localeControllers.containsKey(e.key)) {
          _localeControllers[e.key]!.text = e.value;
        } else {
          _localeControllers[e.key] = TextEditingController(text: e.value);
        }
      }
    }
    _cuisine = widget.existing?.cuisine ?? 'Korean';
    if (widget.existing != null) {
      _ingredients.addAll(widget.existing!.ingredients);
    }
  }

  @override
  void dispose() {
    for (final c in _localeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (ctx) => IngredientUpsertDialog(
        onAdd: (ingredient) {
          setState(() {
            _ingredients.add(ingredient);
          });
        },
      ),
    );
  }

  Future<void> _importFromHistory() async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) return;

    final history = await UserPrefService.getShoppingCartHistory(
      accountName: accountName,
    );
    if (!mounted) return;

    final selected = await showModalBottomSheet<List<ShoppingCartHistoryEntry>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => RecipeHistoryPicker(history: history),
    );

    if (selected != null) {
      setState(() {
        for (var item in selected) {
          _ingredients.add(
            RecipeIngredient(name: item.name, quantity: 1, unit: '개'),
          );
        }
      });
    }
  }

  Future<void> _save() async {
    final Map<String, String> localized = {};
    for (final entry in _localeControllers.entries) {
      final v = entry.value.text.trim();
      if (v.isNotEmpty) localized[entry.key] = v;
    }
    if (localized.isEmpty) return;

    final recipe = Recipe(
      id: widget.existing?.id ?? 'r_${DateTime.now().millisecondsSinceEpoch}',
      localizedNames: localized,
      cuisine: _cuisine,
      ingredients: _ingredients,
    );

    if (widget.existing == null) {
      await RecipeService.instance.addRecipe(recipe);
    } else {
      await RecipeService.instance.updateRecipe(recipe);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? '새 레시피 추가' : '레시피 수정',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // 다국어 이름 입력
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '레시피 이름',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._localeControllers.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: '언어: ${e.key}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _cuisines.contains(_cuisine) ? _cuisine : 'Other',
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              items: _cuisines
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _cuisine = v);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('식료품/생활용품 목록'),
                Row(
                  children: [
                    IconButton(
                      onPressed: _importFromHistory,
                      icon: const Icon(Icons.history),
                      tooltip: '쇼핑 기록에서 가져오기',
                    ),
                    IconButton(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add),
                      tooltip: '식료품/생활용품 직접 추가',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = _ingredients[index];
                    return ListTile(
                      title: Text(ing.name),
                      subtitle: Text('${ing.quantity} ${ing.unit}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _ingredients.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.existing != null)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('레시피 삭제'),
                          content: Text(
                            "'${widget.existing!.name}' 레시피를 삭제하시겠습니까?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                '삭제',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await RecipeService.instance.deleteRecipe(
                          widget.existing!.id,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('삭제'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('저장')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
