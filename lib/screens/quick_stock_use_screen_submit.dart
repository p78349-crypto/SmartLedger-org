// ignore_for_file: invalid_use_of_protected_member
part of 'quick_stock_use_screen.dart';

/// Extension: stock info snackbar & submit (deduct) logic.
extension QuickStockSubmit on _QuickStockUseBodyState {
  void _showStockInfo(String stockText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('현재 재고: $stockText'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상품을 선택해주세요')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사용량을 입력해주세요')));
      return;
    }

    // 재고 초과 체크
    if (amount > _selectedItem!.currentStock) {
      final currentLabel =
          '${_formatQty(_selectedItem!.currentStock)}${_selectedItem!.unit}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('재고 부족! 현재: $currentLabel'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 개선된 차감 로직 (부족분 장바구니 자동 추가)
    final result = await QuickStockUseUtils.useStockWithShortage(
      itemId: _selectedItem!.id,
      amount: amount,
      accountName: widget.accountName,
    );

    if (mounted) {
      if (result.success) {
        // 최근 사용 기록 추가
        setState(() {
          _recentUses.insert(
            0,
            _RecentUse(
              name: _selectedItem!.name,
              amount: result.actualUsed,
              unit: _selectedItem!.unit,
              remaining: result.remaining,
              time: DateTime.now(),
              shortage: result.shortage,
              addedToCart: result.addedToCart,
            ),
          );
          if (_recentUses.length > 5) {
            _recentUses = _recentUses.take(5).toList();
          }
        });

        // 결과 메시지 생성
        String message;
        Color bgColor;

        if (result.addedToCart) {
          // 부족분이 장바구니에 추가됨
          message =
              '⚠️ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감\n'
              '부족분 '
              '${_formatQty(result.shortage)}${_selectedItem!.unit} '
              '→ 장바구니 추가됨';
          bgColor = Colors.orange;
        } else if (result.remaining == 0) {
          // 재고 소진
          message =
              '✅ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감 완료\n'
              '⚠️ 재고가 모두 소진되었습니다!';
          bgColor = Colors.orange.shade700;
        } else {
          // 정상 차감
          final predictionLine = result.addedToCartByPrediction
              ? '\n예상 소진 임박 → 장바구니 추가됨'
              : '';
          message =
              '✅ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감 완료\n'
              '남은 재고: ${_formatQty(result.remaining)}${_selectedItem!.unit}'
              '$predictionLine';
          bgColor = Colors.green;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // 입력 초기화
        _nameController.clear();
        _amountController.text = '1';
        _selectedItem = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차감 실패: ${result.error ?? "알 수 없는 오류"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
