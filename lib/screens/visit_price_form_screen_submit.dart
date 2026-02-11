// ignore_for_file: invalid_use_of_protected_member
part of 'visit_price_form_screen.dart';

/// 음성 인식 + 제출 로직
extension VisitPriceFormVoiceSubmit on _VisitPriceFormScreenState {
  bool _isListeningFor(String target) {
    return _speechAvailable && _currentListeningTarget == target;
  }

  Future<bool> _ensureSpeechReady() async {
    if (_speechInitAttempted) return _speechAvailable;
    _speechInitAttempted = true;
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
    } catch (e) {
      _speechAvailable = false;
    }
    setState(() {});
    return _speechAvailable;
  }

  void _onSpeechStatus(String status) {}

  void _onSpeechError(dynamic error) {}

  void _toggleListening(String target) async {
    final ready = await _ensureSpeechReady();
    if (!mounted) return;
    if (!ready) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음성 인식 준비 실패')));
      return;
    }

    if (_currentListeningTarget == target) {
      await _speech.stop();
      setState(() => _currentListeningTarget = '');
      return;
    }

    setState(() => _currentListeningTarget = target);
    await _speech.listen(
      onResult: (result) {
        if (!result.finalResult) return;
        final text = result.recognizedWords;
        _applyRecognizedText(target, text);
        _speech.stop();
        if (!mounted) return;
        setState(() => _currentListeningTarget = '');
      },
    );
  }

  void _applyRecognizedText(String target, String text) {
    final cleaned = text.trim();
    switch (target) {
      case 'store':
        _storeController.text = cleaned;
        break;
      case 'sku':
        _skuController.text = cleaned.replaceAll(' ', '_').toLowerCase();
        break;
      case 'skuName':
        _skuNameController.text = cleaned;
        break;
      case 'price':
        final digits = _extractNumber(cleaned);
        if (digits != null) _priceController.text = digits.toString();
        break;
      case 'note':
        _noteController.text = cleaned;
        break;
      default:
        break;
    }
  }

  int? _extractNumber(String text) {
    final reg = RegExp(r'(\d+[,.]?\d*)');
    final m = reg.firstMatch(text.replaceAll(',', ''));
    if (m == null) return null;
    final numStr = m.group(1)!;
    final parsed = double.tryParse(numStr);
    if (parsed == null) return null;
    return parsed.round();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storeId = _storeController.text.trim();
    final skuId = _skuController.text.trim();
    final price = double.parse(_priceController.text.replaceAll(',', ''));
    final quantity = int.parse(_quantityController.text);
    final discount = _buildDiscountContext();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final evidenceUri = _evidenceController.text.trim().isEmpty
        ? null
        : _evidenceController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final entry = VisitPriceEntry.create(
        skuId: skuId,
        storeId: storeId,
        regionCode: widget.regionCode,
        unitPrice: price,
        currency: 'KRW',
        quantity: quantity,
        discount: discount,
        note: note,
        evidenceUri: evidenceUri,
      );

      await VisitPriceRepository.instance.addUserEntry(entry);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_buildSuccessMessage(entry))));
      Navigator.of(context).pop(VisitPriceFormResult(entry: entry));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('가격 등록 중 오류가 발생했습니다: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  DiscountContext _buildDiscountContext() {
    final expiresAt = _discountExpiresAt;
    switch (_discountType) {
      case DiscountType.none:
        return DiscountContext.none();
      case DiscountType.onePlusOne:
        return DiscountContext(
          type: DiscountType.onePlusOne,
          multiplier: 0.5,
          label: '1+1 행사',
          expiresAt: expiresAt,
        );
      case DiscountType.clearance:
        return DiscountContext(
          type: DiscountType.clearance,
          multiplier: 0.4,
          label: '마감 세일',
          expiresAt: expiresAt,
        );
      case DiscountType.timeSale:
        return DiscountContext(
          type: DiscountType.timeSale,
          multiplier: 0.7,
          label: '타임 세일',
          expiresAt: expiresAt,
        );
      case DiscountType.coupon:
        return DiscountContext(
          type: DiscountType.coupon,
          multiplier: 0.85,
          label: '쿠폰 할인',
          expiresAt: expiresAt,
        );
      case DiscountType.custom:
        final multiplier =
            double.tryParse(_customDiscountController.text) ?? 1.0;
        return DiscountContext(
          type: DiscountType.custom,
          multiplier: multiplier,
          label: '사용자 정의 할인',
          expiresAt: expiresAt,
        );
    }
  }

  String _discountLabel(DiscountType type) {
    switch (type) {
      case DiscountType.none:
        return '할인 없음';
      case DiscountType.onePlusOne:
        return '1+1 (50%)';
      case DiscountType.clearance:
        return '마감 세일 (40%)';
      case DiscountType.timeSale:
        return '타임 세일 (70%)';
      case DiscountType.coupon:
        return '쿠폰 (85%)';
      case DiscountType.custom:
        return '사용자 정의';
    }
  }

  String _buildSuccessMessage(VisitPriceEntry entry) {
    final diff = entry.discount.multiplier < 1
        ? '할인 반영 단가 ${entry.effectiveUnitPrice.round()}원으로 처리되었습니다.'
        : '단가 ${entry.unitPrice.round()}원이 반영되었습니다.';
    return '실방문 가격이 등록되었습니다. $diff';
  }
}
