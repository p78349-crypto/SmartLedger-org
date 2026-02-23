import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../services/user_pref_service.dart';
import 'consumable_item_dialog.dart';

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
    String? initialLocation,
  }) =>
      showConsumableItemDialog(
        context: context,
        item: item,
        initialLocation: initialLocation,
      );

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
