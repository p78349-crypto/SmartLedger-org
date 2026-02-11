// ignore_for_file: invalid_use_of_protected_member

part of 'emergency_fund_screen.dart';

/// Actions & logic for [_EmergencyFundScreenState].
extension EmergencyFundActions on _EmergencyFundScreenState {
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await EmergencyFundService().ensureLoaded();
      final transactions = EmergencyFundService().getTransactions(
        widget.accountName,
      );

      if (!mounted) return;
      setState(() {
        _transactions = List<EmergencyTransaction>.from(transactions);
        _filteredTransactions = _transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '비상금 거래를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  void _filterTransactions() {
    final query = _searchController.text.trim();
    final lower = query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTransactions = _transactions;
      } else {
        _filteredTransactions = _transactions
            .where(
              (t) =>
                  t.description.toLowerCase().contains(lower) ||
                  t.amount.toString().contains(query),
            )
            .toList();
      }
    });
  }

  Widget _buildTransactionCard(EmergencyTransaction transaction) {
    final isDeposit = transaction.amount > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDeposit ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isDeposit ? Icons.add : Icons.remove,
            color: isDeposit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text(DateFormatter.formatDate(transaction.date)),
        trailing: Text(
          CurrencyFormatter.formatSigned(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDeposit ? Colors.green : Colors.red,
            fontSize: 16,
          ),
        ),
        onTap: () => _editTransaction(transaction),
      ),
    );
  }

  Future<void> _addTransaction() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => const _EmergencyTransactionDialog(),
    );

    if (result != null && result is EmergencyTransaction) {
      setState(() {
        _transactions.insert(0, result);
        _filterTransactions();
      });

      await _saveTransactions();

      if (mounted) {
        SnackbarUtils.showSuccess(context, '비상금 거래가 저장되었습니다');
      }
    }
  }

  Future<void> _editTransaction(EmergencyTransaction transaction) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) =>
          _EmergencyTransactionDialog(transaction: transaction),
    );

    if (result == 'DELETE') {
      // 삭제 처리
      if (!mounted) return;
      final decision = await showDialog<_EmergencyDeleteDecision>(
        context: context,
        builder: (ctx) => const _EmergencyDeleteDecisionDialog(),
      );

      if (decision == null) return;

      if (decision.mode == _EmergencyDeleteMode.justDelete) {
        setState(() {
          _transactions.removeWhere((t) => t.id == transaction.id);
          _filterTransactions();
        });
        await _saveTransactions();
      } else {
        final cashAssetId = await _selectCashAssetId();
        if (cashAssetId == null) {
          setState(() {
            _transactions.removeWhere((t) => t.id == transaction.id);
            _filterTransactions();
          });
          await _saveTransactions();
        } else {
          await EmergencyFundService().deleteTransactionsAndAdjustCashAsset(
            widget.accountName,
            [transaction.id],
            cashAssetId: cashAssetId,
            memo: decision.memo,
          );
          await _loadTransactions();
        }
      }

      if (mounted) {
        SnackbarUtils.showSuccess(context, '비상금 거래가 삭제되었습니다');
      }
    } else if (result != null && result is EmergencyTransaction) {
      // 수정 처리
      setState(() {
        final index = _transactions.indexOf(transaction);
        _transactions[index] = result;
        _filterTransactions();
      });

      await _saveTransactions();

      if (mounted) {
        SnackbarUtils.showSuccess(context, '비상금 거래가 수정되었습니다');
      }
    }
  }

  Future<void> _saveTransactions() async {
    await EmergencyFundService().replaceTransactions(
      widget.accountName,
      _transactions,
    );
  }

  Future<String?> _selectCashAssetId() async {
    await AssetService().loadAssets();
    if (!mounted) return null;
    final assets = AssetService().getAssets(widget.accountName);
    final cashAssets = assets.where((a) => a.category == AssetCategory.cash);
    final items = cashAssets.toList();

    if (items.isEmpty) {
      if (!mounted) return null;
      SnackbarUtils.showWarning(context, '현금 자산이 없어 자산 순환을 적용할 수 없습니다');
      return null;
    }

    if (items.length == 1) {
      return items.first.id;
    }

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('현금 자산 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final asset = items[index];
              return ListTile(
                title: Text(asset.name),
                subtitle: Text(CurrencyFormatter.format(asset.amount)),
                onTap: () => Navigator.of(ctx).pop(asset.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}
