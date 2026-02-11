part of 'quick_stock_use_utils.dart';

class _QuickStockUseSheet extends StatefulWidget {
  const _QuickStockUseSheet();

  @override
  State<_QuickStockUseSheet> createState() => _QuickStockUseSheetState();
}

class _QuickStockUseSheetState extends State<_QuickStockUseSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '1');
  final _nameFocus = FocusNode();

  ConsumableInventoryItem? _selectedItem;
  List<ConsumableInventoryItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    ConsumableInventoryService.instance.load();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final query = _nameController.text;
    setState(() {
      _suggestions = QuickStockUseUtils.searchItems(query);
      _selectedItem = QuickStockUseUtils.findExactItem(query);
    });
  }

  void _selectItem(ConsumableInventoryItem item) {
    setState(() {
      _nameController.text = item.name;
      _selectedItem = item;
      _suggestions = [];
    });
  }

  Future<void> _submit() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상품을 선택해주세요')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사용량을 입력해주세요')));
      return;
    }

    final success = await QuickStockUseUtils.useStock(
      itemId: _selectedItem!.id,
      amount: amount,
    );

    if (mounted) {
      if (success) {
        final remaining = (_selectedItem!.currentStock - amount).clamp(
          0.0,
          double.infinity,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedItem!.name} '
              '${amount.toStringAsFixed(0)}${_selectedItem!.unit} '
              '사용 완료\n'
              '남은 재고: '
              '${remaining.toStringAsFixed(0)}${_selectedItem!.unit}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차감 실패'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPadding + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '식료품/생활용품 사용기록',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '상품명',
              hintText: '휴지, 세제 등 입력',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _selectedItem != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),
          if (_suggestions.isNotEmpty && _selectedItem == null)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  final isLow = item.currentStock <= item.threshold;
                  return ListTile(
                    dense: true,
                    title: Text(item.name),
                    subtitle: Text(
                      '재고: ${item.currentStock.toStringAsFixed(0)}${item.unit}',
                      style: TextStyle(color: isLow ? Colors.orange : null),
                    ),
                    trailing: Text('📍${item.location}'),
                    onTap: () => _selectItem(item),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          if (_selectedItem != null) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedItem!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '현재 재고: '
                            '${_selectedItem!.currentStock.toStringAsFixed(0)}'
                            '${_selectedItem!.unit} '
                            '| 📍${_selectedItem!.location}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '사용량',
                    border: const OutlineInputBorder(),
                    suffixText: _selectedItem?.unit ?? '개',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...(_selectedItem != null && _selectedItem!.bundleSize > 1
                  ? [
                      ActionChip(
                        label: const Text('1묶음'),
                        onPressed: () {
                          _amountController.text = _selectedItem!.bundleSize
                              .toStringAsFixed(0);
                        },
                      ),
                      const SizedBox(width: 4),
                    ]
                  : []),
              ActionChip(
                label: const Text('1'),
                onPressed: () => _amountController.text = '1',
              ),
              const SizedBox(width: 4),
              ActionChip(
                label: const Text('5'),
                onPressed: () => _amountController.text = '5',
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _selectedItem != null ? _submit : null,
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('차감하기'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
