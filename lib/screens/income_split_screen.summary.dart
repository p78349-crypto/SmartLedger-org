// ignore_for_file: invalid_use_of_protected_member
part of 'income_split_screen.dart';

/// Extension: summary inline widget.
extension IncomeSplitSummary on _IncomeSplitScreenState {
  Widget _buildSummaryInline(
    double savings, double budget, double emergency, double assetTransfer,
  ) {
    Widget buildColumn(String label, double amount, Color color,
        {TextAlign align = TextAlign.start}) {
      return Column(
        crossAxisAlignment: align == TextAlign.end
            ? CrossAxisAlignment.end
            : align == TextAlign.center
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 2),
          Text(CurrencyFormatter.format(amount), textAlign: align,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      );
    }

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: buildColumn('예금', savings, Colors.orange)),
          const VerticalDivider(width: 24, thickness: 0.5),
          Expanded(child: buildColumn('예산', budget, Colors.blue,
            align: TextAlign.center)),
          const VerticalDivider(width: 24, thickness: 0.5),
          Expanded(child: buildColumn('비상금', emergency, Colors.purple,
            align: TextAlign.end)),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.teal[50], borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('자산 이동',
              style: TextStyle(fontWeight: FontWeight.w600)),
            Text(CurrencyFormatter.format(assetTransfer),
              style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.teal)),
          ],
        ),
      ),
    ]);
  }
}
