// ignore_for_file: invalid_use_of_protected_member
part of 'quick_stock_use_screen.dart';

/// Extension: main build method.
extension QuickStockBuild on _QuickStockUseBodyState {
  Widget _buildMain(BuildContext context) {
    final items = ConsumableInventoryService.instance.items.value;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Voice / simple guidance card ──
          if (AppConstants.voiceInputEnabled)
            _buildVoiceInputCard(colorScheme)
          else
            Card(
              color: colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('상품명 입력 → 사용량 입력 → ENT',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // ── 상품명 입력 ──
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '상품명',
              hintText: '휴지, 세제, 샴푸 등',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 16),
              suffixIcon: _selectedItem != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),

          // ── 자동완성 목록 ──
          if ((_suggestions.isNotEmpty || _historySuggestions.isNotEmpty) &&
              _selectedItem == null)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in _suggestions) ...[
                    _buildSuggestionTile(item),
                  ],
                  if (_suggestions.isEmpty && _historySuggestions.isNotEmpty)
                    const Divider(height: 1),
                  for (final name in _historySuggestions) ...[
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.history, size: 18)),
                      title: Text(name),
                      subtitle: const Text(
                        '쇼핑 기록에서 찾음 (탭하면 등록 후 선택)'),
                      onTap: () => _createAndSelectByName(name),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 16),

          _buildPrimaryActionRow(),

          const SizedBox(height: 16),

          // ── 사용량 입력 + 장바구니 버튼 ──
          Builder(
            builder: (context) {
              final productUnit = _getProductUnit(
                _selectedItem?.name ?? _nameController.text);
              final displayUnit =
                  _selectedItem?.unit ?? productUnit?.unit ?? '개';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            labelText: '사용량',
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                            suffixText: displayUnit,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 108, height: 56,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.shoppingCart,
                              arguments: route_args.ShoppingCartArgs(
                                accountName: widget.accountName),
                            );
                          },
                          child: const Text('장바구니'),
                        ),
                      ),
                    ],
                  ),
                  if (productUnit != null) ...[
                    const SizedBox(height: 8),
                    _buildWeightPriceHint(productUnit),
                  ],
                ],
              );
            },
          ),

          // ── 선택된 상품 상세 카드 ──
          if (_selectedItem != null) ...[
            const SizedBox(height: 16),
            _buildSelectedItemCard(context),
          ],

          // ── 최근 차감 기록 ──
          ..._buildRecentUsesList(context),

          // ── 등록된 재고가 없을 때 ──
          if (items.isEmpty) ...[
            const SizedBox(height: 32),
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 32, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      '등록된 재고가 없습니다.\n먼저 소모품 재고 화면에서 상품을 등록해주세요.',
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Recent uses list (returns a list of widgets to spread into Column).
  List<Widget> _buildRecentUsesList(BuildContext context) {
    if (_recentUses.isEmpty) return const [];

    return [
      const SizedBox(height: 32),
      Text('최근 차감 기록', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...(_recentUses.map((r) {
        final hasShortage = r.shortage > 0;
        final isEmpty = r.remaining == 0;
        final minute = r.time.minute.toString().padLeft(2, '0');
        final timeLabel = '${r.time.hour}:$minute';

        return Card(
          color: hasShortage
              ? Colors.orange.shade50
              : isEmpty ? Colors.red.shade50 : null,
          child: ListTile(
            leading: Icon(
              hasShortage
                  ? Icons.shopping_cart
                  : isEmpty ? Icons.warning : Icons.check_circle,
              color: hasShortage
                  ? Colors.orange
                  : isEmpty ? Colors.red : Colors.green,
            ),
            title: Text(
              '${r.name} -${r.amount.toStringAsFixed(0)}${r.unit}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmpty
                      ? '⚠️ 재고 없음!'
                      : '남은 재고: '
                            '${r.remaining.toStringAsFixed(0)}${r.unit}',
                  style: TextStyle(
                    color: isEmpty ? Colors.red : null,
                    fontWeight: isEmpty ? FontWeight.bold : null),
                ),
                if (hasShortage)
                  Text(
                    '🛒 부족분 '
                    '${r.shortage.toStringAsFixed(0)}${r.unit} '
                    '장바구니 추가됨',
                    style: const TextStyle(color: Colors.orange)),
              ],
            ),
            trailing: Text(timeLabel,
              style: Theme.of(context).textTheme.bodySmall),
            isThreeLine: hasShortage,
          ),
        );
      })),
    ];
  }
}
