import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/visit_price_entry.dart';
import '../services/visit_price_repository.dart';

class VisitPriceFormScreen extends StatefulWidget {
  final String? initialStoreId;
  final String? initialSkuId;
  final String? initialSkuName;
  final double? initialUnitPrice;
  final int? initialQuantity;
  final DiscountContext? initialDiscount;
  final String regionCode;

  const VisitPriceFormScreen({
    super.key,
    this.initialStoreId,
    this.initialSkuId,
    this.initialSkuName,
    this.initialUnitPrice,
    this.initialQuantity,
    this.initialDiscount,
    required this.regionCode,
  });

  @override
  State<VisitPriceFormScreen> createState() => _VisitPriceFormScreenState();
}

class _VisitPriceFormScreenState extends State<VisitPriceFormScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _speechInitAttempted = false;
  String _currentListeningTarget = '';
  final _formKey = GlobalKey<FormState>();
  final _storeController = TextEditingController();
  final _skuController = TextEditingController();
  final _skuNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _customDiscountController = TextEditingController(text: '1.0');

  DiscountType _discountType = DiscountType.none;
  DateTime? _discountExpiresAt;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStoreId != null) {
      _storeController.text = widget.initialStoreId!;
    }
    if (widget.initialSkuId != null) {
      _skuController.text = widget.initialSkuId!;
    }
    if (widget.initialSkuName != null) {
      _skuNameController.text = widget.initialSkuName!;
    }

    final initialPrice = widget.initialUnitPrice;
    if (initialPrice != null && initialPrice > 0) {
      _priceController.text = initialPrice.toStringAsFixed(0);
    }

    final initialQty = widget.initialQuantity;
    if (initialQty != null && initialQty > 0) {
      _quantityController.text = initialQty.toString();
    }

    final initialDiscount = widget.initialDiscount;
    if (initialDiscount != null) {
      _discountType = initialDiscount.type;
      _discountExpiresAt = initialDiscount.expiresAt;
      if (initialDiscount.type == DiscountType.custom) {
        _customDiscountController.text = initialDiscount.multiplier.toString();
      }
    }
    _ensureSpeechReady();
  }

  @override
  void dispose() {
    _storeController.dispose();
    _skuController.dispose();
    _skuNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    _evidenceController.dispose();
    _customDiscountController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('실방문 가격 신고'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelperBanner(),
              const SizedBox(height: 16),
              _buildStoreField(),
              const SizedBox(height: 12),
              _buildSkuField(),
              const SizedBox(height: 12),
              _buildPriceField(),
              const SizedBox(height: 12),
              _buildQuantityField(),
              const SizedBox(height: 12),
              _buildDiscountField(),
              const SizedBox(height: 12),
              if (_discountType == DiscountType.custom)
                _buildCustomDiscountField(),
              if (_discountType != DiscountType.none) ...[
                const SizedBox(height: 12),
                _buildDiscountExpiryField(),
              ],
              const SizedBox(height: 12),
              _buildEvidenceField(),
              const SizedBox(height: 12),
              _buildMemoField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelperBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '사용자님이 올려주신 실방문 가격은 같은 지역 사용자들의 예산 계획에 바로 반영됩니다.',
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildStoreField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _storeController,
            decoration: const InputDecoration(
              labelText: '매장 ID 또는 이름',
              hintText: '예: lottemart_jamsil',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '매장을 입력해주세요.';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(_isListeningFor('store') ? Icons.mic : Icons.mic_none),
          onPressed: () => _toggleListening('store'),
        ),
      ],
    );
  }

  Widget _buildSkuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: '품목 ID (SKU)',
                  hintText: '예: onion_001',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '품목 ID를 입력해주세요.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_isListeningFor('sku') ? Icons.mic : Icons.mic_none),
              onPressed: () => _toggleListening('sku'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skuNameController,
                decoration: const InputDecoration(
                  labelText: '품목 이름',
                  hintText: '예: 양파 1망',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_isListeningFor('skuName') ? Icons.mic : Icons.mic_none),
              onPressed: () => _toggleListening('skuName'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '구매 단가 (원)',
              hintText: '예: 2100',
              border: OutlineInputBorder(),
              prefixText: '₩ ',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '가격을 입력해주세요.';
              }
              final parsed = double.tryParse(value.replaceAll(',', ''));
              if (parsed == null || parsed <= 0) {
                return '유효한 가격을 입력해주세요.';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(_isListeningFor('price') ? Icons.mic : Icons.mic_none),
          onPressed: () => _toggleListening('price'),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '구매 수량',
        hintText: '예: 1',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '수량을 입력해주세요.';
        }
        final parsed = int.tryParse(value);
        if (parsed == null || parsed <= 0) {
          return '1 이상의 정수를 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildDiscountField() {
    return DropdownButtonFormField<DiscountType>(
      initialValue: _discountType,
      items: DiscountType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(_discountLabel(type)),
            ),
          )
          .toList(growable: false),
      onChanged: (type) {
        if (type == null) return;
        setState(() {
          _discountType = type;
        });
      },
      decoration: const InputDecoration(
        labelText: '할인 유형',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCustomDiscountField() {
    return TextFormField(
      controller: _customDiscountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: '할인 배율 (0~1, 예: 0.7)',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (_discountType != DiscountType.custom) {
          return null;
        }
        final parsed = double.tryParse(value ?? '');
        if (parsed == null || parsed <= 0 || parsed > 1) {
          return '0보다 크고 1 이하의 값을 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildDiscountExpiryField() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('할인 종료일'),
      subtitle: Text(
        _discountExpiresAt == null
            ? '선택 안 함'
            : _discountExpiresAt!.toLocal().toString().split('.').first,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: _pickDiscountExpiry,
      ),
    );
  }

  Widget _buildEvidenceField() {
    return TextFormField(
      controller: _evidenceController,
      decoration: const InputDecoration(
        labelText: '증빙 파일 경로 / 링크 (선택)',
        hintText: '예: s3://bucket/receipt_123.jpg',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMemoField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '추가 메모 (선택)',
              hintText: '예: 1+1 행사, 오후 7시 마감 세일',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(_isListeningFor('note') ? Icons.mic : Icons.mic_none),
          onPressed: () => _toggleListening('note'),
        ),
      ],
    );
  }

  bool _isListeningFor(String target) {
    return _speechAvailable && _currentListeningTarget == target;
  }

  Future<bool> _ensureSpeechReady() async {
    if (_speechInitAttempted) return _speechAvailable;
    _speechInitAttempted = true;
    try {
      _speechAvailable = await _speech.initialize(onStatus: _onSpeechStatus, onError: _onSpeechError);
    } catch (e) {
      _speechAvailable = false;
    }
    setState(() {});
    return _speechAvailable;
  }

  void _onSpeechStatus(String status) {
    // status may be 'listening', 'notListening'
  }

  void _onSpeechError(dynamic error) {
    // ignore for now
  }

  void _toggleListening(String target) async {
    final ready = await _ensureSpeechReady();
    if (!mounted) return;
    if (!ready) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('음성 인식 준비 실패')));
      return;
    }

    if (_currentListeningTarget == target) {
      await _speech.stop();
      setState(() => _currentListeningTarget = '');
      return;
    }

    setState(() => _currentListeningTarget = target);
    await _speech.listen(onResult: (result) {
      if (!result.finalResult) return;
      final text = result.recognizedWords;
      _applyRecognizedText(target, text);
      _speech.stop();
      if (!mounted) return;
      setState(() => _currentListeningTarget = '');
    });
  }

  void _applyRecognizedText(String target, String text) {
    final cleaned = text.trim();
    switch (target) {
      case 'store':
        _storeController.text = cleaned;
        break;
      case 'sku':
        // try to derive sku id tokenized
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.done),
        label: Text(_isSubmitting ? '등록 중...' : '실방문 가격 등록'),
        onPressed: _isSubmitting ? null : _submit,
      ),
    );
  }

  Future<void> _pickDiscountExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _discountExpiresAt ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked == null) return;
    setState(() {
      _discountExpiresAt = picked;
    });
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
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    final evidenceUri = _evidenceController.text.trim().isEmpty ? null : _evidenceController.text.trim();

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_buildSuccessMessage(entry)),
        ),
      );
      Navigator.of(context).pop(VisitPriceFormResult(entry: entry));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가격 등록 중 오류가 발생했습니다: $error')),
      );
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
        final multiplier = double.tryParse(_customDiscountController.text) ?? 1.0;
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

class VisitPriceFormResult {
  final VisitPriceEntry entry;

  const VisitPriceFormResult({required this.entry});
}
