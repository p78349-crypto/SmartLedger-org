import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/shopping_price_seasonality_utils.dart';
import 'package:smart_ledger/utils/utils.dart';

class ShoppingCheapestMonthScreen extends StatefulWidget {
  final String accountName;

  const ShoppingCheapestMonthScreen({super.key, required this.accountName});

  @override
  State<ShoppingCheapestMonthScreen> createState() =>
      _ShoppingCheapestMonthScreenState();
}

class _ShoppingCheapestMonthScreenState
    extends State<ShoppingCheapestMonthScreen> {
  final _itemController = TextEditingController();

  bool _loading = true;
  List<Transaction> _transactions = const [];
  ShoppingCheapestMonthResult? _result;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await TransactionService().loadTransactions();
    final txs = TransactionService().getTransactions(widget.accountName);
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _loading = false;
    });
  }

  void _runAnalysis() {
    final itemName = _itemController.text.trim();
    final result = ShoppingPriceSeasonalityUtils.cheapestMonthLastYear(
      transactions: _transactions,
      itemName: itemName,
    );

    setState(() => _result = result);

    if (result == null) {
      SnackbarUtils.show(context, '데이터가 부족합니다(최근 1년, 식비, 단가 입력, 동일 품목 기준).');
      return;
    }

    SnackbarUtils.show(context, result.hintKo(formatWon: _formatWonNoUnit));
  }

  String _formatWonNoUnit(double won) {
    return CurrencyFormatter.format(won.round(), showUnit: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('식비 최저 월')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('식비 최저 월'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: '품목명',
                      hintText: '예: 사과',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runAnalysis(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _runAnalysis,
                    child: const Icon(Icons.search),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '기준: 최근 1년 / 지출(식비) / 단가(unitPrice) 입력된 항목 / 동일 품목(정규화)만 집계',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.hintKo(formatWon: _formatWonNoUnit),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '총 샘플 수: ${_result!.totalSamples}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    '품목명을 입력하고 분석을 눌러주세요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

