// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_points_input_screen.dart';

/// 컨트롤러 초기화/해제, 데이터 로드/저장 로직
extension ShoppingPointsInputLogic on _ShoppingPointsInputScreenState {
  void _initControllers() {
    _paymentMethodController = TextEditingController();
    _chargedAmountController = TextEditingController();
    _otherAmountController = TextEditingController();
    _totalAmountController = TextEditingController();
    _cardPointController = TextEditingController();
    _martNameController = TextEditingController();
    _martDiscountController = TextEditingController();
    _memoController = TextEditingController();
  }

  void _disposeControllers() {
    _paymentMethodController.dispose();
    _chargedAmountController.dispose();
    _otherAmountController.dispose();
    _totalAmountController.dispose();
    _cardPointController.dispose();
    _martNameController.dispose();
    _martDiscountController.dispose();
    _memoController.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      // 1. 중앙 저장소에서 쇼핑 세션 정보 가져오기 (우선)
      final session = await LastInputService.instance.getShoppingSession(
        widget.accountName,
      );

      // 2. 드래프트 목록 로드
      final drafts = await UserPrefService.getShoppingPointsDrafts(
        accountName: widget.accountName,
      );
      // toList()로 mutable list 생성 후 정렬
      final sortedDrafts = drafts.toList()
        ..sort((a, b) => b.at.compareTo(a.at));

      if (!mounted) return;

      // 3. 세션 데이터 또는 widget 파라미터로 폼 초기화
      // 우선순위: 세션 > widget 파라미터 > 빈 값
      final paymentMethod =
          session?.paymentMethod ?? widget.lastPaymentMethod ?? '';
      final storeName = session?.storeName ?? widget.lastMemo ?? '';
      final totalAmount = session?.totalAmount ?? widget.totalAmount;
      final chargedAmount = session?.chargedAmount ?? widget.chargedAmount;

      _paymentMethodController.text = paymentMethod;
      _martNameController.text = storeName;

      if (totalAmount != null && totalAmount > 0) {
        _totalAmountController.text = CurrencyFormatter.format(
          totalAmount,
          showUnit: false,
        );
      }
      if (chargedAmount != null && chargedAmount > 0) {
        _chargedAmountController.text = CurrencyFormatter.format(
          chargedAmount,
          showUnit: false,
        );
      }

      setState(() {
        _drafts = sortedDrafts;
        _loading = false;
      });
    } catch (e) {
      // 에러 발생 시에도 로딩 해제
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    // 모든 필드가 비어있어도 저장 가능 (할인 0원 처리)
    final points = _totalDiscount;

    if (points > 0) {
      final memoParts = <String>[
        BenefitAggregationUtils.savedPointsMemoTag,
        if (_martNameController.text.trim().isNotEmpty)
          '마트:${_martNameController.text.trim()}',
        if (_paymentMethodController.text.trim().isNotEmpty)
          '결제:${_paymentMethodController.text.trim()}',
        '합계:${CurrencyFormatter.format(_totalAmount)}',
        if (_chargedAmount > 0)
          '카드결제:${CurrencyFormatter.format(_chargedAmount)}',
        if (_cardPoint > 0) '카드포인트:${CurrencyFormatter.format(_cardPoint)}',
        if (_martDiscount > 0)
          '마트할인:${CurrencyFormatter.format(_martDiscount)}',
        if (_memoController.text.trim().isNotEmpty) _memoController.text.trim(),
      ];

      final tx = Transaction(
        id: 'points_${DateTime.now().microsecondsSinceEpoch}',
        type: TransactionType.savings,
        description: '포인트/할인 적립',
        amount: points,
        date: _selectedDate,
        memo: memoParts.join(' '),
        savingsAllocation: SavingsAllocation.assetIncrease,
      );

      await TransactionService().addTransaction(widget.accountName, tx);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            points > 0
                ? '할인 ${CurrencyFormatter.format(points)}을 저장했어요.'
                : '할인 0원으로 처리했어요.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  void _loadDraft(ShoppingPointsDraftEntry draft) {
    setState(() {
      _selectedDate = draft.at;
      _totalAmountController.text = CurrencyFormatter.format(
        draft.receiptTotal,
        showUnit: false,
      );
      _martNameController.text = draft.store ?? '';
      _paymentMethodController.text = draft.card ?? '';
      _memoController.text = draft.memo ?? '';
    });
  }

  Future<void> _deleteDraft(ShoppingPointsDraftEntry draft) async {
    await UserPrefService.removeShoppingPointsDraft(
      accountName: widget.accountName,
      id: draft.id,
    );
    await _load();
  }
}
