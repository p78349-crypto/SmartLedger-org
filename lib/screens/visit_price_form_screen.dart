import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/visit_price_entry.dart';
import '../services/visit_price_repository.dart';

part 'visit_price_form_screen_fields.dart';
part 'visit_price_form_screen_submit.dart';

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
      appBar: AppBar(title: const Text('실방문 가격 신고')),
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
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
}

class VisitPriceFormResult {
  final VisitPriceEntry entry;

  const VisitPriceFormResult({required this.entry});
}
