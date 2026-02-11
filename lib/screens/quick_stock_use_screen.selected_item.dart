// ignore_for_file: invalid_use_of_protected_member
part of 'quick_stock_use_screen.dart';

/// Extension: selected-item detail card (depletion prediction).
extension QuickStockSelectedItem on _QuickStockUseBodyState {
  Widget _buildSelectedItemCard(BuildContext context) {
    final item = _selectedItem!;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final used = amount < 0 ? 0 : amount;
    final remaining = item.currentStock - used;
    final remainingClamped = remaining < 0 ? 0.0 : remaining;
    final shortage = used - item.currentStock;
    final shortageClamped = shortage < 0 ? 0.0 : shortage;

    String relativeLastUpdated() {
      final now = DateTime.now();
      var diff = now.difference(item.lastUpdated);
      if (diff.isNegative) diff = Duration.zero;
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inHours < 1) return '${diff.inMinutes}분 전';
      if (diff.inDays < 1) return '${diff.inHours}시간 전';
      return '${diff.inDays}일 전';
    }

    DateTime startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    String formatDate(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    int? expectedDaysLeft;
    int? avgIntervalDays;
    DateTime? expectedDepletionDate;

    if (item.usageHistory.length >= 2) {
      final sorted = [...item.usageHistory]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final first = sorted.first.timestamp;
      final last = sorted.last.timestamp;
      final spanDays = startOfDay(last)
          .difference(startOfDay(first)).inDays.abs();
      final denomDays = spanDays < 1 ? 1 : spanDays;
      final totalUsed = sorted.fold<double>(
        0.0, (sum, r) => sum + r.amount);
      final avgPerDay = totalUsed / denomDays;

      if (avgPerDay > 0 && item.currentStock > 0) {
        expectedDaysLeft = (item.currentStock / avgPerDay).ceil();
        expectedDepletionDate = startOfDay(DateTime.now())
            .add(Duration(days: expectedDaysLeft));
      }

      final intervals = <int>[];
      for (var i = 1; i < sorted.length; i++) {
        final delta = startOfDay(sorted[i].timestamp)
            .difference(startOfDay(sorted[i - 1].timestamp)).inDays;
        if (delta > 0) intervals.add(delta);
      }
      if (intervals.isNotEmpty) {
        final avg = intervals.reduce((a, b) => a + b) / intervals.length;
        avgIntervalDays = avg.round();
      }
    }

    String? secondaryLine;
    Color? secondaryColor;

    if (expectedDaysLeft != null && expectedDepletionDate != null) {
      final expectedLeft = expectedDaysLeft;
      final expectedDate = expectedDepletionDate;

      final avgText = avgIntervalDays == null
          ? ''
          : ' (평균 $avgIntervalDays일 사용)';
      secondaryLine =
          '예상 소진: $expectedLeft일 뒤 (${formatDate(expectedDate)})'
          '$avgText';
      secondaryColor = expectedLeft <= 2
          ? Colors.orange
          : Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      final value = item.currentStock;
                      final label = _formatQty(value);
                      _amountController.text = label;
                      FocusScope.of(context).unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2, horizontal: 4),
                      child: Text(
                        '현재 '
                        '${_formatQty(item.currentStock)}'
                        '${item.unit} '
                        '남음',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                if (item.currentStock > 0)
                  TextButton(
                    onPressed: () {
                      _amountController.text = _formatQty(item.currentStock);
                      FocusScope.of(context).unfocus();
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('전량'),
                  ),
                Text(
                  '최근 차감: ${relativeLastUpdated()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (secondaryLine != null) ...[
              const SizedBox(height: 4),
              Text(secondaryLine,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: secondaryColor)),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '차감 후 예상 남은 재고: '
                    '${_formatQty(remainingClamped)}${item.unit}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (shortageClamped > 0)
                  Text(
                    '부족 ${_formatQty(shortageClamped)}${item.unit}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
