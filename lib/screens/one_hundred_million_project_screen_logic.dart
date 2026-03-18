part of 'one_hundred_million_project_screen.dart';

extension OneHundredMillionProjectScreenLogic
    on _OneHundredMillionProjectScreenState {
  Future<void> _loadData() async {
    _isRestoringData = true;
    final prefs = await SharedPreferences.getInstance();
    final years = prefs.getInt(PrefKeys.project100mYearsV1) ?? 10;
    final savedProjectName = prefs.getString(PrefKeys.project100mNameV1);
    _selectedYears = _normalizeYears(years);
    _yearsController.text = _selectedYears.toString();
    _projectName = (savedProjectName ?? '').trim().isEmpty
        ? _defaultProjectName()
        : savedProjectName!.trim();
    _projectNameController.text = _projectName;

    // 저장된 금액 불러오기
    final cardAmount = prefs.getDouble('project_card_amount') ?? 0;
    final martAmount = prefs.getDouble('project_mart_amount') ?? 0;
    final shoppingAmount = prefs.getDouble('project_shopping_amount') ?? 0;
    final etcAmount = prefs.getDouble('project_etc_amount') ?? 0;
    final interestRate = prefs.getDouble('project_interest_rate') ?? 3.0;

    if (cardAmount > 0) _cardController.text = cardAmount.toInt().toString();
    if (martAmount > 0) _martController.text = martAmount.toInt().toString();
    if (shoppingAmount > 0) {
      _shoppingController.text = shoppingAmount.toInt().toString();
    }
    if (etcAmount > 0) _etcController.text = etcAmount.toInt().toString();
    _interestRateController.text = interestRate.toString();

    if (!mounted) {
      _isRestoringData = false;
      return;
    }
    setState(() {
      _isSettingsDirty = false;
    });
    _isRestoringData = false;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.project100mYearsV1, _selectedYears);
    await prefs.setString(PrefKeys.project100mNameV1, _projectName);
    await prefs.setDouble(
      'project_card_amount',
      _parseAmount(_cardController.text),
    );
    await prefs.setDouble(
      'project_mart_amount',
      _parseAmount(_martController.text),
    );
    await prefs.setDouble(
      'project_shopping_amount',
      _parseAmount(_shoppingController.text),
    );
    await prefs.setDouble(
      'project_etc_amount',
      _parseAmount(_etcController.text),
    );
    await prefs.setDouble(
      'project_interest_rate',
      _parseAmount(_interestRateController.text),
    );
  }

  Future<void> _saveProjectSettings() async {
    final inputName = _projectNameController.text.trim();
    if (inputName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로젝트 이름을 입력하세요')));
      return;
    }

    final parsedYears = int.tryParse(_yearsController.text.trim());
    final years = _normalizeYears(parsedYears ?? _selectedYears);

    setState(() {
      _projectName = inputName;
      _selectedYears = years;
      _yearsController.text = years.toString();
      _isSettingsDirty = false;
      _showSavedState = true;
    });

    await _saveData();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('설정이 저장되었습니다')));

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _showSavedState = false;
      });
    });
  }

  void _markSettingsDirty() {
    if (_isRestoringData) return;
    if (_isSettingsDirty) return;
    if (!mounted) return;
    setState(() {
      _isSettingsDirty = true;
    });
  }

  void _calculateTotal() {
    final card = _parseAmount(_cardController.text);
    final mart = _parseAmount(_martController.text);
    final shopping = _parseAmount(_shoppingController.text);
    final etc = _parseAmount(_etcController.text);

    final total = card + mart + shopping + etc;
    final percentage = total > 0
        ? (total / _targetAmount * 100).toDouble()
        : 0.0;

    setState(() {
      _totalAmount = total;
      _progressPercentage = percentage;
    });

    _saveData();
  }
}
