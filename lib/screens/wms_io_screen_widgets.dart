import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../services/consumable_inventory_service.dart';
import '../services/health_guardrail_service.dart';

/// 중복 품목 확인 다이얼로그
Future<bool?> showWmsDuplicateDialog(
  BuildContext context,
  ConsumableInventoryItem existing,
) {
  return showDialog<bool>(
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
}

/// 건강 태그 선택 위젯
class WmsHealthTagsSelector extends StatelessWidget {
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  const WmsHealthTagsSelector({
    super.key,
    required this.selectedTags,
    required this.onTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '건강 태그 (선택)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HealthGuardrailService.defaultTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (_) => onTagToggled(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 출고 탭
class WmsOutboundTab extends StatefulWidget {
  final String accountName;

  const WmsOutboundTab({super.key, required this.accountName});

  @override
  State<WmsOutboundTab> createState() => _WmsOutboundTabState();
}

class _WmsOutboundTabState extends State<WmsOutboundTab> {
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

    await ConsumableInventoryService.instance.useItem(
      _selectedItem!.id,
      quantity,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedItem!.name} $quantity개 출고 완료',
        ),
      ),
    );

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
              // 출고 품목 선택 (검색 가능하게 변경 - 바코드 스캐너 지원)
              Autocomplete<ConsumableInventoryItem>(
                displayStringForOption: (item) =>
                    '${item.name} (재고: ${item.currentStock}${item.unit})',
                initialValue: TextEditingValue(
                  text: _selectedItem != null ? _selectedItem!.name : '',
                ),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<ConsumableInventoryItem>.empty();
                  }
                  return items.where((item) {
                    final search = textEditingValue.text.toLowerCase();
                    return item.name.toLowerCase().contains(search) ||
                        item.id.toLowerCase().contains(search) ||
                        (item.barcode != null &&
                            item.barcode!.toLowerCase().contains(search));
                  });
                },
                onSelected: (item) {
                  setState(() => _selectedItem = item);
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: '출고 품목 검색 또는 스캔',
                      hintText: '이름 또는 바코드를 입력하세요',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (val) {
                      onFieldSubmitted();
                    },
                  );
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleOutbound(),
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleOutbound(),
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
