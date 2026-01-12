library savings_plan_form_screen;

import 'package:flutter/material.dart';
import '../models/savings_plan.dart';
import 'savings_plan_search_screen.dart';
import '../services/savings_plan_service.dart';
import '../services/transaction_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formats.dart';
import '../utils/utils.dart';

part 'savings_plan_form_screen_ui.dart';

class SavingsPlanFormScreen extends StatefulWidget {
  final String accountName;
  final SavingsPlan? initialPlan;
  const SavingsPlanFormScreen({
    super.key,
    required this.accountName,
    this.initialPlan,
  });

  @override
  State<SavingsPlanFormScreen> createState() => _SavingsPlanFormScreenState();
}

class _SavingsPlanFormScreenState extends State<SavingsPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _termController = TextEditingController();
  final _interestController = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _autoDeposit = true;

  _InitialSavingsPlanFormSnapshot? _initialSnapshot;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPlan;
    if (initial != null) {
      _nameController.text = initial.name;
      _amountController.text = CurrencyFormatter.format(
        initial.monthlyAmount,
        showUnit: false,
      );
      _termController.text = initial.termMonths.toString();
      _interestController.text = (initial.interestRate * 100).toStringAsFixed(
        2,
      );
      _startDate = initial.startDate;
      _autoDeposit = initial.autoDeposit;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });
  }

  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialSavingsPlanFormSnapshot(
      nameText: _nameController.text,
      amountText: _amountController.text,
      termText: _termController.text,
      interestText: _interestController.text,
      startDate: _startDate,
      autoDeposit: _autoDeposit,
    );
  }

  Future<void> _promptRevertToInitial() async {
    _captureInitialSnapshotIfNeeded();
    final snapshot = _initialSnapshot;
    if (snapshot == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('입력값 되돌리기'),
          content: const Text('화면을 열었을 때의 입력값으로 되돌릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('되돌리기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      FocusScope.of(context).unfocus();
      setState(() {
        _nameController.text = snapshot.nameText;
        _amountController.text = snapshot.amountText;
        _termController.text = snapshot.termText;
        _interestController.text = snapshot.interestText;
        _startDate = snapshot.startDate;
        _autoDeposit = snapshot.autoDeposit;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _termController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (selected != null) {
      setState(() => _startDate = selected);
    }
  }

  String _calculateMaturityDate() {
    final termMonths = int.tryParse(_termController.text.trim());
    if (termMonths == null || termMonths <= 0) {
      return '-';
    }
    final base = DateTime(_startDate.year, _startDate.month + termMonths - 1);
    final day = _startDate.day;
    final lastDayOfMonth = DateTime(base.year, base.month + 1, 0).day;
    final safeDay = day < 1
        ? 1
        : day > lastDayOfMonth
        ? lastDayOfMonth
        : day;
    final maturityDate = DateTime(base.year, base.month, safeDay);
    return DateFormats.yMd.format(maturityDate);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final termMonths = int.tryParse(_termController.text.trim());
    final interestPercent = double.tryParse(
      _interestController.text.trim().replaceAll('%', ''),
    );

    if (amount == null ||
        amount <= 0 ||
        termMonths == null ||
        termMonths <= 0) {
      SnackbarUtils.showWarning(context, '금액과 기간을 올바르게 입력하세요');
      return;
    }

    final interestRate = (interestPercent ?? 0) / 100;

    final existing = widget.initialPlan;
    final plan = existing == null
        ? SavingsPlan(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: name,
            monthlyAmount: amount,
            startDate: _startDate,
            termMonths: termMonths,
            interestRate: interestRate,
            paidMonths: const <int>[],
            createdAt: DateTime.now(),
            autoDeposit: _autoDeposit,
          )
        : existing.copyWith(
            name: name,
            monthlyAmount: amount,
            startDate: _startDate,
            termMonths: termMonths,
            interestRate: interestRate,
            autoDeposit: _autoDeposit,
          );

    final service = SavingsPlanService();
    if (existing == null) {
      await service.addPlan(widget.accountName, plan);
    } else {
      await service.updatePlan(widget.accountName, plan);
    }
    // 새 플랜이 추가/수정되면 자동 납입 동기화 수행
    await service.syncDueDeposits(widget.accountName);
    await TransactionService().loadTransactions();

    if (!mounted) return;
    final isEditing = widget.initialPlan != null;
    SnackbarUtils.showSuccess(
      context,
      isEditing ? '예금이 수정되었습니다' : '예금이 저장되었습니다',
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }
}
