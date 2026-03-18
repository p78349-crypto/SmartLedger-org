part of 'asset_security_settings_screen.dart';

extension AssetSecuritySettingsLogic on _AssetSecuritySettingsScreenState {
  Future<void> _initialize() async {
    await _checkBiometricAvailability();
    await _loadCurrentSettings();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.canUseDeviceAuth();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final pinService = AssetPinService();
    final passwordService = AssetPasswordService();

    setState(() {
      _securityLevel = prefs.getString(PrefKeys.assetSecurityLevel) ?? 'single';
      _pinEnabled = prefs.getBool(PrefKeys.assetPinEnabled) ?? false;
      _biometricEnabled =
          prefs.getBool(PrefKeys.assetBiometricEnabled) ?? false;
      _passwordEnabled = prefs.getBool(PrefKeys.assetPasswordEnabled) ?? false;

      _pinConfigured = pinService.isPinConfigured(prefs);
      _passwordConfigured = passwordService.isPasswordConfigured(prefs);

      _isLoading = false;
    });
  }

  Future<void> _togglePin(bool value) async {
    if (value && !_pinConfigured) {
      await _setupPin();
    } else {
      setState(() {
        _pinEnabled = value;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final result = await _authService.authenticateDevice(
        reason: '자산 보안 생체인식을 활성화합니다',
      );
      if (!result.ok) {
        if (!mounted) return;
        SnackbarUtils.showError(context, '생체인식 테스트에 실패했습니다');
        return;
      }
    }

    setState(() {
      _biometricEnabled = value;
    });
  }

  Future<void> _togglePassword(bool value) async {
    if (value && !_passwordConfigured) {
      await _setupPassword();
    } else {
      setState(() {
        _passwordEnabled = value;
      });
    }
  }

  Future<void> _saveSettings() async {
    final enabledCount =
        (_pinEnabled ? 1 : 0) +
        (_biometricEnabled ? 1 : 0) +
        (_passwordEnabled ? 1 : 0);

    if (_securityLevel == 'single') {
      if (enabledCount == 0) {
        SnackbarUtils.showWarning(context, '최소 1개의 보안 방식을 선택해야 합니다');
        return;
      }
    } else {
      if (enabledCount != 2) {
        SnackbarUtils.showWarning(context, '2중 인증은 정확히 2개의 방식을 선택해야 합니다');
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.assetSecurityLevel, _securityLevel);
    await prefs.setBool(PrefKeys.assetPinEnabled, _pinEnabled);
    await prefs.setBool(PrefKeys.assetBiometricEnabled, _biometricEnabled);
    await prefs.setBool(PrefKeys.assetPasswordEnabled, _passwordEnabled);

    // 활성화된 방식이 1개면 그것을 기본값으로
    String defaultMode = '';
    if (_pinEnabled && !_biometricEnabled && !_passwordEnabled) {
      defaultMode = 'pin';
    } else if (_biometricEnabled && !_pinEnabled && !_passwordEnabled) {
      defaultMode = 'biometric';
    } else if (_passwordEnabled && !_pinEnabled && !_biometricEnabled) {
      defaultMode = 'password';
    } else {
      defaultMode =
          prefs.getString(PrefKeys.assetSecurityMode) ??
          (_pinEnabled
              ? 'pin'
              : (_biometricEnabled ? 'biometric' : 'password'));
    }

    await prefs.setString(PrefKeys.assetSecurityMode, defaultMode);
    await prefs.setBool(PrefKeys.assetAuthEnabled, true);
    await prefs.setBool(PrefKeys.biometricAuthEnabled, true);
    // 기존 assetAuthRequired도 동기화
    await prefs.setBool(PrefKeys.assetAuthRequired, true);

    if (!mounted) return;
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, '자산 보안 설정이 저장되었습니다');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _setupPin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자산 PIN 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (숫자)',
                hintText: '4자리 이상',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'PIN 확인'),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();

              if (pin.length < 4 || !RegExp(r'^\d+$').hasMatch(pin)) {
                SnackbarUtils.showWarning(context, 'PIN은 4자리 이상 숫자여야 합니다');
                return;
              }

              if (pin != confirm) {
                SnackbarUtils.showWarning(context, 'PIN이 일치하지 않습니다');
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true) {
      pinController.dispose();
      confirmController.dispose();
      return;
    }

    final pinValue = pinController.text.trim();
    pinController.dispose();
    confirmController.dispose();

    final prefs = await SharedPreferences.getInstance();
    final pinService = AssetPinService();
    await pinService.setPin(prefs, pin: pinValue);

    if (!mounted) return;
    setState(() {
      _pinConfigured = true;
      _pinEnabled = true;
    });
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, '자산 PIN이 설정되었습니다');
    }
  }

  Future<void> _setupPassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자산 비밀번호 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '최소 6자 이상',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();

              if (password.length < 6) {
                SnackbarUtils.showWarning(context, '비밀번호는 최소 6자 이상이어야 합니다');
                return;
              }

              if (password != confirm) {
                SnackbarUtils.showWarning(context, '비밀번호가 일치하지 않습니다');
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true) {
      passwordController.dispose();
      confirmController.dispose();
      return;
    }

    final passwordValue = passwordController.text.trim();
    passwordController.dispose();
    confirmController.dispose();

    final prefs = await SharedPreferences.getInstance();
    final passwordService = AssetPasswordService();
    await passwordService.setPassword(prefs, password: passwordValue);

    if (!mounted) return;
    setState(() {
      _passwordConfigured = true;
      _passwordEnabled = true;
    });
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, '자산 비밀번호가 설정되었습니다');
    }
  }
}
