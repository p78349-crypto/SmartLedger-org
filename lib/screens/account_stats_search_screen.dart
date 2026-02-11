import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/transaction_benefit_monthly_agg_service.dart';
import '../services/transaction_fts_index_service.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formats.dart';
import 'account_stats_models.dart';
import 'account_stats_search_helpers.dart';
import 'account_stats_utils.dart';

part 'account_stats_search_logic.dart';
part 'account_stats_search_display.dart';

/// 거래 검색 화면.
class AccountStatsSearchScreen extends StatefulWidget {
  const AccountStatsSearchScreen({
    super.key,
    required this.accountName,
    this.memoOnly = false,
  });

  final String accountName;
  final bool memoOnly;

  @override
  State<AccountStatsSearchScreen> createState() =>
      _AccountStatsSearchScreenState();
}

class _AccountStatsSearchScreenState extends State<AccountStatsSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = true;
  int _searchSeq = 0;
  List<StatsSearchResult> _results = const <StatsSearchResult>[];
  TxSearchPlan? _lastPlan;

  static const int _fallbackScanMax = 2000;

  bool _tenYearAggLoading = false;
  double? _tenYearAggTotal;

  static const double _defaultAnnualRatePercent = 3.0;
  bool _pointProjectionLoading = false;
  double? _pointProjectionMonthlyBase;
  double? _pointProjectionFiveYear;
  double? _pointProjectionTenYear;
  double? _pointProjectionMonthlyBase3mAvg;
  double? _pointProjectionFiveYear3mAvg;
  double? _pointProjectionTenYear3mAvg;
  double? _pointProjectionMonthlyBase6mAvg;
  double? _pointProjectionFiveYear6mAvg;
  double? _pointProjectionTenYear6mAvg;
  double _pointProjectionAnnualRateUsed = _defaultAnnualRatePercent;

  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await TransactionService().loadTransactions();
    await TransactionFtsIndexService().ensureIndexedFromPrefs();
    await TransactionBenefitMonthlyAggService().ensureAggregatedFromPrefs();
    if (!mounted) return;
    setState(() => _isLoading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final service = TransactionService();
    final query = _searchController.text.trim();
    final results = _isLoading ? const <StatsSearchResult>[] : _results;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.memoOnly ? '메모 검색' : '거래 검색')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 26),
                    hintText: widget.memoOnly
                        ? '현재 계정 메모에서 검색'
                        : '예: 카드:신용카드 마트:대형마트 카테고리:식비 >=10000'
                              ' 기간:2025-12..2025-12',
                    border: const OutlineInputBorder(),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _runSearch(service, '');
                            },
                          ),
                  ),
                  onChanged: (value) => _runSearch(service, value),
                ),
                const SizedBox(height: 8),
                _buildBenefitSummary(theme, query: query, results: results),
                if (!_isLoading && query.isNotEmpty) const SizedBox(height: 8),
                if (!widget.memoOnly) const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : query.isEmpty
                      ? const Center(child: Text('검색어를 입력하세요.'))
                      : results.isEmpty
                      ? const Center(child: Text('검색 결과가 없습니다.'))
                      : _buildResultsList(
                          theme,
                          results,
                          isLandscape,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
