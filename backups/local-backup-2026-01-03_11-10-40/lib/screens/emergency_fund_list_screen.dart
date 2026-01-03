import 'package:flutter/material.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/emergency_transaction.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/services/emergency_fund_service.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/date_formats.dart';
import 'package:smart_ledger/widgets/state_placeholders.dart';

/// 비상금 지갑 리스트 화면 (자산 리스트 UI와 유사)
class EmergencyFundListScreen extends StatefulWidget {
  final String accountName;
  const EmergencyFundListScreen({super.key, required this.accountName});

  @override
  State<EmergencyFundListScreen> createState() =>
      _EmergencyFundListScreenState();
}

class _EmergencyFundListScreenState extends State<EmergencyFundListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  String? _error;
  List<EmergencyTransaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  List<EmergencyTransaction> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _transactions;
    return _transactions.where((t) {
      return t.description.toLowerCase().contains(query) ||
          t.amount.toString().contains(query);
    }).toList();
  }

  void _applyFilter() => setState(() {});

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _editSelected() async {
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
    await _loadTransactions();
  }

  Future<void> _deleteSelected() async {
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

    await _loadTransactions();

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
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.accountName} - 비상금 지갑')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '비상금 거래',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _toggleSelectionMode,
                  child: Text(_isSelectionMode ? '취소' : '선택'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '설명 또는 금액으로 검색',
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: LoadingCardListSkeleton(itemCount: 6, height: 76),
                  );
                }
                if (_error != null) {
                  return ErrorState(
                    message: _error,
                    onRetry: _loadTransactions,
                  );
                }
                if (items.isEmpty) {
                  final hasQuery = _searchController.text.trim().isNotEmpty;
                  return EmptyState(
                    title: hasQuery ? '검색 결과가 없습니다' : '비상금 거래가 없습니다',
                    message: hasQuery
                        ? '검색어를 바꾸거나 초기화하세요.'
                        : '입금/출금을 추가해 비상금을 관리하세요.',
                    secondaryLabel: hasQuery ? '검색 초기화' : null,
                    onSecondary: hasQuery
                        ? () {
                            _searchController.clear();
                            _applyFilter();
                          }
                        : null,
                  );
                }

                return isLandscape
                    ? ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: items.length + 1,
                        separatorBuilder: (context, _) => const Divider(),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            const headerStyle = TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            );

                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 40),
                                  Expanded(
                                    flex: 7,
                                    child: Text(
                                      '설명',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: headerStyle,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '날짜',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: headerStyle,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    flex: 4,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '금액',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: headerStyle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final tx = items[index - 1];
                          final isSelected = _selectedIds.contains(tx.id);
                          final isDeposit = tx.amount >= 0;
                          final dateLabel = DateFormats.yMd.format(tx.date);
                          final amountLabel = CurrencyFormatter.formatSigned(
                            tx.amount,
                          );

                          final amountStyle = TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDeposit ? Colors.green : Colors.red,
                          );

                          return InkWell(
                            onTap: _isSelectionMode
                                ? () => _toggleSelection(tx.id)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: _isSelectionMode
                                        ? Checkbox(
                                            value: isSelected,
                                            onChanged: (_) =>
                                                _toggleSelection(tx.id),
                                          )
                                        : Icon(
                                            isDeposit
                                                ? Icons.arrow_downward
                                                : Icons.arrow_upward,
                                            color: isDeposit
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: Text(
                                      tx.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      dateLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 4,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        amountLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: amountStyle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: items.length,
                        separatorBuilder: (context, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final tx = items[index];
                          final isSelected = _selectedIds.contains(tx.id);
                          final isDeposit = tx.amount >= 0;
                          return ListTile(
                            leading: _isSelectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleSelection(tx.id),
                                  )
                                : Icon(
                                    isDeposit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isDeposit
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                            title: Text(tx.description),
                            subtitle: Text(DateFormats.yMd.format(tx.date)),
                            trailing: Text(
                              CurrencyFormatter.formatSigned(tx.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDeposit ? Colors.green : Colors.red,
                              ),
                            ),
                            onTap: _isSelectionMode
                                ? () => _toggleSelection(tx.id)
                                : null,
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode && _selectedIds.isNotEmpty
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete),
                        label: Text('삭제 (${_selectedIds.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedIds.length == 1
                            ? _editSelected
                            : null,
                        icon: const Icon(Icons.edit),
                        label: const Text('수정'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _EmergencyTransactionEditDialog extends StatefulWidget {
  final EmergencyTransaction transaction;

  const _EmergencyTransactionEditDialog({required this.transaction});

  @override
  State<_EmergencyTransactionEditDialog> createState() =>
      _EmergencyTransactionEditDialogState();
}

class _EmergencyTransactionEditDialogState
    extends State<_EmergencyTransactionEditDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late bool _isDeposit;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _amountController = TextEditingController(
      text: CurrencyFormatter.format(
        widget.transaction.amount.abs(),
        showUnit: false,
      ),
    );
    _isDeposit = widget.transaction.amount >= 0;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('거래 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('입금'),
                icon: Icon(Icons.add),
              ),
              ButtonSegment(
                value: false,
                label: Text('출금'),
                icon: Icon(Icons.remove),
              ),
            ],
            selected: {_isDeposit},
            onSelectionChanged: (Set<bool> selected) {
              setState(() {
                _isDeposit = selected.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '설명',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '금액',
              border: OutlineInputBorder(),
              suffixText: '원',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final amount = CurrencyFormatter.parse(_amountController.text);
            final description = _descriptionController.text.trim();
            if (amount == null || amount <= 0 || description.isEmpty) {
              return;
            }

            Navigator.of(context).pop(
              widget.transaction.copyWith(
                description: description,
                amount: _isDeposit ? amount : -amount,
              ),
            );
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

enum _EmergencyDeleteMode { justDelete, adjustCashAsset }

class _EmergencyDeleteDecision {
  final _EmergencyDeleteMode mode;
  final String memo;

  const _EmergencyDeleteDecision({required this.mode, required this.memo});
}

class _EmergencyDeleteDecisionDialog extends StatefulWidget {
  final int count;

  const _EmergencyDeleteDecisionDialog({required this.count});

  @override
  State<_EmergencyDeleteDecisionDialog> createState() =>
      _EmergencyDeleteDecisionDialogState();
}

class _EmergencyDeleteDecisionDialogState
    extends State<_EmergencyDeleteDecisionDialog> {
  _EmergencyDeleteMode _mode = _EmergencyDeleteMode.justDelete;

  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: '비상금 거래 삭제(환불/취소) 반영');
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('삭제 처리 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('선택한 ${widget.count}개 거래를 삭제합니다.'),
          const SizedBox(height: 12),
          SegmentedButton<_EmergencyDeleteMode>(
            segments: const [
              ButtonSegment(
                value: _EmergencyDeleteMode.justDelete,
                label: Text('단순 삭제'),
              ),
              ButtonSegment(
                value: _EmergencyDeleteMode.adjustCashAsset,
                label: Text('자산 순환'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selected) {
              setState(() {
                _mode = selected.first;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _mode == _EmergencyDeleteMode.justDelete
                ? '오기입/기록만 제거합니다.'
                : '삭제 금액을 현금 자산에 반영합니다.',
          ),
          if (_mode == _EmergencyDeleteMode.adjustCashAsset) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모(자산 이동 기록)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _EmergencyDeleteDecision(
                mode: _mode,
                memo: _memoController.text.trim().isEmpty
                    ? '비상금 거래 삭제(환불/취소) 반영'
                    : _memoController.text.trim(),
              ),
            );
          },
          child: const Text('계속'),
        ),
      ],
    );
  }
}
