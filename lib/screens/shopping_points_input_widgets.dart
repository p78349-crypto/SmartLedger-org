import 'package:flutter/material.dart';

import '../models/shopping_points_draft_entry.dart';
import '../models/transaction.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_input_formatter.dart';
import '../widgets/smart_input_field.dart';

/// 할인 합계 요약 카드
class PointsDiscountSummaryCard extends StatelessWidget {
  const PointsDiscountSummaryCard({
    super.key,
    required this.cardPoint,
    required this.martDiscount,
    required this.totalDiscount,
  });

  final double cardPoint;
  final double martDiscount;
  final double totalDiscount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '할인 합계',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '카드포인트',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(cardPoint),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '마트 할인',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(martDiscount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 할인',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(totalDiscount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 이전 쇼핑 기록 드래프트 목록
class ShoppingDraftList extends StatelessWidget {
  const ShoppingDraftList({
    super.key,
    required this.drafts,
    required this.dateLabel,
    required this.onLoadDraft,
    required this.onDeleteDraft,
  });

  final List<ShoppingPointsDraftEntry> drafts;
  final String Function(DateTime) dateLabel;
  final ValueChanged<ShoppingPointsDraftEntry> onLoadDraft;
  final ValueChanged<ShoppingPointsDraftEntry> onDeleteDraft;

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이전 쇼핑 기록', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: drafts.length,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final d = drafts[index];
            final store = (d.store ?? '').trim();

            final title = store.isEmpty
                ? dateLabel(d.at)
                : '${dateLabel(d.at)} · $store';

            return Card(
              elevation: 1,
              child: ListTile(
                title: Text(title),
                subtitle: Text(
                  '총액 ${CurrencyFormatter.format(d.receiptTotal)}',
                ),
                onTap: () => onLoadDraft(d),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDeleteDraft(d),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 날짜 선택 카드
class ShoppingDatePickerCard extends StatelessWidget {
  const ShoppingDatePickerCard({
    super.key,
    required this.selectedDate,
    required this.dateLabel,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final String Function(DateTime) dateLabel;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('날짜'),
        subtitle: Text(dateLabel(selectedDate)),
        trailing: TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: const Text('변경'),
        ),
      ),
    );
  }
}

/// 할인 정보 입력 섹션
class ShoppingDiscountInputs extends StatelessWidget {
  const ShoppingDiscountInputs({
    super.key,
    required this.cardPointController,
    required this.martNameController,
    required this.martDiscountController,
    required this.memoController,
    required this.onChanged,
  });

  final TextEditingController cardPointController;
  final TextEditingController martNameController;
  final TextEditingController martDiscountController;
  final TextEditingController memoController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('할인 정보', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SmartInputField(
          label: '카드포인트 할인',
          controller: cardPointController,
          keyboardType: TextInputType.number,
          inputFormatters: const [ThousandsInputFormatter()],
          suffixText: '원',
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SmartInputField(
                label: '마트/쇼핑몰 이름',
                controller: martNameController,
                hint: '예: 하나로마트',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SmartInputField(
                label: '마트 할인금액',
                controller: martDiscountController,
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsInputFormatter()],
                suffixText: '원',
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SmartInputField(
          label: '메모 (선택)',
          controller: memoController,
          maxLines: 2,
        ),
      ],
    );
  }
}

/// 포인트/할인 거래 생성 (null = 할인 없음)
Transaction? createShoppingDiscountTransaction({
  required double totalDiscount,
  required DateTime date,
  required String martName,
  required String paymentMethod,
  required double totalAmount,
  required double chargedAmount,
  required double cardPoint,
  required double martDiscount,
  required String memo,
}) {
  if (totalDiscount <= 0) return null;
  final memoParts = <String>[
    BenefitAggregationUtils.savedPointsMemoTag,
    if (martName.isNotEmpty) '마트:$martName',
    if (paymentMethod.isNotEmpty) '결제:$paymentMethod',
    '합계:${CurrencyFormatter.format(totalAmount)}',
    if (chargedAmount > 0) '카드결제:${CurrencyFormatter.format(chargedAmount)}',
    if (cardPoint > 0) '카드포인트:${CurrencyFormatter.format(cardPoint)}',
    if (martDiscount > 0) '마트할인:${CurrencyFormatter.format(martDiscount)}',
    if (memo.isNotEmpty) memo,
  ];
  return Transaction(
    id: 'points_${DateTime.now().microsecondsSinceEpoch}',
    type: TransactionType.savings,
    description: '포인트/할인 적립',
    amount: totalDiscount,
    date: date,
    memo: memoParts.join(' '),
    savingsAllocation: SavingsAllocation.assetIncrease,
  );
}
