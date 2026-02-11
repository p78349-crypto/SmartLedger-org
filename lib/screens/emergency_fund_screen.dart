import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../models/emergency_transaction.dart';
import '../services/asset_service.dart';
import '../services/emergency_fund_service.dart';
import '../utils/debounce_utils.dart';
import '../utils/utils.dart';
import '../widgets/state_placeholders.dart';

part 'emergency_fund_screen_actions.dart';
part 'emergency_fund_screen_dialogs.dart';

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

  double get _currentBalance {
    return _transactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
}
