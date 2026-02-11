// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_points_input_screen.dart';

/// 포인트/할인 입력 화면 UI 빌더
extension ShoppingPointsInputUI on _ShoppingPointsInputScreenState {
  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트/할인 입력'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 입력 아이템 개수 표시
                  if (widget.itemCount != null && widget.itemCount! > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${widget.itemCount}개 아이템 지출입력 완료',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                  // 날짜 선택
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('날짜'),
                      subtitle: Text(_dateLabel(_selectedDate)),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: const Text('변경'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. 결제 종류
                  Text('결제 정보', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SmartInputField(
                    label: '결제수단 (카드명)',
                    controller: _paymentMethodController,
                    hint: '예: 농협체크카드',
                  ),
                  const SizedBox(height: 12),

                  // 2. 카드 결제금액
                  SmartInputField(
                    label: '카드 결제금액',
                    controller: _chargedAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // 3. 결제금액 외 금액 (현금 등)
                  SmartInputField(
                    label: '기타 결제금액 (현금 등)',
                    controller: _otherAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // 4. 총 상품 가격
                  Text('상품 정보', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SmartInputField(
                    label: '총 상품 가격',
                    controller: _totalAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // 할인 정보 섹션
                  Text('할인 정보', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),

                  // 5. 카드포인트 할인금액
                  SmartInputField(
                    label: '카드포인트 할인',
                    controller: _cardPointController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    suffixText: '원',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // 6. 마트할인 (마트이름 + 금액)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SmartInputField(
                          label: '마트/쇼핑몰 이름',
                          controller: _martNameController,
                          hint: '예: 하나로마트',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: SmartInputField(
                          label: '마트 할인금액',
                          controller: _martDiscountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [ThousandsInputFormatter()],
                          suffixText: '원',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 7. 메모
                  SmartInputField(
                    label: '메모 (선택)',
                    controller: _memoController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // 8. 할인 합계
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '할인 합계',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '카드포인트',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_cardPoint),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '마트 할인',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_martDiscount),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '총 할인',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_totalDiscount),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('저장'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 기존 드래프트 목록
                  if (_drafts.isNotEmpty) ...[
                    Text('이전 쇼핑 기록', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _drafts.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final d = _drafts[index];
                        final store = (d.store ?? '').trim();

                        final title = store.isEmpty
                            ? _dateLabel(d.at)
                            : '${_dateLabel(d.at)} · $store';

                        return Card(
                          elevation: 1,
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text(
                              '총액 ${CurrencyFormatter.format(d.receiptTotal)}',
                            ),
                            onTap: () => _loadDraft(d),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteDraft(d),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
