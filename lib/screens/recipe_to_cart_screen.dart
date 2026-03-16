import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/shopping_cart_item.dart';
import '../services/user_pref_service.dart';
import 'shopping_cart_screen.dart';

/// 레시피 재료 → 장바구니 전송 화면
/// - 재료 목록 표시 (체크박스로 선택)
/// - 수량 조절 가능
/// - 선택한 재료만 장바구니에 추가
class RecipeToCartScreen extends StatefulWidget {
  const RecipeToCartScreen({
    super.key,
    required this.accountName,
    required this.recipe,
  });

  final String accountName;
  final Recipe recipe;

  @override
  State<RecipeToCartScreen> createState() => _RecipeToCartScreenState();
}

class _RecipeToCartScreenState extends State<RecipeToCartScreen> {
  late Map<int, bool> _selectedItems;
  late Map<int, double> _quantities;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // 모든 재료 기본 선택
    _selectedItems = {
      for (var i = 0; i < widget.recipe.ingredients.length; i++) i: true,
    };
    // 모든 레시피 재료 수량을 1개로 통일
    _quantities = {
      for (var i = 0; i < widget.recipe.ingredients.length; i++) i: 1,
    };
  }

  int get _selectedCount => _selectedItems.values.where((v) => v).length;

  Future<void> _sendToCart() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1개 이상의 재료를 선택해주세요')));
      return;
    }

    setState(() => _sending = true);
    final lang = Localizations.localeOf(context).languageCode;

    try {
      // 기존 장바구니 아이템 로드
      final existingItems = await UserPrefService.getShoppingCartItems(
        accountName: widget.accountName,
      );

      final now = DateTime.now();
      final newItems = <ShoppingCartItem>[];

      // 선택된 재료만 장바구니에 추가
      for (var i = 0; i < widget.recipe.ingredients.length; i++) {
        if (_selectedItems[i] != true) continue;

        final ing = widget.recipe.ingredients[i];
        final quantity = _quantities[i] ?? ing.quantity;

        final item = ShoppingCartItem(
          id: '${now.millisecondsSinceEpoch}_$i',
          name: ing.name,
          quantity: quantity.toInt().clamp(1, 999),
          unitLabel: ing.unit,
          memo: widget.recipe.nameForLocale(lang),
          createdAt: now,
          updatedAt: now,
        );

        newItems.add(item);
      }

      // 기존 아이템 하단에 새 아이템 추가
      final allItems = [...existingItems, ...newItems];

      // 저장
      await UserPrefService.setShoppingCartItems(
        accountName: widget.accountName,
        items: allItems,
      );

      if (mounted) {
        // Replace the Recipe->RecipeToCart route with the ShoppingCart route
        // so that the cart's back button returns the user to the recipe screen.
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => ShoppingCartScreen(
              accountName: widget.accountName,
              initialItems: newItems,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('장바구니 추가 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _toggleAll(bool? value) {
    setState(() {
      for (var i = 0; i < widget.recipe.ingredients.length; i++) {
        _selectedItems[i] = value ?? false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingredients = widget.recipe.ingredients;
    final allSelected = _selectedItems.values.every((v) => v);

    return Scaffold(
      appBar: AppBar(title: const Text('장바구니에 추가'), centerTitle: true),
      body: Column(
        children: [
          // 레시피 정보 헤더
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipe.nameForLocale(Localizations.localeOf(context).languageCode),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '재료 ${ingredients.length}개',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 전체 선택 체크박스
          CheckboxListTile(
            value: allSelected,
            onChanged: _toggleAll,
            title: Text('전체 선택 ($_selectedCount/${ingredients.length})'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const Divider(height: 1),

          // 재료 목록
          Expanded(
            child: ListView.builder(
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ing = ingredients[index];
                final selected = _selectedItems[index] ?? false;
                final quantity = _quantities[index] ?? ing.quantity;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (value) {
                            setState(
                              () => _selectedItems[index] = value ?? false,
                            );
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ing.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  decoration: selected
                                      ? null
                                      : TextDecoration.lineThrough,
                                  color: selected ? null : Colors.grey,
                                ),
                              ),
                              Text(
                                '원래: ${ing.quantity} ${ing.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 수량 조절
                        if (selected) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: quantity > 1
                                ? () {
                                    setState(() {
                                      _quantities[index] = quantity - 1;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            '${quantity.toInt()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                _quantities[index] = quantity + 1;
                              });
                            },
                          ),
                        ],
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 하단 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    minimumSize: const Size.fromHeight(52),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _sending || _selectedCount == 0
                      ? null
                      : _sendToCart,
                  icon: _sending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.shopping_cart),
                  label: Text(
                    _selectedCount == 0
                        ? '재료를 선택해주세요'
                        : '$_selectedCount개 재료 장바구니에 추가',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
