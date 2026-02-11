part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Top-level build body, inline header, and field-type router.
extension TxDetailUiBuild on _TransactionAddDetailedFormState {
  /// Body of [build] – extracted so the override stays thin.
  Widget buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      children: [
        if (widget.titlePrefix != null) _buildInlineHeader(),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.only(
                left: isLandscape ? 16 : 0,
                right: isLandscape ? 16 : 0,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              children: [..._buildFieldsForSelectedType()],
            ),
          ),
        ),
        if (!isLandscape)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _buildSaveButtons(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInlineHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.titlePrefix} - ${widget.accountName}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: '장바구니 동기화',
              icon: const Icon(IconCatalog.shoppingCart),
              onPressed: confirmAndOpenShoppingCartPicker,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '입력값 되돌리기',
              icon: const Icon(IconCatalog.restartAlt),
              onPressed: promptRevertToInitial,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            _buildSaveButtons(compact: true),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsForSelectedType() {
    switch (_selectedType) {
      case TransactionType.savings:
        return _buildSavingsFields();
      case TransactionType.income:
        return _buildIncomeFields();
      case TransactionType.expense:
        return _buildExpenseFields();
      case TransactionType.refund:
        return _buildRefundFields();
    }
  }
}
