import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../models/emergency_transaction.dart';
import '../models/transaction.dart';
import 'transaction_add_detailed_screen.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../services/budget_service.dart';
import '../services/emergency_fund_service.dart';
import '../services/transaction_service.dart';
import '../services/recent_input_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/transaction_utils.dart';

/// 거래 상세내역 화면
class TransactionDetailScreen extends StatefulWidget {
  final String accountName;
  final TransactionType? initialType;

  const TransactionDetailScreen({
    super.key,
    required this.accountName,
    this.initialType,
  });

  @override
  State<TransactionDetailScreen> createState() {
    return _TransactionDetailScreenState();
  }
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  TransactionType _selectedType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? TransactionType.expense;
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return '지출';
      case TransactionType.income:
        return '수입';
      case TransactionType.savings:
        return '저축';
      case TransactionType.refund:
        return '반품';
    }
  }

  Color _typeColor(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.income:
        return Colors.green[600] ?? theme.colorScheme.primary;
      case TransactionType.savings:
        return theme.colorScheme.primary;
      case TransactionType.refund:
        return Colors.green;
    }
  }

  Future<void> _showTransactionActionDialog(Transaction tx) async {
    final theme = Theme.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(IconCatalog.edit, color: theme.colorScheme.primary),
              title: const Text('편집'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            if (tx.type == TransactionType.expense && !tx.isRefund)
              ListTile(
                leading: const Icon(IconCatalog.refund, color: Colors.green),
                title: const Text('반품'),
                onTap: () => Navigator.pop(context, 'refund'),
              ),
            if (tx.type == TransactionType.income)
              ListTile(
                leading: const Icon(IconCatalog.moveDown, color: Colors.blue),
                title: const Text('이동'),
                subtitle: const Text('수입을 다른 곳으로 이동'),
                onTap: () => Navigator.pop(context, 'move'),
              ),
            ListTile(
              leading: const Icon(IconCatalog.delete, color: Colors.red),
              title: const Text('삭제'),
              onTap: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('거래 삭제'),
                    content: const Text('이 거래를 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (!mounted) return;
                  await TransactionService().deleteTransaction(
                    widget.accountName,
                    tx.id,
                  );
                  if (!mounted) return;
                  setState(() {});
                  messenger.showSnackBar(
                    const SnackBar(content: Text('거래가 삭제되었습니다')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    // If user cancelled or returned null, just return
    if (action == null || !mounted) return;

    switch (action) {
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionAddDetailedScreen(
              accountName: widget.accountName,
              initialTransaction: tx,
            ),
          ),
        );
        if (mounted) setState(() {});
        break;
      case 'refund':
        await _showRefundDialog(tx);
        break;
      case 'move':
        await _showMoveIncomeDialog(tx);
        break;
      default:
        break;
    }
  }

  Future<void> _showMoveIncomeDialog(Transaction tx) async {
    final theme = Theme.of(context);
    final String? selectedDestination = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수입 이동'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${CurrencyFormatter.format(tx.amount)}을(를) 어디로 이동하시겠습니까?'),
            const SizedBox(height: 16),
            ...[
              (
                title: '지출 예산',
                subtitle: '이번 달 지출 예산으로 사용',
                value: 'expense',
                isSelected: tx.savingsAllocation == SavingsAllocation.expense,
              ),
              (
                title: '비상금',
                subtitle: '비상금으로 보관',
                value: 'emergency',
                isSelected: tx.savingsAllocation == null,
              ),
              (
                title: '자산',
                subtitle: '자산으로 저축',
                value: 'asset',
                isSelected:
                    tx.savingsAllocation == SavingsAllocation.assetIncrease,
              ),
            ].map(
              (option) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.isSelected
                      ? IconCatalog.radioButtonChecked
                      : IconCatalog.radioButtonOff,
                  color: option.isSelected ? theme.colorScheme.primary : null,
                ),
                title: Text(option.title),
                subtitle: Text(option.subtitle),
                onTap: () {
                  Navigator.pop(context, option.value);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (selectedDestination == null) return;

    String destinationFor(SavingsAllocation? allocation) {
      switch (allocation) {
        case SavingsAllocation.expense:
          return 'expense';
        case SavingsAllocation.assetIncrease:
          return 'asset';
        case null:
          return 'emergency';
      }
    }

    final previousDestination = destinationFor(tx.savingsAllocation);
    if (selectedDestination == previousDestination) {
      return;
    }

    // SavingsAllocation 설정
    SavingsAllocation? newAllocation;

    final budgetService = BudgetService();
    final emergencyFundService = EmergencyFundService();
    final assetService = AssetService();
    final assetMoveService = AssetMoveService();
    final linkedId = 'income_move_${tx.id}';

    await Future.wait([
      emergencyFundService.ensureLoaded(),
      assetService.loadAssets(),
      assetMoveService.loadMoves(),
    ]);

    // 1) Revert previous side-effects (best-effort).
    if (previousDestination == 'expense') {
      final currentBudget = budgetService.getBudget(widget.accountName);
      await budgetService.setBudget(
        widget.accountName,
        (currentBudget - tx.amount).clamp(0.0, double.infinity).toDouble(),
      );
    } else if (previousDestination == 'emergency') {
      await emergencyFundService.deleteTransaction(
        widget.accountName,
        linkedId,
      );
    } else if (previousDestination == 'asset') {
      final assets = assetService.getAssets(widget.accountName);
      final depositAsset = assets
          .where((a) => a.category == AssetCategory.deposit)
          .cast<Asset?>()
          .firstWhere(
            (a) => a != null && a.name.contains('수입 이동'),
            orElse: () => null,
          );
      if (depositAsset != null) {
        final updated = depositAsset.copyWith(
          amount: (depositAsset.amount - tx.amount)
              .clamp(0.0, double.infinity)
              .toDouble(),
        );
        await assetService.updateAsset(widget.accountName, updated);
      }
      await assetMoveService.removeMove(widget.accountName, linkedId);
    }

    // 2) Apply new destination side-effects.
    if (selectedDestination == 'expense') {
      newAllocation = SavingsAllocation.expense;
      final currentBudget = budgetService.getBudget(widget.accountName);
      await budgetService.setBudget(
        widget.accountName,
        currentBudget + tx.amount,
      );
    } else if (selectedDestination == 'asset') {
      newAllocation = SavingsAllocation.assetIncrease;

      // Ensure a stable deposit asset to reflect this move.
      var assets = assetService.getAssets(widget.accountName);
      Asset? depositAsset;
      for (final a in assets) {
        if (a.category == AssetCategory.deposit && a.name.contains('수입 이동')) {
          depositAsset = a;
          break;
        }
      }
      depositAsset ??= Asset(
        id: 'income_move_deposit',
        name: '수입 이동 예금',
        amount: 0,
        category: AssetCategory.deposit,
        memo: '자동 생성: 수입 이동(자산) 반영용',
        date: DateTime.now(),
      );
      if (!assets.any((a) => a.id == depositAsset!.id)) {
        await assetService.addAsset(widget.accountName, depositAsset);
        assets = assetService.getAssets(widget.accountName);
      }

      final updatedDeposit = depositAsset.copyWith(
        amount: depositAsset.amount + tx.amount,
      );
      await assetService.updateAsset(widget.accountName, updatedDeposit);

      await assetMoveService.upsertMove(
        widget.accountName,
        AssetMove(
          id: linkedId,
          accountName: widget.accountName,
          fromAssetId: 'income',
          toAssetId: depositAsset.id,
          toCategoryName: '수입',
          amount: tx.amount,
          type: AssetMoveType.deposit,
          memo: '수입 이동: ${tx.description}',
          date: tx.date,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      // emergency
      newAllocation = null;
      await emergencyFundService.upsertTransaction(
        widget.accountName,
        EmergencyTransaction(
          id: linkedId,
          description: '수입 이동: ${tx.description}',
          amount: tx.amount,
          date: tx.date,
        ),
      );
    }

    // 거래 업데이트
    final updatedTx = Transaction(
      id: tx.id,
      type: tx.type,
      description: tx.description,
      amount: tx.amount,
      date: tx.date,
      quantity: tx.quantity,
      unitPrice: tx.unitPrice,
      paymentMethod: tx.paymentMethod,
      memo: tx.memo,
      store: tx.store,
      savingsAllocation: newAllocation,
      isRefund: tx.isRefund,
      originalTransactionId: tx.originalTransactionId,
      mainCategory: tx.mainCategory,
      subCategory: tx.subCategory,
    );

    await TransactionService().updateTransaction(widget.accountName, updatedTx);

    if (!mounted) return;

    if (mounted) {
      setState(() {});

      final String destination = selectedDestination == 'expense'
          ? '지출 예산'
          : selectedDestination == 'asset'
          ? '자산'
          : '비상금';

      final movedMessage =
          '${CurrencyFormatter.format(tx.amount)}이(가) '
          '$destination(으)로 이동되었습니다';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(movedMessage)));
    }
  }

  Future<void> _showRefundDialog(Transaction tx) async {
    int refundQuantity = 1;
    final maxQuantity = tx.quantity > 0 ? tx.quantity : 1;

    double calcDefaultAmount(int qty) {
      if (tx.unitPrice > 0) {
        return tx.unitPrice * qty;
      }
      if (tx.quantity > 0) {
        final perUnit = tx.amount.abs() / tx.quantity;
        return perUnit * qty;
      }
      return tx.amount.abs();
    }

    final textController = TextEditingController(
      text: calcDefaultAmount(refundQuantity).toStringAsFixed(0),
    );
    final memoController = TextEditingController(text: tx.memo);
    final refundMethodController = TextEditingController(
      text: tx.paymentMethod,
    );
    final List<String> recentPaymentMethods =
        await RecentInputService.loadPaymentMethods();
    if (!mounted) return;
    String refundChannel = '카드'; // default selection
    final quantityController = TextEditingController(
      text: refundQuantity.toString(),
    );
    String selectedAccount = '지출 예산';

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '반품 처리',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(IconCatalog.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${tx.description}을(를) 반품 처리하시겠습니까?'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: '반품 수량 (최대 $maxQuantity)',
                                        helperText: '여러 개 중 일부만 반품 시 수정하세요',
                                        suffixText: '개',
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        final parsed = int.tryParse(value) ?? 1;
                                        final clamped = parsed.clamp(
                                          1,
                                          maxQuantity,
                                        );
                                        refundQuantity = clamped;
                                        if (clamped != parsed) {
                                          quantityController.text = clamped
                                              .toString();
                                          final cursorPos =
                                              quantityController.text.length;
                                          quantityController.selection =
                                              TextSelection.fromPosition(
                                                TextPosition(offset: cursorPos),
                                              );
                                        }
                                        // 수량 변경 시 단가가 있을 경우 환불 금액도 자동 계산
                                        if (tx.unitPrice > 0 ||
                                            tx.quantity > 0) {
                                          final calculated = calcDefaultAmount(
                                            refundQuantity,
                                          );
                                          textController.text = calculated
                                              .toStringAsFixed(0);
                                        }
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('구매 수량: $maxQuantity개'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: textController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '환불 금액',
                              suffixText: '원',
                              helperText: '배송비 등을 제외한 실제 환불 받을 금액을 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: memoController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: '메모 (반품 사유)',
                              helperText: '반품 사유나 참고 메모를 적어주세요',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '환불 수단을 선택하세요',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: ['계좌이체', '카드', '현금', '기타'].map((option) {
                              final isSelected = refundChannel == option;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: Icon(
                                  isSelected
                                      ? IconCatalog.radioButtonChecked
                                      : IconCatalog.radioButtonOff,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                title: Text(option),
                                onTap: () =>
                                    setState(() => refundChannel = option),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          if (refundChannel == '카드' || refundChannel == '기타')
                            Autocomplete<String>(
                              initialValue: TextEditingValue(
                                text: refundMethodController.text,
                              ),
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                    final input = textEditingValue.text
                                        .toLowerCase();
                                    if (input.isEmpty) {
                                      return recentPaymentMethods;
                                    }
                                    return recentPaymentMethods.where(
                                      (p) => p.toLowerCase().contains(input),
                                    );
                                  },
                              onSelected: (selection) {
                                refundMethodController.text = selection;
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: refundChannel == '카드'
                                            ? '카드사/카드명'
                                            : '환불 수단 상세',
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (v) =>
                                          refundMethodController.text = v,
                                    );
                                  },
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            '환불금을 어디로 받을까요?',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: ['지출 예산', '비상금', '자산'].map((option) {
                              final isSelected = selectedAccount == option;
                              final theme = Theme.of(context);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: Icon(
                                  isSelected
                                      ? IconCatalog.radioButtonChecked
                                      : IconCatalog.radioButtonOff,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                title: Text(option),
                                onTap: () {
                                  setState(() => selectedAccount = option);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('취소'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: () async {
                                    final refundAmount =
                                        double.tryParse(
                                          textController.text.replaceAll(
                                            ',',
                                            '',
                                          ),
                                        ) ??
                                        tx.amount;
                                    final service = TransactionService();

                                    // 1. 원본 거래 수량/금액 차감
                                    final remainingQty =
                                        tx.quantity - refundQuantity;
                                    if (remainingQty > 0) {
                                      // 일부 반품: 원본 거래의 수량과 금액을 줄임
                                      final perUnit = tx.unitPrice > 0
                                          ? tx.unitPrice
                                          : (tx.amount / tx.quantity);
                                      final remainingAmount =
                                          perUnit * remainingQty;
                                      final refundAmountTextLocal = refundAmount
                                          .toStringAsFixed(0);
                                      final refundNote =
                                          '$refundQuantity개 반품됨 ('
                                          '$refundAmountTextLocal원)';
                                      final updatedMemo = tx.memo.isEmpty
                                          ? refundNote
                                          : '$tx.memo\n[$refundNote]';
                                      final updatedTx = Transaction(
                                        id: tx.id,
                                        type: tx.type,
                                        description: tx.description,
                                        amount: remainingAmount,
                                        date: tx.date,
                                        quantity: remainingQty,
                                        unitPrice: tx.unitPrice,
                                        paymentMethod: tx.paymentMethod,
                                        memo: updatedMemo,
                                        store: tx.store,
                                        savingsAllocation: tx.savingsAllocation,
                                        isRefund: tx.isRefund,
                                        originalTransactionId:
                                            tx.originalTransactionId,
                                        mainCategory: tx.mainCategory,
                                        subCategory: tx.subCategory,
                                      );
                                      await service.updateTransaction(
                                        widget.accountName,
                                        updatedTx,
                                      );
                                    } else {
                                      // 전체 반품: 원본 거래 삭제
                                      await service.deleteTransaction(
                                        widget.accountName,
                                        tx.id,
                                      );
                                    }

                                    // 2. 환불 처리 - 선택한 계정에 따라 다르게 처리
                                    if (selectedAccount == '지출 예산') {
                                      // 지출 예산으로 보내는 경우: 예산을 증가시킴
                                      final budgetService = BudgetService();
                                      final currentBudget = budgetService
                                          .getBudget(widget.accountName);
                                      await budgetService.setBudget(
                                        widget.accountName,
                                        currentBudget + refundAmount,
                                      );

                                      // 환불 거래도 기록 (수입으로, 메모에 지출예산 증가 표시)
                                      final refundAmountText = refundAmount
                                          .toStringAsFixed(0);
                                      final origDate = DateFormatter.defaultDate
                                          .format(tx.date);
                                      final autoMemo =
                                          '${tx.description} '
                                          '$refundQuantity개 환불받음 '
                                          '$refundAmountText원 → 지출예산\n';
                                      final memoSuffix = '\n원구매일: $origDate, '
                               '원결제수단: ${tx.paymentMethod}';
                                      final refundTx = Transaction(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                        type: TransactionType.refund,
                                        description: '${tx.description} (반품환불)',
                                        amount: refundAmount,
                                        date: DateTime.now(),
                                        quantity: refundQuantity,
                                        unitPrice: tx.unitPrice,
                                        paymentMethod:
                                            refundMethodController.text
                                                .trim()
                                                .isEmpty
                                            ? (refundChannel == '카드'
                                                  ? '카드'
                                                  : refundChannel)
                                            : refundMethodController.text
                                                  .trim(),
                                        memo: memoController.text.isEmpty
                                            ? autoMemo
                                            : '${memoController.text}$memoSuffix',
                                        store: tx.store,
                                        isRefund: true,
                                        originalTransactionId: tx.id,
                                        mainCategory: tx.mainCategory,
                                        subCategory: tx.subCategory,
                                      );
                                      await service.addTransaction(
                                        widget.accountName,
                                        refundTx,
                                      );
                                      await RecentInputService.savePaymentMethod(
                                        refundTx.paymentMethod,
                                      );
                                    } else {
                                      // 비상금 또는 자산으로 보내는 경우
                                      SavingsAllocation? allocation;
                                      if (selectedAccount == '자산') {
                                        allocation =
                                            SavingsAllocation.assetIncrease;
                                      }
                                      // 비상금은 null (기본 수입)

                                      final refundAmountText2 = refundAmount
                                          .toStringAsFixed(0);
                                      final origDate2 = DateFormatter
                                          .defaultDate
                                          .format(tx.date);
                                      final refundNote = '$refundAmountText2원 → $selectedAccount';
                                      final refundDetails = '\n원구매일: $origDate2, 원결제수단: ${tx.paymentMethod}';
                                      final autoMemo = '${tx.description} '
                                          '$refundQuantity개 환불받음 ' + refundNote + refundDetails;
                                      final refundTx = Transaction(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                        type: TransactionType.refund,
                                        description: '${tx.description} (반품환불)',
                                        amount: refundAmount,
                                        date: DateTime.now(),
                                        quantity: refundQuantity,
                                        unitPrice: tx.unitPrice,
                                        paymentMethod:
                                            refundMethodController.text
                                                .trim()
                                                .isEmpty
                                            ? (refundChannel == '카드'
                                                  ? '카드'
                                                  : refundChannel)
                                            : refundMethodController.text
                                                  .trim(),
                                        memo: memoController.text.isEmpty
                                            ? autoMemo
                                            : '${memoController.text}\n원구매일: $origDate2, '
                                              '원결제수단: ${tx.paymentMethod}',
                                        savingsAllocation: allocation,
                                        isRefund: true,
                                        originalTransactionId: tx.id,
                                        mainCategory: tx.mainCategory,
                                        subCategory: tx.subCategory,
                                      );
                                      await service.addTransaction(
                                        widget.accountName,
                                        refundTx,
                                      );
                                      await RecentInputService.savePaymentMethod(
                                        refundTx.paymentMethod,
                                      );
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(context); // BottomSheet 닫기
                                      Navigator.pop(context, true);
                                      // TransactionDetailScreen 닫고 true 반환
                                      final refundAmountTextLocal2 =
                                          refundAmount.toStringAsFixed(0);
                                      final processedMessage =
                                          '반품이 처리되었습니다 (환불: '
                                          '$refundAmountTextLocal2원 '
                                          '→ '
                                          '$selectedAccount)';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(processedMessage),
                                        ),
                                      );
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('반품 처리'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      textController.dispose();
      memoController.dispose();
      quantityController.dispose();
      refundMethodController.dispose();
    }
  }

  /// 거래 목록을 환불과 함께 표시 (원본 거래 바로 아래 환불 표시)
  List<Widget> _buildTransactionListWithRefunds(
    List<Transaction> transactions,
    ThemeData theme,
  ) {
    final widgets = <Widget>[];

    // 환불이 아닌 거래만 필터링
    final originalTransactions = transactions
        .where((tx) => !tx.isRefund)
        .toList();

    for (final tx in originalTransactions) {
      // 이 거래의 반품 내역 조회
      final refunds = TransactionService().getRefundsForTransaction(
        widget.accountName,
        tx.id,
      );
      final hasRefund = refunds.isNotEmpty;
      final refundedQty = refunds.fold<int>(0, (s, r) => s + r.quantity);

      final netExpense = _selectedType == TransactionType.expense
          ? getNetExpense(tx, refunds)
          : 0;
      final showNetExpense =
          _selectedType == TransactionType.expense &&
          hasRefund &&
          netExpense > 0;

      // 원본 거래 표시
      widgets.add(
        ListTile(
          onTap: () => _showTransactionActionDialog(tx),
          leading: CircleAvatar(
            backgroundColor: hasRefund
                ? theme.colorScheme.onSurfaceVariant.withAlpha(51)
                : _typeColor(_selectedType, theme).withAlpha(51),
            child: Icon(
              IconCatalog.receipt,
              color: hasRefund
                  ? theme.colorScheme.onSurfaceVariant
                  : _typeColor(_selectedType, theme),
              size: 20,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.description,
                style: TextStyle(
                  decoration: hasRefund ? TextDecoration.lineThrough : null,
                  color: hasRefund ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
              if (showNetExpense || hasRefund)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (showNetExpense)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            CurrencyFormatter.format(netExpense),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (hasRefund)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(51),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '환불은 지출 예산에 포함',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (refundedQty > 0 && refundedQty < tx.quantity)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '부분 반품: $refundedQty/${tx.quantity}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateFormatter.defaultDate.format(tx.date)}${tx.store != null && tx.store!.isNotEmpty ? ' · ${tx.store}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (tx.memo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(tx.memo, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
          trailing: Text(
            CurrencyFormatter.format(tx.amount),
            style: theme.textTheme.titleMedium?.copyWith(
              color: hasRefund
                  ? theme.colorScheme.onSurfaceVariant
                  : _typeColor(_selectedType, theme),
              fontWeight: FontWeight.bold,
              decoration: hasRefund ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      );

      // 환불 거래들을 원본 바로 아래에 표시
      for (final refund in refunds) {
        final destination = refundDestinationLabel(refund);
        widgets.add(
          Container(
            margin: const EdgeInsets.only(left: 56),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.green.withAlpha(128), width: 2),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 12, right: 16),
              leading: Icon(
                IconCatalog.refund,
                size: 20,
                color: Colors.green[700],
              ),
              title: Text(
                '환불 → $destination',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormatter.defaultDate.format(refund.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green[600],
                      fontSize: 11,
                    ),
                  ),
                  if (refund.memo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        refund.memo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      '환불수단: ${refund.paymentMethod}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green[600],
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Text(
                CurrencyFormatter.format(refund.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = TransactionService();

    // 현재 월의 거래 가져오기
    final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month);
    final endOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    List<Transaction> transactions = service
        .getTransactions(widget.accountName)
        .where(
          (tx) =>
              tx.date.isAfter(
                startOfMonth.subtract(const Duration(seconds: 1)),
              ) &&
              tx.date.isBefore(endOfMonth.add(const Duration(seconds: 1))) &&
              tx.type == _selectedType,
        )
        .toList();

    // 날짜 필터 적용
    if (_selectedDate != null) {
      transactions = transactions.where((tx) {
        return tx.date.year == _selectedDate!.year &&
            tx.date.month == _selectedDate!.month &&
            tx.date.day == _selectedDate!.day;
      }).toList();
    }

    // 날짜별로 그룹화
    final groupedByDate = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groupedByDate.putIfAbsent(dateKey, () => []).add(tx);
    }

    final sortedDates = groupedByDate.keys.toList();
    sortedDates.sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text('${_typeLabel(_selectedType)} 상세내역')),
      body: Column(
        children: [
          // 월 선택
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(IconCatalog.chevronLeft),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                      );
                      _selectedDate = null;
                    });
                  },
                ),
                Text(
                  DateFormatter.formatMonthLabel(_currentMonth),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(IconCatalog.chevronRight),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                      );
                      _selectedDate = null;
                    });
                  },
                ),
              ],
            ),
          ),

          // 날짜 필터
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: ListTile(
                  leading: const Icon(IconCatalog.calendarToday),
                  title: Text(DateFormatter.formatDate(_selectedDate!)),
                  trailing: IconButton(
                    icon: const Icon(IconCatalog.close),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                  ),
                ),
              ),
            ),

          // 거래 목록
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconCatalog.inboxOutlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '거래 내역이 없습니다',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final dayTransactions = groupedByDate[date]!;
                      final dayTotal = dayTransactions.fold<double>(
                        0,
                        (sum, tx) => sum + tx.amount,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 날짜 헤더
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDate = _selectedDate == date
                                      ? null
                                      : date;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withAlpha(128),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      DateFormatter.formatMonthDay(date),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      CurrencyFormatter.format(dayTotal),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: _typeColor(
                                              _selectedType,
                                              theme,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 거래 목록 (환불과 함께 표시)
                            ..._buildTransactionListWithRefunds(
                              dayTransactions,
                              theme,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
