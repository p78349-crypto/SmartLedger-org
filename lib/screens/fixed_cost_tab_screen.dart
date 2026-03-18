import 'package:flutter/material.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import '../services/fixed_cost_service.dart';
import '../services/recent_input_service.dart';
import '../services/transaction_service.dart';
import '../utils/date_formats.dart';
import '../utils/utils.dart';
import '../widgets/smart_input_field.dart';

part 'fixed_cost_tab_screen_recording.dart';
part 'fixed_cost_tab_screen_build.dart';

class FixedCostTabScreen extends StatefulWidget {
  final String accountName;
  const FixedCostTabScreen({super.key, required this.accountName});

  @override
  State<FixedCostTabScreen> createState() => _FixedCostTabScreenState();
}

enum _FixedCostAction { record, edit, delete }

class _FixedCostTabScreenState extends State<FixedCostTabScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  bool _loading = true;
  List<FixedCost> _costs = const [];
  List<String> _recentPaymentMethods = const [];
  List<String> _recentMemos = const [];
  bool _isEditing = false;
  int? _editingIndex;
  int? _dueDay;
  static const List<int> _dayOptions = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
  ];

  String get _paymentPrefsKey =>
      'favorite_payments_${widget.accountName}_expense';
  String get _memoPrefsKey => 'recent_memos_fixed_cost_${widget.accountName}';

  @override
  void initState() {
    super.initState();
    _loadRecentInputs();
    _loadCosts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _memoController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _loadCosts({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() => _loading = true);
    }
    await FixedCostService().loadFixedCosts();
    final loaded = FixedCostService().getFixedCosts(widget.accountName);
    if (!mounted) return;
    setState(() {
      _costs = loaded;
      _loading = false;
    });
  }

  Future<void> _loadRecentInputs() async {
    final payments = await RecentInputService.loadValues(_paymentPrefsKey);
    final memos = await RecentInputService.loadValues(_memoPrefsKey);
    if (!mounted) return;
    setState(() {
      _recentPaymentMethods = payments;
      _recentMemos = memos;
      if (_paymentController.text.isEmpty && payments.isNotEmpty) {
        _paymentController.text = payments.first;
      }
      if (_memoController.text.isEmpty && memos.isNotEmpty) {
        _memoController.text = memos.first;
      }
    });
  }

  void _clearForm({bool resetMemo = false}) {
    _nameController.clear();
    _amountController.clear();
    _vendorController.clear();
    if (resetMemo) {
      _memoController.clear();
    }
    _dueDay = null;
  }

  Future<void> _submitCost() async {
    if (!_formKey.currentState!.validate()) return;

    final existingId = (_isEditing && _editingIndex != null)
        ? _costs[_editingIndex!].id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final cost = FixedCost(
      id: existingId,
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      vendor: _vendorController.text.trim().isEmpty
          ? null
          : _vendorController.text.trim(),
      paymentMethod: _paymentController.text.trim(),
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      dueDay: _dueDay,
    );
    final memoValue = _memoController.text.trim();
    if (_isEditing && _editingIndex != null) {
      final updatedList = List<FixedCost>.from(_costs);
      updatedList[_editingIndex!] = cost;
      await FixedCostService().replaceFixedCosts(
        widget.accountName,
        updatedList,
      );
    } else {
      await FixedCostService().addFixedCost(widget.accountName, cost);
    }
    final updatedPayments = await RecentInputService.saveValue(
      _paymentPrefsKey,
      _paymentController.text.trim(),
    );
    List<String> updatedMemos = _recentMemos;
    if (memoValue.isNotEmpty) {
      updatedMemos = await RecentInputService.saveValue(
        _memoPrefsKey,
        memoValue,
      );
    }
    final wasEditing = _isEditing;
    if (!mounted) return;
    _clearForm(resetMemo: true);
    setState(() {
      _recentPaymentMethods = updatedPayments;
      _recentMemos = updatedMemos;
      if (updatedPayments.isNotEmpty) {
        _paymentController.text = updatedPayments.first;
      }
      _memoController.text = !_isEditing && _recentMemos.isNotEmpty
          ? _recentMemos.first
          : '';
      _isEditing = false;
      _editingIndex = null;
    });
    SnackbarUtils.showSuccess(
      context,
      wasEditing ? '고정비용이 수정되었습니다.' : '고정비용이 저장되었습니다.',
    );
    await _loadCosts(showSpinner: true);
  }

  void _startEditing(FixedCost cost, int index) {
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _nameController.text = cost.name;
      _amountController.text = CurrencyFormatter.format(
        cost.amount,
        showUnit: false,
      );
      _vendorController.text = cost.vendor ?? '';
      _paymentController.text = cost.paymentMethod;
      _memoController.text = cost.memo ?? '';
      _dueDay = cost.dueDay;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingIndex = null;
      _clearForm();
      if (_recentMemos.isNotEmpty) {
        _memoController.text = _recentMemos.first;
      }
    });
  }

  Future<void> _deleteCost(int index) async {
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context,
      itemName: _costs[index].name,
    );
    if (confirmed != true) return;
    final updatedList = List<FixedCost>.from(_costs)..removeAt(index);
    await FixedCostService().replaceFixedCosts(widget.accountName, updatedList);
    if (_isEditing && _editingIndex == index) {
      _cancelEditing();
    }
    await _loadCosts(showSpinner: true);
    if (!mounted) return;
    SnackbarUtils.showSuccess(context, '고정비용이 삭제되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: _buildFormSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildCostListHeader(theme)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (_costs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('등록된 고정비용이 없습니다.')),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCostListItem(_costs[index], index),
                  childCount: _costs.length,
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: bottomInset > 0 ? bottomInset : 16),
            ),
          ],
        ),
      ),
    );
  }
}
