import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../services/quick_simple_expense_input_history_service.dart';
import '../services/store_alias_service.dart';
import '../services/transaction_service.dart';
import '../utils/benefit_memo_utils.dart';
import '../utils/icon_catalog.dart';
import '../utils/memo_stats_utils.dart';
import '../utils/number_formats.dart';
import '../utils/product_name_utils.dart';
import '../utils/store_memo_utils.dart';

part 'input_stats_screen_logic.dart';
part 'input_stats_screen_build.dart';
part 'input_stats_screen_benefit_by_store.dart';
part 'input_stats_screen_benefit_type.dart';
part 'input_stats_screen_store_benefit.dart';
part 'input_stats_screen_store_products.dart';
part 'input_stats_screen_quick_category.dart';

// Top-level constants for extension access.
const int _maxTxScan = 1500;
const int _topEmphasisRank = 20;

class InputStatsScreen extends StatefulWidget {
  const InputStatsScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<InputStatsScreen> createState() => _InputStatsScreenState();
}

class _InputStatsScreenState extends State<InputStatsScreen> {
  bool _isLoading = true;
  MemoStatsResult? _memoThisMonth;
  MemoStatsResult? _memoLookback;
  List<QuickSimpleExpenseInputEntry> _entries = const [];

  List<Transaction> _txs = const [];
  Map<String, String> _storeAliasMap = const <String, String>{};
  String? _selectedStore;
  String? _selectedBenefitStore;

  final _currencyFormat = NumberFormats.currency;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}
