// ignore_for_file: invalid_use_of_protected_member
part of 'one_hundred_million_project_screen.dart';

extension _SettingsExt on _OneHundredMillionProjectScreenState {
  Future<void> _openSettings() async {
    final yearsController = TextEditingController(text: '$_projectYears');
    final targetController = TextEditingController(
      text: CurrencyFormatter.format(_projectTargetAmount, showUnit: false),
    );
    final safeRateController = TextEditingController(
      text: _projectSafeRatePct.toStringAsFixed(1),
    );
    final investRateController = TextEditingController(
      text: _projectInvestRatePct.toStringAsFixed(1),
    );
    final cashToInvestController = TextEditingController(
      text: CurrencyFormatter.format(
        _projectCashToInvestThresholdAmount,
        showUnit: false,
      ),
    );

    var includeBenefits = _projectIncludeBenefits;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('1억 프로젝트 설정'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SmartInputField(
                      label: '기간(년)',
                      hint: '예: 10',
                      controller: yearsController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      label: '목표 금액',
                      hint: '예: 100000000',
                      controller: targetController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      label: '안전자산 연이율(%)',
                      hint: '예: 3.0',
                      controller: safeRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      label: '투자자산 연이율(%)',
                      hint: '예: 6.0',
                      controller: investRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('혜택/절약을 매달 적립으로 포함'),
                      value: includeBenefits,
                      onChanged: (v) =>
                          setDialogState(() => includeBenefits = v),
                    ),
                    const SizedBox(height: 12),
                    SmartInputField(
                      label: '비상금→투자 전환 기준(원)',
                      hint: '예: 100000',
                      controller: cashToInvestController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      yearsController.dispose();
      targetController.dispose();
      safeRateController.dispose();
      investRateController.dispose();
      cashToInvestController.dispose();
      return;
    }

    final years = int.tryParse(yearsController.text.trim());
    final target = CurrencyFormatter.parse(targetController.text.trim());
    final safeRate = double.tryParse(safeRateController.text.trim());
    final investRate = double.tryParse(investRateController.text.trim());
    final cashToInvestThreshold = CurrencyFormatter.parse(
      cashToInvestController.text.trim(),
    );

    yearsController.dispose();
    targetController.dispose();
    safeRateController.dispose();
    investRateController.dispose();
    cashToInvestController.dispose();

    setState(() {
      _projectYears = (years ?? _projectYears).clamp(1, 50);
      if (target != null && target >= 0) {
        _projectTargetAmount = target;
      }
      _projectSafeRatePct =
          (safeRate ?? _projectSafeRatePct).clamp(0.0, 100.0);
      _projectInvestRatePct =
          (investRate ?? _projectInvestRatePct).clamp(0.0, 100.0);
      _projectIncludeBenefits = includeBenefits;
      if (cashToInvestThreshold != null && cashToInvestThreshold >= 0) {
        _projectCashToInvestThresholdAmount = cashToInvestThreshold;
      }
    });

    await _saveProject100mPrefs();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('1억 프로젝트 설정이 저장되었습니다.')));
  }
}
