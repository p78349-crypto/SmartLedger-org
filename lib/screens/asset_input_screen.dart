import 'package:flutter/material.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/utils/date_formats.dart';
import 'package:smart_ledger/utils/utils.dart';
import 'package:smart_ledger/widgets/smart_input_field.dart';

class AssetInputScreen extends StatefulWidget {
  final String accountName;
  final Asset? initialAsset;
  const AssetInputScreen({
    super.key,
    required this.accountName,
    this.initialAsset,
  });

  @override
  State<AssetInputScreen> createState() => _AssetInputScreenState();
}

class _AssetInputScreenState extends State<AssetInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _ratioController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _expectedAnnualRateController =
      TextEditingController();
  // ✅ 원가
  final TextEditingController _costBasisController = TextEditingController();
  late DateTime _assetDate;
  AssetCategory _selectedCategory = AssetCategory.stock;
  bool _isInvestment = false;
  bool get _isEdit => widget.initialAsset != null;

  _InitialAssetFormSnapshot? _initialSnapshot;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAsset;
    if (initial != null) {
      _assetDate = initial.date;
      _selectedCategory = initial.category;
      _isInvestment = initial.isInvestment;
      _nameController.text = initial.name;
      _amountController.text = CurrencyFormatter.format(
        initial.amount,
        showUnit: false,
      );
      _memoController.text = initial.memo;
      // ✅ 원가 초기화
      if (initial.costBasis != null && initial.costBasis! > 0) {
        _costBasisController.text = CurrencyFormatter.format(
          initial.costBasis!,
          showUnit: false,
        );
      }
      if (initial.targetRatio != null) {
        _ratioController.text = initial.targetRatio!.toString();
      }
      if (initial.targetAmount != null) {
        _targetAmountController.text = CurrencyFormatter.format(
          initial.targetAmount!,
          showUnit: false,
        );
      }
      if (initial.expectedAnnualRatePct != null) {
        _expectedAnnualRateController.text = initial.expectedAnnualRatePct!
            .toString();
      }
    } else {
      _assetDate = DateTime.now();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });
  }

  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialAssetFormSnapshot(
      nameText: _nameController.text,
      amountText: _amountController.text,
      memoText: _memoController.text,
      ratioText: _ratioController.text,
      targetAmountText: _targetAmountController.text,
      costBasisText: _costBasisController.text,
      expectedAnnualRateText: _expectedAnnualRateController.text,
      assetDate: _assetDate,
      selectedCategory: _selectedCategory,
      isInvestment: _isInvestment,
    );
  }

  Future<void> _promptRevertToInitial() async {
    _captureInitialSnapshotIfNeeded();
    final snapshot = _initialSnapshot;
    if (snapshot == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('입력값 되돌리기'),
          content: const Text('화면을 열었을 때의 입력값으로 되돌릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('되돌리기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      FocusScope.of(context).unfocus();
      setState(() {
        _nameController.text = snapshot.nameText;
        _amountController.text = snapshot.amountText;
        _memoController.text = snapshot.memoText;
        _ratioController.text = snapshot.ratioText;
        _targetAmountController.text = snapshot.targetAmountText;
        _costBasisController.text = snapshot.costBasisText;
        _expectedAnnualRateController.text = snapshot.expectedAnnualRateText;
        _assetDate = snapshot.assetDate;
        _selectedCategory = snapshot.selectedCategory;
        _isInvestment = snapshot.isInvestment;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _ratioController.dispose();
    _targetAmountController.dispose();
    _expectedAnnualRateController.dispose();
    // ✅ 원가 controller 정리
    _costBasisController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        double? targetRatio;
        if (_ratioController.text.isNotEmpty) {
          targetRatio = double.tryParse(_ratioController.text.trim());
        }

        final amount = CurrencyFormatter.parse(_amountController.text.trim());
        final targetAmount = _targetAmountController.text.isNotEmpty
            ? CurrencyFormatter.parse(_targetAmountController.text.trim())
            : null;
        // ✅ 원가 파싱
        final costBasis = _costBasisController.text.isNotEmpty
            ? CurrencyFormatter.parse(_costBasisController.text.trim())
            : null;

        final expectedRateRaw = _expectedAnnualRateController.text.trim();
        final expectedRate = expectedRateRaw.isEmpty
            ? null
            : double.tryParse(expectedRateRaw);

        if (amount == null) {
          SnackbarUtils.showError(context, '유효한 금액을 입력하세요');
          return;
        }

        final asset = Asset(
          id:
              widget.initialAsset?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          amount: amount,
          memo: _memoController.text.trim(),
          date: _assetDate,
          category: _selectedCategory,
          expectedAnnualRatePct: expectedRate,
          targetRatio: targetRatio,
          targetAmount: targetAmount,
          isInvestment:
              _isInvestment && _selectedCategory == AssetCategory.crypto,
          costBasis: costBasis, // ✅ 원가 저장
        );

        if (_isEdit) {
          await AssetService().updateAsset(widget.accountName, asset);
          if (!mounted) return;
          SnackbarUtils.showSuccess(context, '자산이 수정되었습니다');
        } else {
          await AssetService().addAsset(widget.accountName, asset);
          if (!mounted) return;
          SnackbarUtils.showSuccess(context, '자산이 저장되었습니다');
        }

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } catch (e) {
        if (!mounted) return;
        SnackbarUtils.showError(context, '저장 실패: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialAsset = widget.initialAsset;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: '입력값 되돌리기',
            icon: const Icon(Icons.restart_alt),
            onPressed: _promptRevertToInitial,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
              child: Column(
                children: [
                  if (_isEdit && initialAsset != null)
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '원본',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              initialAsset.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${initialAsset.category.label} · '
                              '${DateFormats.yMd.format(initialAsset.date)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(initialAsset.amount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (initialAsset.targetRatio != null ||
                                initialAsset.targetAmount != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (initialAsset.targetRatio != null)
                                      Text(
                                        _targetRatioLabel(
                                          initialAsset.targetRatio!,
                                        ),
                                      ),
                                    if (initialAsset.targetAmount != null)
                                      Text(
                                        _targetAmountLabel(
                                          initialAsset.targetAmount!,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (initialAsset.memo.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(initialAsset.memo),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildSectionHeader('자산 카테고리'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: AssetCategory.values.map((category) {
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Text(
                                    '${category.emoji} ${category.label}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        _buildSectionHeader('기본 정보'),
                        SmartInputField(
                          controller: _nameController,
                          label: '자산명',
                          prefixIcon: const Icon(Icons.label),
                          validator: (v) =>
                              Validators.required(v, fieldName: '자산명'),
                        ),
                        const SizedBox(height: 12),
                        SmartInputField(
                          controller: _amountController,
                          label: '금액',
                          prefixIcon: const Icon(Icons.attach_money),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [CurrencyInputFormatter()],
                          validator: (v) =>
                              Validators.positiveNumber(v, fieldName: '금액'),
                        ),

                        _buildSectionHeader('수익 및 목표'),
                        SmartInputField(
                          controller: _expectedAnnualRateController,
                          label: '기대수익률(연 % · 선택)',
                          prefixIcon: const Icon(Icons.percent),
                          hint: '예: 예금 3, 주식 7, 코인 0~',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            final raw = v?.trim() ?? '';
                            if (raw.isEmpty) return null;
                            final num? n = num.tryParse(raw);
                            if (n == null || n < 0 || n > 100) {
                              return '0~100 사이의 숫자를 입력하세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SmartInputField(
                          controller: _costBasisController,
                          label: '원가 (선택사항)',
                          prefixIcon: const Icon(Icons.history),
                          hint: '손익 추적을 위해 원래 투입한 금액을 입력하세요',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [CurrencyInputFormatter()],
                        ),
                        const SizedBox(height: 12),
                        SmartInputField(
                          controller: _ratioController,
                          label: '목표 배분 비율 (%)',
                          prefixIcon: const Icon(Icons.percent),
                          hint: '예: 30 (선택사항)',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final num? n = num.tryParse(v);
                            if (n == null || n < 0 || n > 100) {
                              return '0~100 사이의 숫자를 입력하세요';
                            }
                            return null;
                          },
                        ),

                        if (_selectedCategory == AssetCategory.crypto) ...[
                          const SizedBox(height: 12),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            color: theme.colorScheme.surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.flag,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '투자 목표 설정',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const Spacer(),
                                      Switch(
                                        value: _isInvestment,
                                        onChanged: (value) {
                                          setState(() {
                                            _isInvestment = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_isInvestment) ...[
                                    const SizedBox(height: 8),
                                    SmartInputField(
                                      controller: _targetAmountController,
                                      label: '목표액 (도달 시 자동 전환)',
                                      prefixIcon: const Icon(Icons.flag),
                                      hint: '목표액에 도달하면 자동으로 자산으로 전환됩니다',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        CurrencyInputFormatter(),
                                      ],
                                      validator: (v) {
                                        if (!_isInvestment) return null;
                                        if (v == null || v.isEmpty) {
                                          return '투자 시 목표액은 필수입니다';
                                        }
                                        return Validators.positiveNumber(
                                          v,
                                          fieldName: '목표액',
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],

                        _buildSectionHeader('메모 및 날짜'),
                        SmartInputField(
                          controller: _memoController,
                          label: '메모 (선택사항)',
                          prefixIcon: const Icon(Icons.note),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _assetDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _assetDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '날짜',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormats.yMd.format(_assetDate),
                                  style: theme.textTheme.bodyLarge,
                                ),
                                Icon(
                                  Icons.edit_calendar,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _submit,
                                icon: Icon(
                                  _isEdit ? Icons.save : Icons.add_task,
                                ),
                                label: Text(_isEdit ? '수정 완료' : '자산 저장'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _targetRatioLabel(double ratio) {
    return '목표 비율: ${ratio.toStringAsFixed(1)}%';
  }

  String _targetAmountLabel(num amount) {
    return '목표액: ${CurrencyFormatter.format(amount)}';
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
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
          Divider(
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _InitialAssetFormSnapshot {
  const _InitialAssetFormSnapshot({
    required this.nameText,
    required this.amountText,
    required this.memoText,
    required this.ratioText,
    required this.targetAmountText,
    required this.costBasisText,
    required this.expectedAnnualRateText,
    required this.assetDate,
    required this.selectedCategory,
    required this.isInvestment,
  });

  final String nameText;
  final String amountText;
  final String memoText;
  final String ratioText;
  final String targetAmountText;
  final String costBasisText;
  final String expectedAnnualRateText;
  final DateTime assetDate;
  final AssetCategory selectedCategory;
  final bool isInvestment;
}
