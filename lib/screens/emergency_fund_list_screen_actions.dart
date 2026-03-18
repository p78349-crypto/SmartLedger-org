// ignore_for_file: invalid_use_of_protected_member

part of 'emergency_fund_list_screen.dart';

/// 거래 로딩/편집/삭제/자산선택 관련 메서드
extension EmergencyFundActions on _EmergencyFundListScreenState {
  Future<void> loadTransactions() async {
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

  Future<void> editSelected() async {
    if (_selectedIds.length != 1) return;

    final id = _selectedIds.single;
    final current = _transactions.where((t) => t.id == id).toList();
    if (current.isEmpty) return;

    final updated = await showDialog<EmergencyTransaction>(
      context: context,
      builder: (context) =>
          _EmergencyTransactionEditDialog(transaction: current.first),
    );

    if (updated == null) return;

    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    final next = List<EmergencyTransaction>.from(_transactions);
    final index = next.indexWhere((t) => t.id == updated.id);
    if (index >= 0) {
      next[index] = updated;
    }

    await EmergencyFundService().replaceTransactions(widget.accountName, next);
    await loadTransactions();
  }

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final idsToDelete = _selectedIds.toList(growable: false);
    final decision = await _showDeleteDecisionDialog(count: idsToDelete.length);

    if (decision == null) return;

    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    if (decision.mode == _EmergencyDeleteMode.justDelete) {
      await EmergencyFundService().deleteTransactions(
        widget.accountName,
        idsToDelete,
      );
    } else {
      final cashAssetId = await _selectCashAssetId();
      if (cashAssetId == null) {
        await EmergencyFundService().deleteTransactions(
          widget.accountName,
          idsToDelete,
        );
      } else {
        await EmergencyFundService().deleteTransactionsAndAdjustCashAsset(
          widget.accountName,
          idsToDelete,
          cashAssetId: cashAssetId,
          memo: decision.memo,
        );
      }
    }

    await loadTransactions();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
  }

  Future<_EmergencyDeleteDecision?> _showDeleteDecisionDialog({
    required int count,
  }) {
    return showDialog<_EmergencyDeleteDecision>(
      context: context,
      builder: (ctx) => _EmergencyDeleteDecisionDialog(count: count),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현금 자산이 없어 자산 순환을 적용할 수 없습니다')),
      );
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
