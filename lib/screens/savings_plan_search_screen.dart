library savings_plan_search_screen;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings_plan.dart';
import 'savings_plan_form_screen.dart';
import '../services/savings_plan_service.dart';
import '../utils/date_formatter.dart';
import '../utils/dialog_utils.dart';
import '../utils/debounce_utils.dart';
import '../utils/korean_search_utils.dart';
import '../utils/number_formats.dart';
import '../utils/snackbar_utils.dart';

part 'savings_plan_search_screen_ui.dart';

class SavingsPlanSearchScreen extends StatefulWidget {
  final String accountName;
  const SavingsPlanSearchScreen({super.key, required this.accountName});

  @override
  State<SavingsPlanSearchScreen> createState() =>
      _SavingsPlanSearchScreenState();
}

class _SavingsPlanSearchScreenState extends State<SavingsPlanSearchScreen> {
  bool _openedFormOnEnter = false;
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 160),
  );
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 한 번만 신규 예금 입력 폼을 자동으로 띄운다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_openedFormOnEnter) {
        _openedFormOnEnter = true;
        _openNewPlan();
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _openNewPlan() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SavingsPlanFormScreen(accountName: widget.accountName),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
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

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '삭제 확인',
      message: '선택한 ${_selectedIds.length}개 항목을 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
    );

    if (confirmed) {
      final service = SavingsPlanService();
      for (final id in _selectedIds) {
        await service.deletePlan(widget.accountName, id);
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        SnackbarUtils.showSuccess(context, '삭제되었습니다');
      }
    }
  }

  Future<void> _editSelected() async {
    if (_selectedIds.length != 1) {
      SnackbarUtils.showWarning(context, '수정할 항목을 1개만 선택하세요');
      return;
    }

    final plans = SavingsPlanService().getPlans(widget.accountName);
    final plan = plans.firstWhere((p) => p.id == _selectedIds.first);

    // 수정 화면으로 이동
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SavingsPlanFormScreen(
          accountName: widget.accountName,
          initialPlan: plan, // 수정 모드
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        SnackbarUtils.showSuccess(context, '예금계획이 수정되었습니다');
      }
    }
  }

  List<SavingsPlan> _getFilteredPlans() {
    final plans = SavingsPlanService().getPlans(widget.accountName);
    final query = _searchController.text;

    if (query.isEmpty) {
      return plans;
    }

    return plans.where((plan) {
      return MultilingualSearchUtils.matches(plan.name, query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }
}
