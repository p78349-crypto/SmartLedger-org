part of 'root_security_setup_screen.dart';

extension RootSecuritySetupScreenLogic on _RootSecuritySetupScreenState {
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

    final pinService = RootPinService();

    setState(() {
      _securityLevel = prefs.getString(PrefKeys.rootSecurityLevel) ?? 'single';
      _pinEnabled = prefs.getBool(PrefKeys.rootPinEnabled) ?? false;
      _biometricEnabled = prefs.getBool(PrefKeys.rootBiometricEnabled) ?? false;
      _passwordEnabled = prefs.getBool(PrefKeys.rootPasswordEnabled) ?? false;

      // PIN과 비밀번호는 별도 저장소에서 각각 확인
      _pinConfigured = pinService.isPinConfigured(prefs);
      _passwordConfigured = pinService.isPasswordConfigured(prefs);

      _isLoading = false;
    });
  }

  Future<void> _togglePin(bool value) async {
    if (value && !_pinConfigured) {
      // PIN이 설정되지 않았으면 먼저 설정
      await _setupPin();
    } else {
      setState(() {
        _pinEnabled = value;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // 생체인식 테스트
      final result = await _authService.authenticateDevice(
        reason: 'ROOT 보안 생체인식을 활성화합니다',
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
      // 비밀번호가 설정되지 않았으면 먼저 설정
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

    // 보안 강도에 따른 검증
    if (_securityLevel == 'single') {
      // 단일 인증: 최소 1개
      if (enabledCount == 0) {
        SnackbarUtils.showWarning(context, '최소 1개의 보안 방식을 선택해야 합니다');
        return;
      }
    } else {
      // 2중 인증: 정확히 2개
      if (enabledCount != 2) {
        SnackbarUtils.showWarning(context, '2중 인증은 정확히 2개의 방식을 선택해야 합니다');
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.rootSecurityLevel, _securityLevel);
    await prefs.setBool(PrefKeys.rootPinEnabled, _pinEnabled);
    await prefs.setBool(PrefKeys.rootBiometricEnabled, _biometricEnabled);
    await prefs.setBool(PrefKeys.rootPasswordEnabled, _passwordEnabled);

    // 활성화된 방식이 1개면 그것을 기본값으로
    String defaultMode = '';
    if (_pinEnabled && !_biometricEnabled && !_passwordEnabled) {
      defaultMode = 'pin';
    } else if (_biometricEnabled && !_pinEnabled && !_passwordEnabled) {
      defaultMode = 'biometric';
    } else if (_passwordEnabled && !_pinEnabled && !_biometricEnabled) {
      defaultMode = 'password';
    } else {
      // 여러 개 활성화된 경우, 기존 설정 유지 또는 첫 번째 것으로
      defaultMode =
          prefs.getString(PrefKeys.rootSecurityMode) ??
          (_pinEnabled
              ? 'pin'
              : (_biometricEnabled ? 'biometric' : 'password'));
    }

    await prefs.setString(PrefKeys.rootSecurityMode, defaultMode);
    await prefs.setBool(PrefKeys.rootAuthEnabled, true);

    if (!mounted) return;
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, 'ROOT 보안 설정이 저장되었습니다');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _setupPin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ROOT PIN 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (6자리 숫자)',
                hintText: '000000',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'PIN 확인'),
              keyboardType: TextInputType.number,
              maxLength: 6,
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

              if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
                SnackbarUtils.showWarning(context, 'PIN은 6자리 숫자여야 합니다');
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
    final pinService = RootPinService();
    await pinService.setPin(prefs, pin: pinValue);

    if (!mounted) return;
    setState(() {
      _pinConfigured = true;
      _pinEnabled = true;
    });
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, 'ROOT PIN이 설정되었습니다');
    }
  }

  Future<void> _setupPassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ROOT 비밀번호 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '영문, 숫자 조합 (최소 8자)',
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

              if (password.length < 8) {
                SnackbarUtils.showWarning(context, '비밀번호는 최소 8자 이상이어야 합니다');
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
    final pinService = RootPinService();
    await pinService.setPassword(prefs, password: passwordValue);

    if (!mounted) return;
    setState(() {
      _passwordConfigured = true;
      _passwordEnabled = true;
    });
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, 'ROOT 비밀번호가 설정되었습니다');
    }
  }
}
