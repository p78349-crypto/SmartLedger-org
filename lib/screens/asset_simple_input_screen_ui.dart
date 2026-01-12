// ignore_for_file: invalid_use_of_protected_member
part of asset_simple_input_screen;

extension _AssetSimpleInputScreenUi on _AssetSimpleInputScreenState {
  Widget _buildScaffold(BuildContext context, List<Asset> assets) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName),
        actions: [
          IconButton(
            tooltip: '입력값 되돌리기',
            icon: const Icon(Icons.restart_alt),
            onPressed: _promptRevertToInitial,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildSectionHeader('자산 종류'),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: '자산 종류',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '현금',
                              child: Text('현금'),
                            ),
                            DropdownMenuItem(
                              value: '예금/적금',
                              child: Text('예금/적금'),
                            ),
                            DropdownMenuItem(
                              value: '소액 투자',
                              child: Text('소액 투자'),
                            ),
                            DropdownMenuItem(
                              value: '기타 실물 자산',
                              child: Text('기타 실물 자산'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _category = v);
                          },
                        ),
                        _buildSectionHeader('기본 정보'),
                        SmartInputField(
                          controller: _nameController,
                          label: '자산명',
                          hint: '예: 시중은행 입출금통장',
                          prefixIcon: const Icon(Icons.label),
                          validator: (v) {
                            return v == null || v.isEmpty
                                ? '자산명을 입력하세요'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SmartInputField(
                          controller: _amountController,
                          label: '금액',
                          prefixIcon: const Icon(Icons.attach_money),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return '금액을 입력하세요';
                            final n = double.tryParse(v);
                            if (n == null || n < 0) {
                              return '유효한 금액을 입력하세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SmartInputField(
                          controller: _locationController,
                          label: '위치(은행/앱/보관장소)',
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        _buildSectionHeader('메모'),
                        SmartInputField(
                          controller: _memoController,
                          label: '메모(선택)',
                          prefixIcon: const Icon(Icons.note),
                          suffixIcon: _recentMemos.isEmpty
                              ? null
                              : PopupMenuButton<String>(
                                  tooltip: '최근 메모 선택',
                                  onSelected: (value) {
                                    setState(
                                      () => _memoController.text = value,
                                    );
                                  },
                                  itemBuilder: (context) {
                                    return _recentMemos
                                        .map(
                                          (memo) => PopupMenuItem(
                                            value: memo,
                                            child: Text(memo),
                                          ),
                                        )
                                        .toList();
                                  },
                                ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.save),
                            label: const Text('자산 저장'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '자산 목록',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (assets.isEmpty)
                    const Center(child: Text('등록된 자산이 없습니다.'))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assets.length,
                      separatorBuilder: (context, idx) {
                        return const Divider();
                      },
                      itemBuilder: (context, idx) {
                        final a = assets[idx];
                        final theme = Theme.of(context);
                        return ListTile(
                          title: Text(
                            a.name,
                            style: theme.textTheme.bodyLarge,
                          ),
                          trailing: Text(
                            '${a.amount.toStringAsFixed(0)}원',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant
        .withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Divider(thickness: 1, color: dividerColor),
        ],
      ),
    );
  }
}

class _InitialAssetSimpleSnapshot {
  const _InitialAssetSimpleSnapshot({
    required this.category,
    required this.nameText,
    required this.amountText,
    required this.locationText,
    required this.memoText,
  });

  final String category;
  final String nameText;
  final String amountText;
  final String locationText;
  final String memoText;
}
