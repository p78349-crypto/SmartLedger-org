part of 'consumable_inventory_screen.dart';

extension ConsumableInventoryUI on _ConsumableInventoryScreenState {
  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCartSelectionMode ? '장바구니 담기 선택' : '식료품/생활용품 관리'),
        bottom: _isCartSelectionMode
            ? null
            : TabBar(
                controller: _mainTabController,
                tabs: const [
                  Tab(icon: Icon(Icons.home), text: '집안 물품'),
                  Tab(icon: Icon(Icons.warehouse), text: '창고 보관'),
                ],
              ),
        actions: [
          if (!_isCartSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.shopping_cart_checkout),
              tooltip: '장바구니 퀵 추가 모드',
              onPressed: () => setState(() => _isCartSelectionMode = true),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: '개수형 단위 설정',
              onPressed: _showCountLikeUnitsDialog,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddItemDialog,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: '전체 선택',
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isCartSelectionMode = false;
                  _selectedForCartIds.clear();
                });
              },
            ),
          ],
        ],
      ),
      floatingActionButton: _isCartSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        WmsIoScreen(accountName: widget.accountName),
                  ),
                );
              },
              tooltip: 'WMS 입출고',
              child: const Icon(Icons.add),
            ),
      body: ValueListenableBuilder<List<ConsumableInventoryItem>>(
        // ✅ Gateway 캐싱 적용 후에도 실시간 업데이트 유지
        valueListenable: ConsumableInventoryService.instance.items,
        builder: (context, items, _) {
          // 0: 집안 (창고 제외), 1: 창고 (창고 전용)
          final isWarehouseTab = _mainTabController.index == 1;
          final tabItems = items.where((e) {
            if (isWarehouseTab) {
              return e.location == '창고';
            } else {
              return e.location != '창고';
            }
          }).toList();

          final locFiltered = _locationFilter == '전체'
              ? tabItems
              : tabItems.where((e) => e.location == _locationFilter).toList();

          final filteredItems = _categoryFilter == '전체'
              ? locFiltered
              : locFiltered
                    .where((e) => e.category == _categoryFilter)
                    .toList();

          final expiryFilteredItems = _expiryFilter == '전체'
              ? filteredItems
              : _expiryFilter == '임박'
              ? filteredItems.where((e) => e.isExpiringWithin()).toList()
              : filteredItems.where((e) => e.isExpired()).toList();

          final finalItems = expiryFilteredItems;

          return Column(
            children: [
              // 통합 필터 라인 (가로 스크롤)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // 1. 장소 필터 (집안 탭일 때만)
                    if (!isWarehouseTab) ...[
                      ..._locationOptions.map(
                        (v) => _buildCompactFilterChip(
                          label: v,
                          selected: _locationFilter == v,
                          onSelected: (sel) =>
                              setState(() => _locationFilter = v),
                          color: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                      _buildDivider(),
                    ],
                    // 2. 분류 필터
                    ..._categoryOptions.map(
                      (v) => _buildCompactFilterChip(
                        label: v,
                        selected: _categoryFilter == v,
                        onSelected: (sel) =>
                            setState(() => _categoryFilter = v),
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                    _buildDivider(),
                    // 3. 상태 필터
                    ..._expiryOptions.map(
                      (v) => _buildCompactFilterChip(
                        label: v,
                        selected: _expiryFilter == v,
                        onSelected: (sel) => setState(() => _expiryFilter = v),
                        color: Colors.orange.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: finalItems.isEmpty
                    ? Center(
                        child: Text(
                          _locationFilter == '전체'
                              ? _expiryFilter == '전체'
                                    ? '등록된 항목이 없습니다.\n우측 상단 + 버튼으로 추가하세요.'
                                    : '$_expiryFilter 항목이 없습니다.'
                              : '$_locationFilter에 등록된 항목이 없습니다.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: finalItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = finalItems[index];
                          return ConsumableItemCard(
                            item: item,
                            isCountLikeUnit: _isCountLikeUnit(item.unit),
                            formatQty: _formatQty,
                            isSelected: _selectedForCartIds.contains(item.id),
                            onSelected: _isCartSelectionMode
                                ? (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedForCartIds.add(item.id);
                                      } else {
                                        _selectedForCartIds.remove(item.id);
                                      }
                                    });
                                  }
                                : null,
                            onQuickDecrement: () => _quickDecrementOne(item),
                            onUse: () => _useItem(item),
                            onRefill: () => _refillItem(item),
                            onSendToCart: () => _sendToCart(item),
                            onEdit: () => _showEditItemDialog(item),
                          );
                        },
                      ),
              ),
              if (_isCartSelectionMode)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.shopping_cart),
                        label: Text(
                          '${_selectedForCartIds.length}개 항목 장바구니에 추가',
                        ),
                        onPressed: _selectedForCartIds.isEmpty
                            ? null
                            : _addSelectedToCart,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        onSelected: onSelected,
        visualDensity: VisualDensity.compact,
        backgroundColor: color,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }
}
