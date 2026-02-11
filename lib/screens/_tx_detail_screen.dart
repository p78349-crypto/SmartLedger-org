part of 'transaction_add_detailed_screen.dart';

class _TransactionAddDetailedScreenState
    extends State<TransactionAddDetailedScreen> {
  final GlobalKey<_TransactionAddDetailedFormState> _formStateKey =
      GlobalKey<_TransactionAddDetailedFormState>();

  @override
  void initState() {
    super.initState();
    if (widget.autoSubmit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_formStateKey.currentState?.triggerAutoSubmit());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.initialTransaction != null && widget.treatAsNew == false;

    final isIncomeTemplate =
        widget.initialTransaction?.type == TransactionType.income;
    final titlePrefix = isIncomeTemplate
        ? (isEditing ? '수입 수정(상세)' : '수입(상세)')
        : (isEditing ? '거래 수정(상세)' : '지출입력(상세)');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final didSave = _formStateKey.currentState?.didSave ?? false;
        if (didSave) {
          navigator.pop(true);
        } else {
          navigator.pop();
        }
      },
      child: Builder(
        builder: (context) {
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          return Scaffold(
            appBar: isLandscape
                ? null
                : AppBar(
                    title: Text('$titlePrefix - ${widget.accountName}'),
                    actions: [
                      IconButton(
                        tooltip: '장바구니 동기화',
                        icon: const Icon(IconCatalog.shoppingCart),
                        onPressed: () => _formStateKey.currentState
                            ?.confirmAndOpenShoppingCartPicker(),
                      ),
                      IconButton(
                        tooltip: '입력값 되돌리기',
                        icon: const Icon(IconCatalog.restartAlt),
                        onPressed: () =>
                            _formStateKey.currentState?.promptRevertToInitial(),
                      ),
                    ],
                  ),
            body: SafeArea(
              top: !isLandscape,
              child: Padding(
                padding: EdgeInsets.all(isLandscape ? 0.0 : 16.0),
                child: TransactionAddDetailedForm(
                  key: _formStateKey,
                  accountName: widget.accountName,
                  initialTransaction: widget.initialTransaction,
                  learnCategoryHintFromDescription:
                      widget.learnCategoryHintFromDescription,
                  confirmBeforeSave: widget.confirmBeforeSave,
                  treatAsNew: widget.treatAsNew,
                  closeAfterSave: widget.closeAfterSave,
                  titlePrefix: isLandscape ? titlePrefix : null,
                  initialPaymentMethod: widget.initialPaymentMethod,
                  initialMemo: widget.initialMemo,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TransactionAddDetailedScreen extends StatefulWidget {
  final String accountName;
  final Transaction? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
  final bool closeAfterSave;
  final bool autoSubmit;
  final String? initialPaymentMethod;
  final String? initialMemo;

  const TransactionAddDetailedScreen({
    super.key,
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
    this.closeAfterSave = false,
    this.autoSubmit = false,
    this.initialPaymentMethod,
    this.initialMemo,
  });

  @override
  State<TransactionAddDetailedScreen> createState() =>
      _TransactionAddDetailedScreenState();
}

class _InitialTransactionFormSnapshot {
  const _InitialTransactionFormSnapshot({
    required this.descText,
    required this.qtyText,
    required this.unitPriceText,
    required this.amountText,
    required this.cardChargedAmountText,
    required this.memoText,
    required this.storeText,
    required this.paymentText,
    required this.selectedType,
    required this.savingsAllocation,
    required this.transactionDate,
    required this.selectedMainCategory,
    required this.selectedSubCategory,
    required this.selectedDetailCategory,
    required this.locationText,
    required this.supplierText,
    required this.unitText,
    required this.expiryDate,
    required this.addToShoppingList,
    required this.showIncomeCategoryOptions,
  });

  final String descText;
  final String qtyText;
  final String unitPriceText;
  final String amountText;
  final String cardChargedAmountText;
  final String memoText;
  final String storeText;
  final String paymentText;
  final TransactionType selectedType;
  final SavingsAllocation savingsAllocation;
  final DateTime transactionDate;
  final String selectedMainCategory;
  final String? selectedSubCategory;
  final String? selectedDetailCategory;
  final String locationText;
  final String supplierText;
  final String unitText;
  final DateTime? expiryDate;
  final bool addToShoppingList;
  final bool showIncomeCategoryOptions;
}
