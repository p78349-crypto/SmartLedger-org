import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/transaction_benefit_monthly_agg_service.dart';
import '../services/transaction_fts_index_service.dart';
import '../services/transaction_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/debounce_utils.dart';
import '../widgets/root_auth_gate.dart';
import '../widgets/root_transaction_list.dart';

/// ROOT 전용 - 전체 계정 거래 통합 검색
class RootSearchScreen extends StatefulWidget {
  const RootSearchScreen({super.key});

  @override
  State<RootSearchScreen> createState() => _RootSearchScreenState();
}

class _RootSearchScreenState extends State<RootSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 220),
  );
  List<Transaction> _searchResults = [];
  List<Transaction> _allTransactions = [];
  final Map<String, Transaction> _transactionById = {};
  final Map<String, String> _transactionAccountMap = {};
  bool _isSearchFocused = false;
  bool _isLoading = true;

  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isSearchFocused = _focusNode.hasFocus;
      if (_isSearchFocused && _searchController.text.isEmpty) {
        _searchResults = _allTransactions;
      }
    });
  }

  Future<void> _loadData() async {
    await TransactionService().loadTransactions();
    await TransactionFtsIndexService().ensureIndexedFromPrefs();
    await TransactionBenefitMonthlyAggService().ensureAggregatedFromPrefs();

    _rebuildAllTransactionsCache();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (_isSearchFocused) {
        _searchResults = _allTransactions;
      }
    });
  }

  void _rebuildAllTransactionsCache() {
    final service = TransactionService();
    _transactionAccountMap.clear();
    _transactionById.clear();

    final allTx = <Transaction>[];
    for (final accountName in service.getAllAccountNames()) {
      final transactions = service.getTransactions(accountName);
      for (final tx in transactions) {
        _transactionAccountMap[tx.id] = accountName;
        _transactionById[tx.id] = tx;
        allTx.add(tx);
      }
    }
    allTx.sort((a, b) => b.date.compareTo(a.date));
    _allTransactions = allTx;
  }

  void _doSearch(String query) {
    final seq = ++_searchSeq;
    final trimmed = query.trim();

    if (_isSearchFocused && trimmed.isEmpty) {
      setState(() => _searchResults = _allTransactions);
      return;
    }
    if (trimmed.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    () async {
      final hits = await TransactionFtsIndexService().search(query: trimmed);
      if (!mounted || seq != _searchSeq) return;

      final idSet = hits.map((h) => h.transactionId).toSet();
      final results = <Transaction>[];
      for (final id in idSet) {
        final tx = _transactionById[id];
        if (tx != null) results.add(tx);
      }
      results.sort((a, b) => b.date.compareTo(a.date));
      setState(() => _searchResults = results);
    }();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormats.currency;

    return RootAuthGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(IconCatalog.search, color: Colors.amber),
              SizedBox(width: 8),
              Text('ROOT 거래 검색'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              labelText: '거래 검색 (설명, 메모, 금액, 지불수단)',
                              prefixIcon: Icon(IconCatalog.search, size: 26),
                            ),
                            onChanged: (value) {
                              _searchDebouncer.run(() {
                                if (!mounted) return;
                                _doSearch(value);
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(IconCatalog.clear),
                          onPressed: () {
                            _searchController.clear();
                            _doSearch('');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildResultList(currencyFormat)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildResultList(NumberFormat currencyFormat) {
    if (_isSearchFocused && _searchController.text.isEmpty) {
      return RootTransactionList(
        transactions: _searchResults,
        transactionAccountMap: _transactionAccountMap,
        isFocused: true,
        currencyFormat: currencyFormat,
      );
    }
    if (_searchController.text.isEmpty) {
      return const Center(child: Text('검색어를 입력하세요'));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다'));
    }
    return RootTransactionList(
      transactions: _searchResults,
      transactionAccountMap: _transactionAccountMap,
      isFocused: false,
      currencyFormat: currencyFormat,
    );
  }
}
