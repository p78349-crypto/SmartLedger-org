import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

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
  late TextEditingController _nameController;
  late String _cuisine;
  late int _healthScore;
  late List<RecipeIngredient> _ingredients;
  bool _saving = false;

  bool get _isEditing => widget.recipe != null && !widget.isNewFromRecommended;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _nameController = TextEditingController(text: recipe?.name ?? '');
    _cuisine = recipe?.cuisine ?? '한식';
    _healthScore = recipe?.healthScore ?? 3;
    _ingredients = recipe?.ingredients.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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

      final recipe = Recipe(
        id: id,
        name: _nameController.text.trim(),
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
      builder: (context) => _IngredientDialog(
        onSave: (ingredient) {
          setState(() => _ingredients.add(ingredient));
        },
      ),
    );
  }

  void _editIngredient(int index) {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
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
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 레시피 이름
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '레시피 이름 *',
                hintText: '예: 김치찌개',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '레시피 이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 요리 종류
            DropdownButtonFormField<String>(
              initialValue: _cuisine,
              decoration: const InputDecoration(
                labelText: '요리 종류',
                border: OutlineInputBorder(),
              ),
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
            const SizedBox(height: 16),

            // 건강 점수
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('건강 점수', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final score = index + 1;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _healthScore = score),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _healthScore >= score
                                ? theme.colorScheme.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: _healthScore >= score
                                ? Colors.white
                                : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _healthScore >= 4
                      ? '매우 건강해요!'
                      : _healthScore >= 3
                      ? '적당해요'
                      : '가끔 먹어요',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const Divider(height: 32),

            // 재료 목록
            Row(
              children: [
                Text('재료 목록', style: theme.textTheme.titleMedium),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('재료 추가'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_ingredients.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.egg_alt_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '아직 재료가 없습니다',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '재료 추가 버튼을 눌러 추가해주세요',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              )
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

            const SizedBox(height: 80), // FAB 공간
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.save),
        label: const Text('저장'),
      ),
    );
  }
}

/// 재료 추가/편집 다이얼로그
class _IngredientDialog extends StatefulWidget {
  const _IngredientDialog({this.existing, required this.onSave});

  final RecipeIngredient? existing;
  final void Function(RecipeIngredient) onSave;

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late String _unit;

  static const _units = ['g', 'kg', 'ml', 'L', '개', '장', '줌', '큰술', '작은술', '컵'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.existing?.quantity.toString() ?? '',
    );
    _unit = widget.existing?.unit ?? 'g';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('재료 이름을 입력해주세요')));
      return;
    }
    if (quantity <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수량을 올바르게 입력해주세요')));
      return;
    }

    widget.onSave(
      RecipeIngredient(name: name, quantity: quantity, unit: _unit),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '재료 추가' : '재료 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '재료 이름',
              hintText: '예: 돼지고기',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: '수량',
                    hintText: '예: 200',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: '단위'),
                  items: _units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _unit = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _save, child: const Text('확인')),
      ],
    );
  }
}
