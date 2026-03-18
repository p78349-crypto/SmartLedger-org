import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../utils/date_formats.dart';
import '../utils/utils.dart';
import '../widgets/smart_input_field.dart';

part 'asset_input_screen_helpers.dart';
part 'asset_input_screen_form.dart';

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
  final TextEditingController _costBasisController = TextEditingController();
  final TextEditingController _tickerController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _appraisalValueController =
      TextEditingController();
  final TextEditingController _monthlyIncomeController =
      TextEditingController();
  final TextEditingController _debtAmountController = TextEditingController();
  final TextEditingController _alertThresholdController =
      TextEditingController();
  late DateTime _assetDate;
  DateTime? _maturityDate;
  AssetCategory _selectedCategory = AssetCategory.stock;
  bool _isInvestment = false;
  AssetRiskLevel? _riskLevel;
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
      if (initial.ticker != null && initial.ticker!.isNotEmpty) {
        _tickerController.text = initial.ticker!;
      }
      if (initial.institution != null && initial.institution!.isNotEmpty) {
        _institutionController.text = initial.institution!;
      }
      if (initial.currencyCode != null && initial.currencyCode!.isNotEmpty) {
        _currencyController.text = initial.currencyCode!;
      }
      if (initial.units != null) {
        _unitsController.text = initial.units!.toString();
      }
      if (initial.unitPrice != null) {
        _unitPriceController.text = CurrencyFormatter.format(
          initial.unitPrice!,
          showUnit: false,
        );
      }
      if (initial.appraisalValue != null) {
        _appraisalValueController.text = CurrencyFormatter.format(
          initial.appraisalValue!,
          showUnit: false,
        );
      }
      if (initial.monthlyIncome != null) {
        _monthlyIncomeController.text = CurrencyFormatter.format(
          initial.monthlyIncome!,
          showUnit: false,
        );
      }
      if (initial.debtAmount != null) {
        _debtAmountController.text = CurrencyFormatter.format(
          initial.debtAmount!,
          showUnit: false,
        );
      }
      if (initial.alertThreshold != null) {
        _alertThresholdController.text = CurrencyFormatter.format(
          initial.alertThreshold!,
          showUnit: false,
        );
      }
      _maturityDate = initial.maturityDate;
      _riskLevel = initial.riskLevel;
    } else {
      _assetDate = DateTime.now();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _ratioController.dispose();
    _targetAmountController.dispose();
    _expectedAnnualRateController.dispose();
    _costBasisController.dispose();
    _tickerController.dispose();
    _institutionController.dispose();
    _currencyController.dispose();
    _unitsController.dispose();
    _unitPriceController.dispose();
    _appraisalValueController.dispose();
    _monthlyIncomeController.dispose();
    _debtAmountController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        double? targetRatio;
        if (_ratioController.text.isNotEmpty) {
          targetRatio = double.tryParse(_ratioController.text.trim());
        }

        final amount =
            CurrencyFormatter.parse(_amountController.text.trim()) ?? 0.0;

        final targetAmount = _targetAmountController.text.isNotEmpty
            ? CurrencyFormatter.parse(_targetAmountController.text.trim())
            : null;
        final costBasis = _costBasisController.text.isNotEmpty
            ? CurrencyFormatter.parse(_costBasisController.text.trim())
            : null;

        final expectedRateRaw = _expectedAnnualRateController.text.trim();
        final expectedRate = expectedRateRaw.isEmpty
            ? null
            : double.tryParse(expectedRateRaw);

        final tickerRaw = _tickerController.text.trim();
        final institutionRaw = _institutionController.text.trim();
        final currencyRaw = _currencyController.text.trim();

        final unitsRaw = _unitsController.text.trim();
        final units = unitsRaw.isEmpty ? null : double.tryParse(unitsRaw);
        final unitPrice = _unitPriceController.text.isNotEmpty
            ? CurrencyFormatter.parse(_unitPriceController.text.trim())
            : null;
        final appraisalValue = _appraisalValueController.text.isNotEmpty
            ? CurrencyFormatter.parse(_appraisalValueController.text.trim())
            : null;
        final monthlyIncome = _monthlyIncomeController.text.isNotEmpty
            ? CurrencyFormatter.parse(_monthlyIncomeController.text.trim())
            : null;

        String name = _nameController.text.trim();
        if (name.isEmpty) name = '새 자산';

        final asset = Asset(
          id:
              widget.initialAsset?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          amount: amount,
          memo: _memoController.text.trim(),
          date: _assetDate,
          category: _selectedCategory,
          expectedAnnualRatePct: expectedRate,
          targetRatio: targetRatio,
          targetAmount: targetAmount,
          isInvestment:
              _isInvestment && _selectedCategory == AssetCategory.crypto,
          costBasis: costBasis,
          ticker: tickerRaw.isEmpty ? null : tickerRaw,
          institution: institutionRaw.isEmpty ? null : institutionRaw,
          currencyCode: currencyRaw.isEmpty ? null : currencyRaw,
          units: units,
          unitPrice: unitPrice,
          appraisalValue: appraisalValue,
          monthlyIncome: monthlyIncome,
          riskLevel: _riskLevel,
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
          if (mounted) Navigator.of(context).pop(true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 상세 입력'),
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
                  if (_isEdit && widget.initialAsset != null)
                    _buildOriginalCard(theme),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        ..._buildFormFields(theme),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submit,
        icon: Icon(_isEdit ? Icons.save : Icons.add_task),
        label: Text(_isEdit ? '수정 완료' : '자산 저장'),
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
    required this.tickerText,
    required this.institutionText,
    required this.currencyText,
    required this.unitsText,
    required this.unitPriceText,
    required this.appraisalValueText,
    required this.monthlyIncomeText,
    required this.debtAmountText,
    required this.alertThresholdText,
    required this.assetDate,
    required this.maturityDate,
    required this.selectedCategory,
    required this.isInvestment,
    required this.riskLevel,
  });

  final String nameText;
  final String amountText;
  final String memoText;
  final String ratioText;
  final String targetAmountText;
  final String costBasisText;
  final String expectedAnnualRateText;
  final String tickerText;
  final String institutionText;
  final String currencyText;
  final String unitsText;
  final String unitPriceText;
  final String appraisalValueText;
  final String monthlyIncomeText;
  final String debtAmountText;
  final String alertThresholdText;
  final DateTime assetDate;
  final DateTime? maturityDate;
  final AssetCategory selectedCategory;
  final bool isInvestment;
  final AssetRiskLevel? riskLevel;
}
