part of 'transaction_add_screen.dart';

class _ExpenseHistoryPicker extends StatefulWidget {
  final String accountName;
  final ValueChanged<Transaction> onSelected;

  const _ExpenseHistoryPicker({
    required this.accountName,
    required this.onSelected,
  });

  @override
  State<_ExpenseHistoryPicker> createState() => _ExpenseHistoryPickerState();
}

class _ExpenseHistoryPickerState extends State<_ExpenseHistoryPicker> {
  final _searchController = TextEditingController();
  List<Transaction> _allExpenses = [];
  List<Transaction> _filteredExpenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    final service = TransactionService();
    await service.loadTransactions();
    final all = service.getTransactions(widget.accountName);

    final expenses =
        all.where((tx) => tx.type == TransactionType.expense).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _allExpenses = expenses;
        _filteredExpenses = expenses;
        _isLoading = false;
      });
    }
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredExpenses = _allExpenses);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filteredExpenses = _allExpenses.where((tx) {
        return tx.description.toLowerCase().contains(lower) ||
            (tx.store != null && tx.store!.toLowerCase().contains(lower)) ||
            tx.amount.toString().contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '지출 내역에서 불러오기',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: '검색 (상품명, 가게, 금액)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filter,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredExpenses.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final tx = _filteredExpenses[index];
                        return ListTile(
                          title: Text(tx.description),
                          subtitle: Text(
                            '${DateFormatter.defaultDate.format(tx.date)} | '
                            '${tx.store ?? ""}',
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(tx.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () => widget.onSelected(tx),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
