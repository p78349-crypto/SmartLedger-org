// ignore_for_file: invalid_use_of_protected_member
part of 'quick_stock_use_screen.dart';

/// Extension: suggestion tile, weight/price hint, formatting helpers.
extension QuickStockSuggestionWidgets on _QuickStockUseBodyState {
  Widget _buildSuggestionTile(ConsumableInventoryItem item) {
    final isLow = item.currentStock <= item.threshold;
    final isEmpty = item.currentStock == 0;

    final productUnit = _getProductUnit(item.name);
    final priceText = productUnit != null
        ? '약 ${_formatPrice(productUnit.pricePerUnit)}원/${productUnit.unit}'
        : null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isEmpty
            ? Colors.red
            : isLow
            ? Colors.orange
            : Colors.grey,
        child: isEmpty
            ? const Icon(Icons.warning, color: Colors.white, size: 18)
            : Text(item.name[0]),
      ),
      title: Row(
        children: [
          Expanded(child: Text(item.name)),
          if (isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('재고 없음',
                style: TextStyle(
                  color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📦 ${_formatQty(item.currentStock)}${item.unit}',
                style: TextStyle(
                  color: isEmpty ? Colors.red : isLow ? Colors.orange : null,
                  fontWeight: isEmpty || isLow ? FontWeight.bold : null),
              ),
              Text(' | 📍${item.location}'),
            ],
          ),
          if (priceText != null)
            Text('💰 $priceText',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
      isThreeLine: priceText != null,
      onTap: isEmpty ? null : () => _selectItem(item),
    );
  }

  Widget _buildWeightPriceHint(_ProductUnitInfo unitInfo) {
    final amount = double.tryParse(_amountController.text) ?? 1;
    final totalWeight = (unitInfo.weightPerUnit * amount).round();
    final totalPrice = (unitInfo.pricePerUnit * amount).round();

    final weightText = unitInfo.weightPerUnit > 0
        ? '약 ${_formatWeight(totalWeight)}'
        : '';
    final priceText = '${_formatPrice(totalPrice)}원 차감';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              weightText.isNotEmpty
                  ? '($weightText / $priceText)'
                  : '($priceText)',
              style: TextStyle(
                fontSize: 13, color: Colors.blue.shade700,
                fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeight(int grams) {
    if (grams >= 1000) return '${(grams / 1000).toStringAsFixed(1)}kg';
    return '${grams}g';
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      final man = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) return '$man만';
      return '$man만${_formatPrice(remainder)}';
    }
    if (price >= 1000) {
      final cheon = price ~/ 1000;
      final remainder = price % 1000;
      if (remainder == 0) return '$cheon,000';
      return '$cheon,${remainder.toString().padLeft(3, '0')}';
    }
    return price.toString();
  }
}
