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

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _ratioController.dispose();
    _targetAmountController.dispose();
    _expectedAnnualRateController.dispose();
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
        final costBasis = _costBasisController.text.isNotEmpty
            ? CurrencyFormatter.parse(_costBasisController.text.trim())
            : null;

        final expectedRateRaw = _expectedAnnualRateController.text.trim();
        final expectedRate =
            expectedRateRaw.isEmpty ? null : double.tryParse(expectedRateRaw);

        if (amount == null) {
          SnackbarUtils.showError(context, '유효한 금액을 입력하세요');
          return;
        }

        final asset = Asset(
          id: widget.initialAsset?.id ??
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
          costBasis: costBasis,
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
                  if (_isEdit && widget.initialAsset != null)
                    _buildOriginalCard(theme),
                  Form(
                    key: _formKey,
                    child: Column(children: _buildFormFields(theme)),
                  ),
                ],
              ),
            );
          },
        ),
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
