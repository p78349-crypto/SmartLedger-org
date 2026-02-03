import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../services/consumable_inventory_service.dart';
import '../services/health_guardrail_service.dart';
import '../utils/wms_data_gateway.dart';

/// WMS 입출고 화면 (Input/Output)
class WmsIoScreen extends StatefulWidget {
  final String accountName;

  const WmsIoScreen({super.key, required this.accountName});

  @override
  State<WmsIoScreen> createState() => _WmsIoScreenState();
}

class _WmsIoScreenState extends State<WmsIoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WMS 입출고'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_box), text: '입고'),
            Tab(icon: Icon(Icons.remove_circle_outline), text: '출고'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InboundTab(accountName: widget.accountName),
          _OutboundTab(accountName: widget.accountName),
        ],
      ),
    );
  }
}

/// 입고 탭
class _InboundTab extends StatefulWidget {
  final String accountName;

  const _InboundTab({required this.accountName});

  @override
  State<_InboundTab> createState() => _InboundTabState();
}

class _InboundTabState extends State<_InboundTab> {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '1');
  final _bundleSizeController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: '개');
  String _selectedLocation = '기타';
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _bundleSizeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _handleInbound() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목명을 입력하세요')),
      );
      return;
    }

    final stock = double.tryParse(_stockController.text) ?? 0.0;
    final threshold = double.tryParse(
      _thresholdController.text,
    ) ?? 1.0;
    final bundleSize = double.tryParse(
      _bundleSizeController.text,
    ) ?? 1.0;
    final unit = _unitController.text.trim();

    final input = WmsInventoryInput.full(
      name: name,
      currentStock: stock,
      unit: unit,
      threshold: threshold,
      bundleSize: bundleSize,
      location: _selectedLocation,
      healthTags: _selectedTags.toList(),
    );

    final result = await WmsInventoryGateway.instance.addItem(
      input: input,
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.data?.name} 입고 완료')),
      );
      _clearForm();
    } else if (result.type == WmsOperationType.duplicate) {
      _showDuplicateDialog(result.data!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('입고 실패: ${result.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _stockController.text = '0';
    _thresholdController.text = '1';
    _bundleSizeController.text = '1';
    _unitController.text = '개';
    setState(() {
      _selectedLocation = '기타';
      _selectedTags.clear();
    });
  }

  Future<void> _showDuplicateDialog(
    ConsumableInventoryItem existing,
  ) async {
    final addMore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이미 존재하는 품목'),
        content: Text(
          '${existing.name}이(가) 이미 등록되어 있습니다.\n'
          '현재 재고: ${existing.currentStock}${existing.unit}\n\n'
          '입력한 수량을 추가하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (addMore == true) {
      final addStock = double.tryParse(_stockController.text) ?? 0.0;
      final updated = existing.copyWith(
        currentStock: existing.currentStock + addStock,
      );
      await ConsumableInventoryService.instance.updateItem(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${existing.name}에 $addStock개 추가 완료'),
        ),
      );
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '품목명',
              hintText: '예: 휴지, 세제',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: '입고 수량',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: '단위',
                    hintText: '개, 롤',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedLocation,
            decoration: const InputDecoration(
              labelText: '보관 위치',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place),
            ),
            items: ConsumableInventoryItem.locationOptions
                .map(
                  (loc) => DropdownMenuItem(
                    value: loc,
                    child: Text(loc),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedLocation = val);
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            decoration: const InputDecoration(
              labelText: '알림 기준',
              hintText: '재고가 이 수량 이하일 때 알림',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notifications),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bundleSizeController,
            decoration: const InputDecoration(
              labelText: '묶음 단위',
              hintText: '예: 30롤 묶음이면 30',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.widgets),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '건강 태그 (선택)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HealthGuardrailService.defaultTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _handleInbound,
            icon: const Icon(Icons.add_box),
            label: const Text('입고 처리'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// 출고 탭
class _OutboundTab extends StatefulWidget {
  final String accountName;

  const _OutboundTab({required this.accountName});

  @override
  State<_OutboundTab> createState() => _OutboundTabState();
}

class _OutboundTabState extends State<_OutboundTab> {
  ConsumableInventoryItem? _selectedItem;
  final _quantityController = TextEditingController(text: '1');
  final _memoController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _handleOutbound() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목을 선택하세요')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출고 수량을 입력하세요')),
      );
      return;
    }

    final warning = await ConsumableInventoryService.instance.useItem(
      _selectedItem!.id,
      quantity,
    );

    if (!mounted) return;

    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warning.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedItem!.name} $quantity개 출고 완료',
          ),
        ),
      );
    }

    _clearForm();
  }

  void _clearForm() {
    setState(() {
      _selectedItem = null;
      _quantityController.text = '1';
      _memoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ConsumableInventoryItem>>(
      valueListenable: ConsumableInventoryService.instance.items,
      builder: (context, items, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ConsumableInventoryItem>(
                initialValue: _selectedItem,
                decoration: const InputDecoration(
                  labelText: '출고 품목 선택',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                hint: const Text('품목을 선택하세요'),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      '${item.name} (재고: ${item.currentStock}'
                      '${item.unit})',
                    ),
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() => _selectedItem = item);
                },
              ),
              if (_selectedItem != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '현재 재고 정보',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('품목: ${_selectedItem!.name}'),
                        Text(
                          '현재고: ${_selectedItem!.currentStock}'
                          '${_selectedItem!.unit}',
                        ),
                        Text('보관 위치: ${_selectedItem!.location}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: '출고 수량',
                    border: const OutlineInputBorder(),
                    suffixText: _selectedItem!.unit,
                    prefixIcon: const Icon(Icons.remove_circle),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    labelText: '출고 사유 (선택)',
                    hintText: '예: 사용, 폐기, 이동',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _handleOutbound,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('출고 처리'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.error,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onError,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
