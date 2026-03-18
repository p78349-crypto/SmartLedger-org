// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_cart_screen.dart';

/// Extension: main build method.
extension ShoppingCartBuild on _ShoppingCartScreenState {
  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    const nameFieldHeight = 48.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final ordered = _orderedItems(_items);
    final checkedCount = _items.where((i) => i.isChecked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        actions: [
          IconButton(
            tooltip: '초기화',
            onPressed: _isLoading ? null : _confirmResetAll,
            icon: const Icon(Icons.restart_alt),
          ),
          TextButton(
            onPressed: _isLoading ? null : _openRecentPurchasePicker,
            child: const Text('최근 구매'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isPortrait ? 72 : 56),
          child: Padding(
            padding: isPortrait
                ? const EdgeInsets.fromLTRB(16, 6, 16, 10)
                : const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: isPortrait ? nameFieldHeight : 44,
                    child: SmartInputField(
                      compact: true,
                      label: '상품명',
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _addItem(keepKeyboardOpen: true),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: isPortrait ? nameFieldHeight : 44,
                  child: FilledButton(
                    onPressed: () => _addItem(keepKeyboardOpen: true),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: !_isLoading
          ? _buildCheckedSummaryBar(theme: theme, checkedCount: checkedCount)
          : null,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (ordered.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    '구매 예정 물품을 등록하세요.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.only(bottom: bottomInset + 24),
                        itemCount: ordered.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          final item = ordered[index];

                          _qtyControllers.putIfAbsent(item.id, () {
                            final val = item.bundleCount < 0
                                ? 0
                                : item.bundleCount;
                            return TextEditingController(
                              text: val == 0 ? '' : val.toString(),
                            );
                          });
                          _unitPriceControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(
                              text: _unitPriceTextForInlineEditor(
                                item.unitPrice,
                              ),
                            ),
                          );
                          _bundleSizeControllers.putIfAbsent(item.id, () {
                            final val = item.unitsPerBundle < 0
                                ? 0
                                : item.unitsPerBundle;
                            return TextEditingController(
                              text: val == 0 ? '' : val.toString(),
                            );
                          });
                          _memoControllers.putIfAbsent(
                            item.id,
                            () => TextEditingController(text: item.memo),
                          );
                          _qtyFocusNodes.putIfAbsent(item.id, FocusNode.new);
                          _bundleSizeFocusNodes.putIfAbsent(
                            item.id,
                            FocusNode.new,
                          );
                          _unitPriceFocusNodes.putIfAbsent(
                            item.id,
                            FocusNode.new,
                          );
                          _memoFocusNodes.putIfAbsent(item.id, FocusNode.new);

                          final qtyCtrl = _qtyControllers[item.id]!;
                          final bundleCtrl = _bundleSizeControllers[item.id]!;
                          final unitCtrl = _unitPriceControllers[item.id]!;
                          final memoCtrl = _memoControllers[item.id]!;
                          final qtyFn = _qtyFocusNodes[item.id]!;
                          final bundleFn = _bundleSizeFocusNodes[item.id]!;
                          final unitFn = _unitPriceFocusNodes[item.id]!;
                          final memoFn = _memoFocusNodes[item.id]!;

                          return isPortrait
                              ? _buildPortraitItemTile(
                                  context: context,
                                  theme: theme,
                                  item: item,
                                  index: index,
                                  ordered: ordered,
                                  qtyController: qtyCtrl,
                                  bundleSizeController: bundleCtrl,
                                  unitController: unitCtrl,
                                  qtyFocusNode: qtyFn,
                                  bundleSizeFocusNode: bundleFn,
                                  unitFocusNode: unitFn,
                                )
                              : _buildWideItemTile(
                                  context: context,
                                  item: item,
                                  qtyController: qtyCtrl,
                                  bundleSizeController: bundleCtrl,
                                  unitController: unitCtrl,
                                  memoController: memoCtrl,
                                  qtyFocusNode: qtyFn,
                                  bundleSizeFocusNode: bundleFn,
                                  unitFocusNode: unitFn,
                                  memoFocusNode: memoFn,
                                  theme: theme,
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Checked-items summary bottom bar ──
  Widget _buildCheckedSummaryBar({
    required ThemeData theme,
    required int checkedCount,
  }) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final checkedTotal = _items.where((i) => i.isChecked).fold<double>(0, (
      sum,
      item,
    ) {
      final qty = item.quantity < 0 ? 0 : item.quantity;
      return sum + (item.unitPrice * qty);
    });

    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // 레시피 메뉴로 돌아가기 버튼
              IconButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.recipeManagement,
                  arguments: RecipeManagementArgs(
                    accountName: widget.accountName,
                  ),
                ),
                icon: const Icon(Icons.restaurant_menu),
                tooltip: '레시피 메뉴',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('체크 항목', style: theme.textTheme.labelSmall),
                    Text(
                      CurrencyFormatter.format(checkedTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
