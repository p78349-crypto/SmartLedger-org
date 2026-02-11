part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Save buttons, memo field, and payment field (shared across types).
extension TxDetailUiCommon on _TransactionAddDetailedFormState {
  /// 저장 + 저장후계속 버튼
  Widget _buildSaveButtons({bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: compact ? 0.7 : 0.8,
          child: FloatingActionButton.small(
            heroTag: 'save_continue',
            onPressed: _saveAndContinue,
            tooltip: '저장 후 계속',
            child: const Icon(IconCatalog.arrowForward),
          ),
        ),
        const SizedBox(width: 4),
        Transform.scale(
          scale: compact ? 0.6 : 0.7,
          child: FloatingActionButton(
            heroTag: 'save',
            onPressed: _saveTransaction,
            tooltip: '저장',
            child: Text(
              compact ? '저장' : 'ENT',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 메모 입력 필드 (공통)
  Widget _buildMemoField({required VoidCallback onSubmitted}) {
    return KeyedSubtree(
      key: const Key('tx_memo'),
      child: TextFormField(
        controller: _memoController,
        focusNode: _memoFocusNode,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onSubmitted(),
        onChanged: (_) => setState(() {}),
        decoration: _standardInputDecoration(
          labelText: '메모',
          hintText: '예: 마트 이름 + 간단 메모',
          suffixIcon: IconButton(
            tooltip: '입력내용 불러오기',
            icon: Icon(
              Icons.list_alt,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _showRecentInputPicker(
              context: context,
              items: _recentMemos,
              onSelected: (v) {
                _memoController.text = v;
                _memoController.selection = TextSelection.fromPosition(
                  TextPosition(offset: v.length),
                );
                setState(() {});
              },
              title: '메모 입력내용 불러오기',
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentField({
    required Key fieldKey,
    required FocusNode focusNode,
    required TextEditingController controller,
    required VoidCallback onSubmitted,
    required String labelText,
    String? hintText,
    String? emptyErrorText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      key: fieldKey,
      focusNode: focusNode,
      controller: controller,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted(),
      decoration: _standardInputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: IconButton(
          tooltip: '입력내용 불러오기',
          icon: Icon(
            Icons.list_alt,
            size: 20,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => _showRecentInputPicker(
            context: context,
            items: _recentPayments,
            onSelected: (v) {
              controller.text = v;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: v.length),
              );
              setState(() {});
            },
            title: '결제수단 입력내용 불러오기',
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      validator: (value) {
        if (emptyErrorText == null) return null;
        return value == null || value.trim().isEmpty ? emptyErrorText : null;
      },
    );
  }
}
