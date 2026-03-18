import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_edit_screen_widgets.dart';
import 'recipe_ingredient_dialog.dart';

/// 레시피 편집 화면
/// - 새 레시피 작성
/// - 기존 레시피 수정
/// - 추천 레시피 복사 후 편집
class RecipeEditScreen extends StatefulWidget {
  const RecipeEditScreen({
    super.key,
    required this.accountName,
    this.recipe,
    this.isNewFromRecommended = false,
  });

  final String accountName;
  final Recipe? recipe;
  final bool isNewFromRecommended;

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipeNameController;
  late String _cuisine;
  late int _healthScore;
  late List<RecipeIngredient> _ingredients;
  bool _saving = false;

  bool get _isEditing => widget.recipe != null && !widget.isNewFromRecommended;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _recipeNameController = TextEditingController(
      text: recipe?.nameForLocale('ko') ?? '',
    );
    _cuisine = recipe?.cuisine ?? '한식';
    _healthScore = recipe?.healthScore ?? 3;
    _ingredients = recipe?.ingredients.toList() ?? [];
  }

  @override
  void dispose() {
    _recipeNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('레시피 이름을 입력해주세요')));
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('재료를 최소 1개 이상 추가해주세요')));
      return;
    }

    setState(() => _saving = true);

    try {
      final id = _isEditing
          ? widget.recipe!.id
          : 'user_${DateTime.now().millisecondsSinceEpoch}';

      final recipeName = _recipeNameController.text.trim();
      final recipe = Recipe(
        id: id,
        localizedNames: {'ko': recipeName},
        cuisine: _cuisine,
        ingredients: _ingredients,
        healthScore: _healthScore,
      );

      if (_isEditing) {
        await RecipeService.instance.updateRecipe(recipe);
      } else {
        await RecipeService.instance.addRecipe(recipe);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? '레시피가 수정되었습니다' : '레시피가 저장되었습니다')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => RecipeIngredientDialog(
        onSave: (ingredient) {
          setState(() => _ingredients.add(ingredient));
        },
      ),
    );
  }

  void _editIngredient(int index) {
    showDialog(
      context: context,
      builder: (context) => RecipeIngredientDialog(
        existing: _ingredients[index],
        onSave: (ingredient) {
          setState(() => _ingredients[index] = ingredient);
        },
      ),
    );
  }

  void _removeIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isEditing
        ? '레시피 수정'
        : widget.isNewFromRecommended
        ? '내 레시피로 저장'
        : '새 레시피 작성';

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 레시피 이름 (한국어만)
            TextFormField(
              controller: _recipeNameController,
              decoration: const InputDecoration(
                labelText: '음식 이름',
                hintText: '예: 비빔밥, 김치찌개',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '레시피 이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 요리 종류 + 재료 추가 + 저장 (같은 라인, 동일 너비)
            Row(
              children: [
                // 요리 종류 (왼쪽)
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: DropdownButtonFormField<String>(
                      initialValue: _cuisine,
                      decoration: const InputDecoration(
                        labelText: '요리 종류',
                        border: OutlineInputBorder(),
                        isDense: true,
                        constraints: BoxConstraints(minHeight: 56),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        labelStyle: TextStyle(fontSize: 12),
                        floatingLabelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      items: const [
                        DropdownMenuItem(value: '한식', child: Text('한식')),
                        DropdownMenuItem(value: '양식', child: Text('양식')),
                        DropdownMenuItem(value: '중식', child: Text('중식')),
                        DropdownMenuItem(value: '일식', child: Text('일식')),
                        DropdownMenuItem(value: '분식', child: Text('분식')),
                        DropdownMenuItem(value: '기타', child: Text('기타')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _cuisine = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 재료 추가 (중앙) - 아이콘만 표시
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _addIngredient,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 저장 버튼 (오른쪽) - 텍스트 크기 조정
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _saving ? '저장중' : 'ENT',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 건강 점수
            HealthScoreSelector(
              score: _healthScore,
              onChanged: (s) => setState(() => _healthScore = s),
            ),

            const Divider(height: 32),

            // 재료 목록
            Text('재료 목록', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            if (_ingredients.isEmpty)
              const EmptyIngredientsPlaceholder()
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredients.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _ingredients.removeAt(oldIndex);
                    _ingredients.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final ing = _ingredients[index];
                  return Card(
                    key: ValueKey('ingredient_$index'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(ing.name),
                      subtitle: Text('${ing.quantity} ${ing.unit}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editIngredient(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeIngredient(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
