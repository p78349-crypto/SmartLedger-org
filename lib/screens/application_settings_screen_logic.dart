part of 'application_settings_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension ApplicationSettingsLogic on _ApplicationSettingsScreenState {
  Future<void> _loadFoodExpiryFeedbackTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(PrefKeys.foodExpirySavedFeedbackTemplateV1) ?? '';
    if (!mounted) return;
    setState(() {
      _foodExpiryFeedbackTemplateController.text = t;
    });
  }

  Future<void> _saveFoodExpiryFeedbackTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final t = _foodExpiryFeedbackTemplateController.text.trim();
    if (t.isEmpty) {
      await prefs.remove(PrefKeys.foodExpirySavedFeedbackTemplateV1);
    } else {
      await prefs.setString(PrefKeys.foodExpirySavedFeedbackTemplateV1, t);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('피드백 문구 템플릿을 저장했습니다.')));
  }

  Future<void> _resetFoodExpiryFeedbackTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.foodExpirySavedFeedbackTemplateV1);
    if (!mounted) return;
    setState(() {
      _foodExpiryFeedbackTemplateController.text = '';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('피드백 문구 템플릿을 기본값으로 되돌렸습니다.')));
  }

  Future<void> _loadStockUseSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final vFood = prefs.getInt(PrefKeys.stockUseAutoAddDepletionDaysFoodV1);
    final vHousehold = prefs.getInt(
      PrefKeys.stockUseAutoAddDepletionDaysHouseholdV1,
    );

    final notifyEnabled = prefs.getBool(
      PrefKeys.stockUsePredictedDepletionNotifyEnabledV1,
    );

    final legacy = prefs.getInt(PrefKeys.stockUseAutoAddDepletionDaysV1);
    if (!mounted) return;
    setState(() {
      _stockAutoAddDaysFood = (vFood ?? legacy ?? 3).clamp(1, 30);
      _stockAutoAddDaysHousehold = (vHousehold ?? legacy ?? 5).clamp(1, 30);
      _stockDepletionNotifyEnabled = notifyEnabled ?? true;
    });
  }

  Future<void> _setStockDepletionNotifyEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.stockUsePredictedDepletionNotifyEnabledV1, v);
    if (!mounted) return;
    setState(() {
      _stockDepletionNotifyEnabled = v;
    });
  }

  Future<void> _setStockAutoAddDaysFood(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.stockUseAutoAddDepletionDaysFoodV1, v);
    if (!mounted) return;
    setState(() {
      _stockAutoAddDaysFood = v;
    });
  }

  Future<void> _setStockAutoAddDaysHousehold(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.stockUseAutoAddDepletionDaysHouseholdV1, v);
    if (!mounted) return;
    setState(() {
      _stockAutoAddDaysHousehold = v;
    });
  }

  Future<void> _loadTxRecentInputSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.txRecentInputsEnabledV1);
    final autofill = prefs.getBool(PrefKeys.txRecentInputsAutofillEnabledV1);
    final maxCount = prefs.getInt(PrefKeys.txRecentInputsMaxCountV1);

    if (!mounted) return;
    setState(() {
      _txRecentEnabled = enabled ?? true;
      _txRecentAutofill = autofill ?? true;
      _txRecentMaxCount = (maxCount ?? 30).clamp(1, 100);
    });
  }

  Future<void> _setTxRecentEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.txRecentInputsEnabledV1, v);
    if (!mounted) return;
    setState(() {
      _txRecentEnabled = v;
    });
  }

  Future<void> _setTxRecentAutofill(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.txRecentInputsAutofillEnabledV1, v);
    if (!mounted) return;
    setState(() {
      _txRecentAutofill = v;
    });
  }

  Future<void> _setTxRecentMaxCount(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.txRecentInputsMaxCountV1, v);
    if (!mounted) return;
    setState(() {
      _txRecentMaxCount = v;
    });
  }

  Future<void> _clearTxRecentInputs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('입력내용 삭제'),
        content: const Text('저장된 상품명/결제수단/메모 입력내용을 모두 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_descriptions', const <String>[]);
    await prefs.setStringList('recent_payments', const <String>[]);
    await prefs.setStringList('recent_memos', const <String>[]);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('저장된 입력내용을 삭제했습니다.')));
  }

  Future<void> _checkPermissions() async {
    // Android 13+ (API 33+) uses Permission.photos and Permission.notification
    // Older versions use Permission.storage
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    final notificationStatus = await Permission.notification.status;

    final hasStorage = photosStatus.isGranted || storageStatus.isGranted;
    final hasNotification = notificationStatus.isGranted;

    if (!mounted) return;
    setState(() {
      _hasPermissions = hasStorage && hasNotification;
      _isChecking = false;
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.photos,
      Permission.storage,
      Permission.notification,
    ].request();

    _checkPermissions();
  }
}
