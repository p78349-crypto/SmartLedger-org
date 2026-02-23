import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/account_service.dart';
import '../services/budget_service.dart';
import '../services/income_split_service.dart';
import '../utils/category_definitions.dart';
import '../utils/income_category_definitions.dart';
import '../utils/utils.dart';
import '../widgets/smart_input_field.dart';

part 'income_split_screen.save.dart';
part 'income_split_screen.category_budget_sheet.dart';
part 'income_split_screen.category_budget_card.dart';
part 'income_split_screen.income_allocation_sheet.dart';
part 'income_split_screen.income_allocation_card.dart';
part 'income_split_screen.build.dart';
part 'income_split_screen.summary.dart';

class IncomeSplitScreen extends StatefulWidget {
  final String accountName;
  final double? initialIncomeAmount;
  const IncomeSplitScreen({
    super.key,
    required this.accountName,
    this.initialIncomeAmount,
  });

  @override
  State<IncomeSplitScreen> createState() => _IncomeSplitScreenState();
}

class _IncomeSplitScreenState extends State<IncomeSplitScreen> {
  late TextEditingController _incomeController;
  late TextEditingController _savingsController;
  late TextEditingController _budgetController;
  late TextEditingController _emergencyController;
  late TextEditingController _assetController;
  late FocusNode _incomeFocusNode;
  late FocusNode _savingsFocusNode;
  late FocusNode _budgetFocusNode;
  late FocusNode _emergencyFocusNode;
  late FocusNode _assetFocusNode;
  late List<String> _availableAccounts = [];
  late String _targetAccount;

  double _totalIncome = 0;
  double _savings = 0;
  double _budget = 0;
  double _emergency = 0;
  double _assetTransfer = 0;

  Map<String, double> _categoryBudgets = <String, double>{};
  Map<String, double> _incomeAllocations = <String, double>{};

  double get _total => _savings + _budget + _emergency + _assetTransfer;
  double get _remaining => _totalIncome - _total;
  bool get _isValid =>
      (_totalIncome > 0 && _total <= _totalIncome) ||
      (_totalIncome == 0 && _total > 0);
  double get _categoryBudgetTotal =>
      _categoryBudgets.values.fold(0, (sum, value) => sum + value);

  @override
  void initState() {
    super.initState();
    _incomeController = TextEditingController();
    _savingsController = TextEditingController();
    _budgetController = TextEditingController();
    _emergencyController = TextEditingController();
    _assetController = TextEditingController();
    _incomeFocusNode = FocusNode();
    _savingsFocusNode = FocusNode();
    _budgetFocusNode = FocusNode();
    _emergencyFocusNode = FocusNode();
    _assetFocusNode = FocusNode();

    _incomeController.addListener(_updateCalculation);
    _savingsController.addListener(_updateCalculation);
    _budgetController.addListener(_updateCalculation);
    _emergencyController.addListener(_updateCalculation);
    _assetController.addListener(_updateCalculation);

    final accounts = AccountService().accounts;
    _availableAccounts = accounts.map((account) => account.name).toList();
    _targetAccount = _availableAccounts.contains(widget.accountName)
        ? widget.accountName
        : (_availableAccounts.isNotEmpty
              ? _availableAccounts.first
              : widget.accountName);

    _loadExisting();

    final initialAmount = widget.initialIncomeAmount;
    if ((initialAmount ?? 0) > 0) {
      _incomeController.text = CurrencyFormatter.currency.format(initialAmount);
      _updateCalculation();
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    _budgetController.dispose();
    _emergencyController.dispose();
    _assetController.dispose();
    _incomeFocusNode.dispose();
    _savingsFocusNode.dispose();
    _budgetFocusNode.dispose();
    _emergencyFocusNode.dispose();
    _assetFocusNode.dispose();
    super.dispose();
  }

  void _loadExisting() {
    final split = IncomeSplitService().getSplit(_targetAccount);
    if (split == null) {
      _updateCalculation();
      return;
    }

    void setController(TextEditingController controller, double value) {
      controller.text = value > 0
          ? CurrencyFormatter.currency.format(value)
          : '';
    }

    setController(_incomeController, split.totalIncome);
    setController(_savingsController, split.savingsAmount);
    setController(_budgetController, split.budgetAmount);
    setController(_emergencyController, split.emergencyAmount);
    setController(_assetController, split.assetTransferAmount);

    final sanitizedBudgets = Map<String, double>.from(split.categoryBudgets)
      ..removeWhere((_, value) => value <= 0);
    final allocations = _incomeAllocationsFromItems(split.incomeItems);

    setState(() {
      _totalIncome = split.totalIncome;
      _savings = split.savingsAmount;
      _budget = split.budgetAmount;
      _emergency = split.emergencyAmount;
      _assetTransfer = split.assetTransferAmount;
      _categoryBudgets = sanitizedBudgets;
      _incomeAllocations = allocations;
    });
  }

  void _updateCalculation() {
    double parse(TextEditingController controller) {
      final sanitized = controller.text.replaceAll(',', '').trim();
      if (sanitized.isEmpty) return 0;
      return double.tryParse(sanitized) ?? 0;
    }

    setState(() {
      _totalIncome = parse(_incomeController);
      _savings = parse(_savingsController);
      _budget = parse(_budgetController);
      _emergency = parse(_emergencyController);
      _assetTransfer = parse(_assetController);
    });
  }

  void _showUsageGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 수입 배분 사용법'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: [
              Text('1. 이번 달 총 수입을 입력하세요.'),
              SizedBox(height: 8),
              Text('2. 총 수입을 예금, 지출 예산, 비상금으로 배분하세요.'),
              SizedBox(height: 8),
              Text('3. "자산 이동"에 입력한 금액은 저장 시 자산 탭으로 자동 이동됩니다.'),
              SizedBox(height: 8),
              Text('4. [카테고리 배분]: 지출 예산을 카테고리별로 상세히 나눌 수 있습니다.'),
              SizedBox(height: 8),
              Text('5. [수입을 자산으로]: 급여, 부수입 등 수입의 출처를 기록할 수 있습니다.'),
              SizedBox(height: 8),
              Text('6. 모든 설정이 끝나면 우측 하단의 "저장" 버튼을 누르세요.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}

/// Comma-separated currency input formatter.
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final onlyDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (onlyDigits.isEmpty) return newValue.copyWith(text: '');

    final formatted = _formatWithCommas(onlyDigits);
    int cursorPosition = formatted.length;
    final oldOnlyDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    if (oldOnlyDigits.length < onlyDigits.length) {
      cursorPosition = formatted.length;
    } else if (oldOnlyDigits.length > onlyDigits.length) {
      cursorPosition = newValue.selection.baseOffset;
      if (cursorPosition > 0 && formatted[cursorPosition - 1] == ',') {
        cursorPosition--;
      }
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition));
  }

  String _formatWithCommas(String text) {
    final buffer = StringBuffer();
    final length = text.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}
