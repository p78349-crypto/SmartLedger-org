// ignore_for_file: invalid_use_of_protected_member
part of 'visit_price_form_screen.dart';

/// 폼 입력 필드 위젯 빌더
extension VisitPriceFormFields on _VisitPriceFormScreenState {
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
              icon: Icon(
                _isListeningFor('skuName') ? Icons.mic : Icons.mic_none,
              ),
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
}
