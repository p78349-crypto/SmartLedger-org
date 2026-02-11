import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';
import '../utils/ingredient_parsing_utils.dart';
import '../utils/nutrition_food_knowledge.dart';
import '../utils/shopping_prep_utils.dart';

part 'ingredient_search_list_screen_data.dart';
part 'ingredient_search_list_screen_cart.dart';
part 'ingredient_search_list_screen_list_ui.dart';

/// 식재료 검색 결과 화면
/// 검색어에 정확하게 매칭되는 식재료를 찾고,
/// 그 식재료와 함께 요리하면 좋은 모든 재료를 리스트로 표시
class IngredientSearchListScreen extends StatefulWidget {
  const IngredientSearchListScreen({
    super.key,
    this.searchQuery = '',
    this.customIngredients,
    this.dessertIngredients,
    this.onSelect,
  });

  final String searchQuery;
  final List<String>? customIngredients;
  final List<String>? dessertIngredients;
  final ValueChanged<String>? onSelect;

  @override
  State<IngredientSearchListScreen> createState() =>
      _IngredientSearchListScreenState();
}

class _IngredientSearchListScreenState
    extends State<IngredientSearchListScreen> {
  FoodKnowledgeEntry? _mainIngredient;
  List<PairingIngredient> _cookingList = [];
  List<PairingIngredient> _dessertList = [];
  bool _isSelectionMode = false; // 선택 모드 활성화 여부
  final Set<String> _selectedNames = {}; // 선택된 식재료 이름

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNames.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      final totalItems = _cookingList.length + _dessertList.length;
      if (_selectedNames.length == totalItems) {
        // 이미 모두 선택된 경우 해제
        _selectedNames.clear();
      } else {
        // 모두 선택
        _selectedNames.clear();
        for (final item in _cookingList) {
          _selectedNames.add(item.name);
        }
        for (final item in _dessertList) {
          _selectedNames.add(item.name);
        }
      }
    });
  }

  void _toggleItemSelection(String name) {
    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
      } else {
        _selectedNames.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustomMode = widget.customIngredients != null;

    // 주 식재료를 찾지 못한 경우 (검색 모드일 때만 체크)
    if (!isCustomMode && _mainIngredient == null) {
      return _buildSearchNotFoundView(theme);
    }

    // 목록이 비어있는 경우
    if (_cookingList.isEmpty && _dessertList.isEmpty) {
      return _buildEmptyListView(theme, isCustomMode);
    }

    final mainTitle = isCustomMode
        ? '재고 확인 및 선택'
        : '${_mainIngredient!.primaryName} 요리';
    final totalCount = _cookingList.length + _dessertList.length;
    final subTitle = isCustomMode
        ? '식재료 $totalCount개'
        : '필요한 재료 ($totalCount개)';

    // 페어링 재료 리스트 표시
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mainTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          // 전체 선택/해제 버튼 (선택 모드일 때만 표시)
          if (_isSelectionMode)
            TextButton(
              onPressed: _selectAll,
              child: Text(
                _selectedNames.length == totalCount ? '해제' : '전체',
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 0. 파싱 로직 안내 (간단한 헤더)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '상품명과 수량이 자동으로 분리되어 표시됩니다.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 1. 요리 재료 섹션
          if (_cookingList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '🍳 요리 식재료',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            _buildSliverList(theme, _cookingList),
          ],

          // 2. 후식 섹션
          if (_dessertList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🍰 후식 메뉴 추천',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildSliverList(theme, _dessertList),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.2,
              ),
            ),
          ),
        ),
        child: Row(
          children: [
            // 왼쪽: 선택 모드 토글 버튼
            FloatingActionButton.small(
              heroTag: 'selection_mode',
              onPressed: _toggleSelectionMode,
              backgroundColor: _isSelectionMode
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: _isSelectionMode
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              child: Icon(
                _isSelectionMode
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
            ),
            const SizedBox(width: 12),
            // 오른쪽: 쇼핑준비 보내기 버튼
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sendToShoppingPrep,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text(
                  _selectedNames.isEmpty
                      ? '쇼핑준비 보내기'
                      : '${_selectedNames.length}개 보내기',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
