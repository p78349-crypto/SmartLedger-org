import 'package:flutter/material.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/screens/asset_list_screen.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/utils/date_formats.dart';
import 'package:smart_ledger/utils/utils.dart';

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
        _expectedAnnualRateController.text =
            initial.expectedAnnualRatePct!.toString();
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
          inputType: AssetInputType.simple,
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
                              CurrencyFormatter.format(
                                initialAsset.amount,
                                showUnit: true,
                              ),
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
                        // 자산 카테고리 선택
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '자산 카테고리',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: AssetCategory.values.map((
                                        category,
                                      ) {
                                        final isSelected =
                                            _selectedCategory == category;
                                        final labelColor = isSelected
                                            ? theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                            : theme.colorScheme.onSurface;
                                        final selectedChipColor = theme
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.35);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          child: ChoiceChip(
                                            selected: isSelected,
                                            label: Text(
                                              '${category.emoji} '
                                              '${category.label}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: labelColor,
                                                  ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            backgroundColor: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            selectedColor: selectedChipColor,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
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
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '자산명',
                            prefixIcon: Icon(Icons.label),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              Validators.required(v, fieldName: '자산명'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: '금액',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [CurrencyInputFormatter()],
                          validator: (v) =>
                              Validators.positiveNumber(v, fieldName: '금액'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _expectedAnnualRateController,
                          decoration: const InputDecoration(
                            labelText: '기대수익률(연 % · 선택)',
                            prefixIcon: Icon(Icons.percent),
                            helperText: '예: 예금 3, 주식 7, 코인 0~',
                            border: OutlineInputBorder(),
                          ),
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
                        const SizedBox(height: 16),
                        // ✅ 원가 필드 (손익 추적용)
                        TextFormField(
                          controller: _costBasisController,
                          decoration: const InputDecoration(
                            labelText: '원가 (선택사항)',
                            prefixIcon: Icon(Icons.history),
                            helperText: '손익 추적을 위해 원래 투입한 금액을 입력하세요',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [CurrencyInputFormatter()],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ratioController,
                          decoration: const InputDecoration(
                            labelText: '목표 배분 비율 (%)',
                            prefixIcon: Icon(Icons.percent),
                            helperText: '예: 30 (선택사항)',
                            border: OutlineInputBorder(),
                          ),
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
                        const SizedBox(height: 16),
                        // 투자 목표액 입력
                        if (_selectedCategory == AssetCategory.crypto) ...[
                          Card(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.flag),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '투자 목표 설정',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Checkbox(
                                        value: _isInvestment,
                                        onChanged: (value) {
                                          setState(() {
                                            _isInvestment = value ?? false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_isInvestment) ...[
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _targetAmountController,
                                      decoration: const InputDecoration(
                                        labelText: '목표액 (도달 시 자동 전환)',
                                        prefixIcon: Icon(Icons.flag),
                                        helperText: '목표액에 도달하면 자동으로 자산으로 전환됩니다',
                                        border: OutlineInputBorder(),
                                      ),
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
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _memoController,
                          decoration: const InputDecoration(
                            labelText: '메모 (선택사항)',
                            prefixIcon: Icon(Icons.note),
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          maxLines: 3,
                          minLines: 2,
                        ),
                        const SizedBox(height: 16),
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
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '날짜',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormats.yMd.format(_assetDate)),
                                const Icon(Icons.edit_calendar),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                child: Text(_isEdit ? '💾 수정' : '💾 저장'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AssetListScreen(
                                        accountName: widget.accountName,
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('📋 리스트'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text('자산 목록 보기'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AssetListScreen(accountName: widget.accountName),
                        ),
                      );
                    },
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
    return '목표액: ${CurrencyFormatter.format(amount, showUnit: true)}';
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

