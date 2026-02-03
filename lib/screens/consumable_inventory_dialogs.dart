import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../services/consumable_inventory_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/user_pref_service.dart';
import '../utils/wms_data_gateway.dart';

/// 개수형 단위 설정 다이얼로그
class ConsumableInventoryDialogs {
  ConsumableInventoryDialogs._();

  /// 개수형 단위 설정 다이얼로그 표시
  static Future<List<String>?> showCountLikeUnitsDialog({
    required BuildContext context,
    required Set<String> currentUnits,
  }) async {
    final initial = currentUnits.toList()..sort();
    final controller = TextEditingController(text: initial.join(', '));

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('개수형 단위 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '입력된 단위는 목록에서 -1 버튼이 크게 표시됩니다.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '단위 목록 (쉼표/줄바꿈 구분)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.text = UserPrefService
                .defaultCountLikeUnitsV1.join(', ');
            },
            child: const Text('기본값'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final parts = controller.text
                  .split(RegExp(r'[\n,]'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              Navigator.pop(ctx, parts);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  /// 아이템 추가/수정 다이얼로그 표시
  static Future<void> showItemDialog({
    required BuildContext context,
    ConsumableInventoryItem? item,
  }) async {
    final nameController = TextEditingController(
      text: item?.name ?? '',
    );
    final stockController = TextEditingController(
      text: item?.currentStock.toString() ?? '0',
    );
    final thresholdController = TextEditingController(
      text: item?.threshold.toString() ?? '1',
    );
    final bundleSizeController = TextEditingController(
      text: item?.bundleSize.toString() ?? '1',
    );
    final unitController = TextEditingController(
      text: item?.unit ?? '개',
    );
    String selectedLocation = item?.location ?? '기타';
    final selectedTags = <String>{...?(item?.healthTags)};

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(item == null ? '재고 추가' : '재고 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '품목명 (예: 휴지)',
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            decoration: const InputDecoration(
                              labelText: '현재고',
                            ),
                            keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: '단위 (예: 롤, 개)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLocation,
                      decoration: const InputDecoration(
                        labelText: '보관 위치',
                        border: OutlineInputBorder(),
                      ),
                      items: ConsumableInventoryItem
                        .locationOptions
                        .map(
                          (loc) => DropdownMenuItem(
                            value: loc,
                            child: Text(loc),
                          ),
                        )
                        .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedLocation = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thresholdController,
                      decoration: const InputDecoration(
                        labelText: '알림 기준 (이하일 때 알림)',
                      ),
                      keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                    ),
                    TextField(
                      controller: bundleSizeController,
                      decoration: const InputDecoration(
                        labelText: '묶음 단위 (예: 30롤 묶음이면 30)',
                        hintText: '휴지 대형 묶음은 보통 30입니다.',
                      ),
                      keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '건강 태그 (선택)',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HealthGuardrailService
                        .defaultTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (v) {
                            setDialogState(() {
                              if (v) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (item != null)
                  TextButton(
                    onPressed: () {
                      ConsumableInventoryService
                        .instance.deleteItem(item.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      '삭제',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => _handleItemSave(
                    context: context,
                    dialogContext: ctx,
                    item: item,
                    nameController: nameController,
                    stockController: stockController,
                    thresholdController: thresholdController,
                    bundleSizeController: bundleSizeController,
                    unitController: unitController,
                    selectedLocation: selectedLocation,
                    selectedTags: selectedTags,
                  ),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _handleItemSave({
    required BuildContext context,
    required BuildContext dialogContext,
    required ConsumableInventoryItem? item,
    required TextEditingController nameController,
    required TextEditingController stockController,
    required TextEditingController thresholdController,
    required TextEditingController bundleSizeController,
    required TextEditingController unitController,
    required String selectedLocation,
    required Set<String> selectedTags,
  }) async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final stock = double.tryParse(stockController.text) ?? 0.0;
    final threshold = double.tryParse(
      thresholdController.text,
    ) ?? 1.0;
    final bundleSize = double.tryParse(
      bundleSizeController.text,
    ) ?? 1.0;
    final unit = unitController.text.trim();
    final tags = selectedTags.toList();

    if (item == null) {
      final input = WmsInventoryInput.full(
        name: name,
        currentStock: stock,
        unit: unit,
        threshold: threshold,
        bundleSize: bundleSize,
        location: selectedLocation,
        healthTags: tags,
      );

      final result = await WmsInventoryGateway.instance.addItem(
        input: input,
      );

      if (!context.mounted) return;

      if (result.success) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.data?.name} 추가 완료')),
        );
      } else if (result.type == WmsOperationType.duplicate) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('이미 존재하는 품목'),
            content: Text(
              '${result.data?.name}이(가) 이미 등록되어 있습니다.\n'
              '현재 재고: ${result.data?.currentStock}'
              '${result.data?.unit}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추가 실패: ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      final updated = item.copyWith(
        name: name,
        currentStock: stock,
        threshold: threshold,
        bundleSize: bundleSize,
        unit: unit,
        location: selectedLocation,
        healthTags: tags,
      );

      final result = await WmsInventoryGateway.instance.updateItem(
        item: updated,
      );

      if (!context.mounted) return;

      if (result.success) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updated.name} 수정 완료')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 사용량/추가량 입력 다이얼로그 표시
  static Future<void> showAmountDialog({
    required BuildContext context,
    required String title,
    required ConsumableInventoryItem item,
    required Future<void> Function(double) onConfirm,
  }) async {
    final controller = TextEditingController(text: '1');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(suffixText: item.unit),
            ),
            const SizedBox(height: 16),
            const Text(
              '빠른 선택',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.bundleSize > 1)
                  ActionChip(
                    label: Text(
                      '1묶음 (${item.bundleSize.toInt()}${item.unit})',
                    ),
                    onPressed: () =>
                      controller.text = item.bundleSize.toString(),
                  ),
                ActionChip(
                  label: const Text('9개'),
                  onPressed: () => controller.text = '9',
                ),
                ActionChip(
                  label: const Text('10개'),
                  onPressed: () => controller.text = '10',
                ),
                ActionChip(
                  label: const Text('30개'),
                  onPressed: () => controller.text = '30',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null) {
                await onConfirm(val);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
