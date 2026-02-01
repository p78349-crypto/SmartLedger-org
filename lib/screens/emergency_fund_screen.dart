import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../models/emergency_transaction.dart';
import '../services/asset_service.dart';
import '../services/emergency_fund_service.dart';
import '../utils/debounce_utils.dart';
import '../utils/utils.dart';
import '../widgets/state_placeholders.dart';

class EmergencyFundScreen extends StatefulWidget {
  final String accountName;
  const EmergencyFundScreen({super.key, required this.accountName});

  @override
  State<EmergencyFundScreen> createState() => _EmergencyFundScreenState();
}

class _EmergencyFundScreenState extends State<EmergencyFundScreen> {
  late TextEditingController _searchController;
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 220),
  );
  bool _isLoading = true;
  String? _error;
  List<EmergencyTransaction> _transactions = [];
  List<EmergencyTransaction> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchDebouncer.run(_filterTransactions);
    });
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
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

  double get _currentBalance {
    return _transactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 비상금 목표 대비 진행률은 실제 사용처에서 바로 계산해 사용하므로
    // 로컬 변수는 제거했습니다.

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 비상금 지갑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTransaction,
            tooltip: '입출금',
          ),
        ],
      ),
      body: Column(
        children: [
          // 잔액 카드
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.purple[50],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '현재 잔액',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.purple[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(_currentBalance),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 검색바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 거래 내역
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LoadingCardListSkeleton(itemCount: 6, height: 88),
                  );
                }
                if (_error != null) {
                  return ErrorState(
                    message: _error,
                    onRetry: _loadTransactions,
                  );
                }
                if (_filteredTransactions.isEmpty) {
                  final hasQuery = _searchController.text.isNotEmpty;
                  return EmptyState(
                    title: hasQuery ? '검색 결과가 없습니다' : '비상금 거래 내역이 없습니다',
                    message: hasQuery
                        ? '검색어를 바꾸거나 초기화하세요.'
                        : '+ 버튼을 눌러 입출금을 추가하세요.',
                    secondaryLabel: hasQuery ? '검색 초기화' : null,
                    onSecondary: hasQuery
                        ? () {
                            _searchController.clear();
                            _filterTransactions();
                          }
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _filteredTransactions[index];
                    return _buildTransactionCard(transaction);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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

enum _EmergencyDeleteMode { justDelete, adjustCashAsset }

class _EmergencyDeleteDecision {
  final _EmergencyDeleteMode mode;
  final String memo;

  const _EmergencyDeleteDecision({required this.mode, required this.memo});
}

class _EmergencyDeleteDecisionDialog extends StatefulWidget {
  const _EmergencyDeleteDecisionDialog();

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
          onPressed: () => Navigator.of(context).pop(),
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

class _EmergencyTransactionDialog extends StatefulWidget {
  final EmergencyTransaction? transaction;
  const _EmergencyTransactionDialog({this.transaction});

  @override
  State<_EmergencyTransactionDialog> createState() =>
      _EmergencyTransactionDialogState();
}

class _EmergencyTransactionDialogState
    extends State<_EmergencyTransactionDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  bool _isDeposit = true;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.transaction != null
          ? CurrencyFormatter.format(
              widget.transaction!.amount.abs(),
              showUnit: false,
            )
          : '',
    );
    _isDeposit = widget.transaction == null || widget.transaction!.amount > 0;
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
      title: Text(widget.transaction == null ? '입출금 추가' : '입출금 수정'),
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
              hintText: '예: 비상금 적립',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '금액',
              hintText: '0',
              border: OutlineInputBorder(),
              suffixText: '원',
            ),
          ),
        ],
      ),
      actions: [
        if (widget.transaction != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop('DELETE');
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = _parseAmount(_amountController.text);
            if (amount != null && _descriptionController.text.isNotEmpty) {
              final transaction = EmergencyTransaction(
                id:
                    widget.transaction?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                description: _descriptionController.text,
                amount: _isDeposit ? amount : -amount,
                date: widget.transaction?.date ?? DateTime.now(),
              );
              Navigator.of(context).pop(transaction);
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(cleaned);
  }
}
