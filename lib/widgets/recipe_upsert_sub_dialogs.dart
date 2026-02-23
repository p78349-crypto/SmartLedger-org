import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/shopping_cart_history_entry.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';
import '../utils/debounce_utils.dart';
import '../utils/korean_search_utils.dart';

/// 식료품/생활용품 추가 다이얼로그
class IngredientUpsertDialog extends StatefulWidget {
  final Function(RecipeIngredient) onAdd;
  const IngredientUpsertDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<IngredientUpsertDialog> createState() =>
      _IngredientUpsertDialogState();
}

class _IngredientUpsertDialogState
    extends State<IngredientUpsertDialog> {
  final _nameController = TextEditingController();
  final _qtyController =
      TextEditingController(text: '1');
  final _unitController =
      TextEditingController(text: '개');
  final Debouncer _suggestionDebouncer = Debouncer(
    delay: const Duration(milliseconds: 120),
  );
  List<String> _suggestions = [];
  List<String> _allPossibleNames = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final inventory = ConsumableInventoryService
        .instance.items.value
        .map((e) => e.name)
        .toList();
    final accountName =
        await UserPrefService.getLastAccountName();
    List<String> history = [];
    if (accountName != null) {
      final h =
          await UserPrefService.getShoppingCartHistory(
        accountName: accountName,
      );
      history = h.map((e) => e.name).toList();
    }
    setState(() {
      _allPossibleNames =
          {...inventory, ...history}.toList();
    });
  }

  void _updateSuggestions(String query) {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _suggestions = _allPossibleNames
          .where(
            (name) => MultilingualSearchUtils.matches(
              name,
              query,
            ),
          )
          .take(5)
          .toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _suggestionDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('식료품/생활용품 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '품목명',
              hintText: '예: 아몬드 분말',
            ),
            autofocus: true,
            onChanged: (query) {
              _suggestionDebouncer
                  .run(() => _updateSuggestions(query));
            },
          ),
          if (_suggestions.isNotEmpty)
            Container(
              constraints:
                  const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (ctx, i) {
                  final name = _suggestions[i];
                  return ListTile(
                    title: Text(name),
                    dense: true,
                    onTap: () {
                      setState(() {
                        _nameController.text = name;
                        _suggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  decoration: const InputDecoration(
                    labelText: '수량',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: '단위',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final qty =
                double.tryParse(_qtyController.text) ??
                    0;
            final unit = _unitController.text.trim();
            if (name.isNotEmpty && qty > 0) {
              widget.onAdd(
                RecipeIngredient(
                  name: name,
                  quantity: qty,
                  unit: unit,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}

/// 쇼핑 기록에서 재료 선택 피커
class RecipeHistoryPicker extends StatefulWidget {
  final List<ShoppingCartHistoryEntry> history;
  const RecipeHistoryPicker({
    super.key,
    required this.history,
  });

  @override
  State<RecipeHistoryPicker> createState() =>
      _RecipeHistoryPickerState();
}

class _RecipeHistoryPickerState
    extends State<RecipeHistoryPicker> {
  final Set<ShoppingCartHistoryEntry> _selected = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: const Text('Select from History'),
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _selected.toList(),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.history.length,
                itemBuilder: (context, index) {
                  final item = widget.history[index];
                  final isSelected =
                      _selected.contains(item);
                  return ListTile(
                    title: Text(item.name),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          )
                        : const Icon(
                            Icons.circle_outlined,
                          ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(item);
                        } else {
                          _selected.add(item);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
