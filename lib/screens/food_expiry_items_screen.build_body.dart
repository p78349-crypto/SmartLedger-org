// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Main build method: scaffold, app bar, FAB, and body structure.
extension FoodExpiryBuildBodyExt on _FoodExpiryItemsScreenState {
  Widget buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTitle = widget.autoUsageMode ? '유통기한 관리' : '식료품/생활용품';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(appBarTitle),
        actions: [
          if (_isUsageMode)
            IconButton(
              onPressed: _showRecipePicker,
              icon: const Icon(Icons.menu_book),
              tooltip: '요리 불러오기',
            ),
          IconButton(
            onPressed: _toggleUsageMode,
            icon: Icon(_isUsageMode ? Icons.close : Icons.soup_kitchen),
            tooltip: _isUsageMode ? '사용량 입력 종료' : '요리/사용 모드 (일괄 입력)',
          ),
          if (!_isUsageMode)
            IconButton(
              onPressed: ConsumableInventoryService.instance.load,
              icon: const Icon(IconCatalog.refresh),
              tooltip: '새로고침',
            ),
        ],
      ),
      floatingActionButton:
          (_isUsageMode || _activeUsageItems.isNotEmpty) && _usageMap.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: _applyBulkUsage,
                  icon: const Icon(Icons.check),
                  label: Text('${_usageMap.length}개 적용'),
                )
              : null,
      body: ValueListenableBuilder<List<FoodExpiryItem>>(
        valueListenable: FoodExpiryService.instance.items,
        builder: (context, allItems, child) {
          final items = _locationFilter == null || _locationFilter == '전체'
              ? allItems
              : allItems
                    .where((it) => it.location == _locationFilter)
                    .toList();

          final ingredientNames = _normalizeIngredientNames(
            widget.initialIngredients,
          );

          final missingIngredients = <String>[];
          if (ingredientNames.isNotEmpty) {
            for (final ing in ingredientNames) {
              final hasAvailable = items.any(
                (it) => _ingredientMatchesItem(ing, it) && it.quantity > 0,
              );
              if (!hasAvailable) missingIngredients.add(ing);
            }
          }

          if (items.isEmpty && missingIngredients.isEmpty) {
            final emptyMsg = widget.autoUsageMode
                ? '등록된 유통기한 항목이 없습니다.\n하단 버튼으로 추가하세요.'
                : '등록된 식료품/생활용품이 없습니다.\n하단 버튼으로 품목을 추가하세요.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  emptyMsg,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: _locationOptions.map((loc) {
                    final isSelected = (_locationFilter ?? '전체') == loc;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(loc),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _locationFilter = loc == '전체' ? null : loc;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
              KeyedSubtree(
                key: _dailyRecipeSectionKey,
                child: const DailyRecipeRecommendationWidget(),
              ),
              const IngredientsRecommendationWidget(),
              const CostAnalysisWidget(),
              const UserPreferencesWidget(),
              if (!_isUsageMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              _showRecipePicker(onlyCookable: true),
                          icon: const Icon(Icons.soup_kitchen),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                          ),
                          label: const Text('보관 중인 식재료 요리'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.ingredientSearch,
                            );
                          },
                          icon: const Icon(Icons.search),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                          ),
                          label: const Text('추천 재료 비교'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (ingredientNames.isNotEmpty)
                buildIngredientComparisonPanel(
                  theme,
                  items,
                  ingredientNames,
                  missingIngredients,
                ),
              if (missingIngredients.isNotEmpty)
                buildMissingIngredientsPanel(theme, missingIngredients),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      buildItemTile(items[i], theme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
