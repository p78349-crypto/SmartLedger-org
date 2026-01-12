part of 'shopping_cart_bulk_ledger_utils.dart';

class _MartCommonInfo {
  final String store;
  final String payment;
  final DateTime date;
  const _MartCommonInfo(this.store, this.payment, this.date);
}

class _MartCommonInfoDialog extends StatefulWidget {
  final String accountName;
  const _MartCommonInfoDialog({required this.accountName});

  @override
  State<_MartCommonInfoDialog> createState() => _MartCommonInfoDialogState();
}

class _MartCommonInfoDialogState extends State<_MartCommonInfoDialog> {
  final _storeController = TextEditingController();
  final _paymentController = TextEditingController();
  DateTime _date = DateTime.now();

  List<String> _recentStores = [];
  List<String> _recentPayments = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final stores = await UserPrefService.getRecentStores(widget.accountName);
    final payments = await UserPrefService.getRecentPayments(
      widget.accountName,
    );
    if (!mounted) return;

    setState(() {
      _recentStores = stores;
      _recentPayments = payments;
      if (stores.isNotEmpty) _storeController.text = stores.first;
      if (payments.isNotEmpty) _paymentController.text = payments.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('마트 쇼핑 정보 입력'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _storeController,
              decoration: const InputDecoration(
                labelText: '마트/쇼핑몰',
                hintText: '예: 이마트, 쿠팡 등',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: _recentStores
                  .take(3)
                  .map(
                    (s) => ActionChip(
                      label: Text(
                        s,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () =>
                          setState(() => _storeController.text = s),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _paymentController,
              decoration: const InputDecoration(
                labelText: '결제수단',
                hintText: '예: 현대카드, 현금 등',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: _recentPayments
                  .take(3)
                  .map(
                    (p) => ActionChip(
                      label: Text(
                        p,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () =>
                          setState(() => _paymentController.text = p),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('쇼핑 날짜'),
              subtitle: Text('${_date.year}-${_date.month}-${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(
                    const Duration(days: 365),
                  ),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_storeController.text.trim().isEmpty ||
                _paymentController.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              _MartCommonInfo(
                _storeController.text.trim(),
                _paymentController.text.trim(),
                _date,
              ),
            );
          },
          child: const Text('시작하기'),
        ),
      ],
    );
  }
}
