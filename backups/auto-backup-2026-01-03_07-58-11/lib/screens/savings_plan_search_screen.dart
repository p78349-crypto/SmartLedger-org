import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/savings_plan.dart';
import 'package:smart_ledger/screens/savings_plan_form_screen.dart';
import 'package:smart_ledger/services/savings_plan_service.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/dialog_utils.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';

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
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
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
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return plans;
    }

    return plans.where((plan) {
      return plan.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlans = _getFilteredPlans();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.accountName} - 예금 목록'),
      ),
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
                Text(
                  '예금 목록',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
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
                hintText: '계획명으로 검색',
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: filteredPlans.isEmpty
                ? const Center(
                    child: Text(
                      '예금 계획이 없습니다.',
                      style: TextStyle(),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredPlans.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final plan = filteredPlans[index];
                      final progress = plan.termMonths > 0
                          ? plan.paidCount / plan.termMonths
                          : 0.0;
                      final monthly = _currencyFormat.format(
                        plan.monthlyAmount,
                      );
                      final totalDeposited = _currencyFormat.format(
                        plan.depositedAmount,
                      );
                      final maturityStr = _dateFormat.format(plan.maturityDate);
                      final isSelected = _selectedIds.contains(plan.id);

                      return Card(
                        child: InkWell(
                          onTap: _isSelectionMode
                              ? () => _toggleSelection(plan.id)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_isSelectionMode)
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleSelection(plan.id),
                                      ),
                                    Expanded(
                                      child: Text(
                                        plan.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${plan.paidCount}/${plan.termMonths}회',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor:
                                      scheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress >= 1.0
                                        ? scheme.primary
                                        : scheme.tertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '월 $monthly원',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      '총 $totalDeposited원',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: scheme.tertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '만기일: $maturityStr',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                if (plan.autoDeposit) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '자동이체',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
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
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
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

