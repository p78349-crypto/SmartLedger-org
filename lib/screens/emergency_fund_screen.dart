import 'package:flutter/material.dart';

import '../models/emergency_transaction.dart';
import '../services/emergency_fund_service.dart';
import '../utils/debounce_utils.dart';
import '../utils/utils.dart';
import '../widgets/state_placeholders.dart';
import 'emergency_fund_dialogs.dart';
import 'emergency_fund_widgets.dart';

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
          EmergencyBalanceCard(balance: _currentBalance),
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
                    return EmergencyTransactionCard(
                      transaction: transaction,
                      onTap: () => _editTransaction(transaction),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTransaction() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => const EmergencyTransactionDialog(),
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
          EmergencyTransactionDialog(transaction: transaction),
    );

    if (result == 'DELETE') {
      // 삭제 처리
      if (!mounted) return;
      final decision = await showDialog<EmergencyDeleteDecision>(
        context: context,
        builder: (ctx) => const EmergencyDeleteDecisionDialog(),
      );

      if (decision == null) return;

      if (decision.mode == EmergencyDeleteMode.justDelete) {
        setState(() {
          _transactions.removeWhere((t) => t.id == transaction.id);
          _filterTransactions();
        });
        await _saveTransactions();
      } else {
        if (!mounted) return;
        final cashAssetId = await showCashAssetPicker(
          context,
          widget.accountName,
        );
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
}
