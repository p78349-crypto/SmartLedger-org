// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import 'account_create_screen.dart';
import 'account_main_screen.dart';
import 'account_select_screen.dart';
import '../services/account_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../theme/app_colors.dart';
import '../utils/backup_password_bootstrapper.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/refund_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/top_level_stats_utils.dart';
import '../utils/debounce_utils.dart';
import '../widgets/month_end_carryover_dialog.dart';
import '../widgets/root_summary_card.dart';
import '../widgets/root_transaction_list.dart';

part 'top_level_main_screen_logic.dart';
part 'top_level_main_screen_build.dart';
part 'top_level_main_screen_detail.dart';
part 'top_level_main_screen_detail_accounts.dart';
part 'top_level_main_screen_detail_outflows.dart';
part 'top_level_main_screen_detail_helpers.dart';

class TopLevelMainScreen extends StatefulWidget {
  const TopLevelMainScreen({super.key});

  @override
  State<TopLevelMainScreen> createState() => _TopLevelMainScreenState();
}

class _TopLevelMainScreenState extends State<TopLevelMainScreen> {
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  List<Transaction> searchResults = [];
  bool isSearchFocused = false;
  bool _isLoadingData = true;
  final Debouncer _rootSearchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 200),
  );

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController()..addListener(_onSearchChanged);
    searchFocusNode = FocusNode()..addListener(_onFocusChange);
    _initializeServices();
    _initialLoad();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _rootSearchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}

class _AccountAggregate {
  const _AccountAggregate({
    required this.name,
    required this.income,
    required this.expense,
    required this.savings,
    required this.refund,
    required this.fixedCost,
  });

  final String name;
  final double income;
  final double expense;
  final double savings;
  final double refund;
  final double fixedCost;

  double get net => income + refund - expense - savings - fixedCost;
}
