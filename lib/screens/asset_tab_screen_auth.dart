part of 'asset_tab_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension AssetTabScreenAuth on _AssetTabScreenState {
  void _resetAutoLockTimer() {
    _autoLockTimer?.cancel();
    if (!_biometricAuthEnabled) return;
    if (!_isAuthenticated) return;

    // Persist an "unlocked until" marker so other parts of the app can
    // respect the same lock/unlock window.
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(
        PrefKeys.assetAuthSessionUntilMs,
        DateTime.now()
            .add(_AssetTabScreenState._autoLockIdleTimeout)
            .millisecondsSinceEpoch,
      );
    });

    _autoLockTimer = Timer(_AssetTabScreenState._autoLockIdleTimeout, () {
      if (!mounted) return;
      // Auto-lock after inactivity.
      setState(() {
        _isAuthenticated = false;
      });
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove(PrefKeys.assetAuthSessionUntilMs);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('일정 시간 미사용으로 자동 잠금되었습니다')));
    });
  }

  // 생체 인증 설정 로드
  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final enabled =
        (prefs.getBool(PrefKeys.assetAuthEnabled) ?? false) ||
        (prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false);
    setState(() {
      _biometricAuthEnabled = enabled;
      if (!enabled) {
        _isAuthenticated = true;
        _autoLockTimer?.cancel();
        // Security off => clear lock marker.
        prefs.remove(PrefKeys.assetAuthSessionUntilMs);
        prefs.remove(PrefKeys.rootAuthSessionUntilMs);
      }
    });
    _resetAutoLockTimer();
  }

  Future<void> _loadRootAuthEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(PrefKeys.rootAuthEnabled) ??
        (prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false);
    if (!mounted) return;
    setState(() {
      _rootAuthEnabled = enabled;
    });
  }

  Future<void> _setRootAuthEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.rootAuthEnabled, enabled);
    if (!enabled) {
      // Turning off ROOT lock clears only ROOT session.
      await prefs.remove(PrefKeys.rootAuthSessionUntilMs);
    }
    if (!mounted) return;
    setState(() {
      _rootAuthEnabled = enabled;
    });
  }

  Future<void> _loadRootPinState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.rootPinEnabled) ?? false;
    final configured = _rootPinService.isPinConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _rootPinEnabled = enabled && configured;
      _rootPinConfigured = configured;
    });

    if (enabled && !configured) {
      await prefs.setBool(PrefKeys.rootPinEnabled, false);
    }
  }

  Future<void> _setRootPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final configured = _rootPinService.isPinConfigured(prefs);

    if (enabled && !configured) {
      final didSet = await _showSetRootPinDialog();
      if (!didSet) return;
    }

    await prefs.setBool(PrefKeys.rootPinEnabled, enabled);
    await prefs.remove(PrefKeys.rootAuthSessionUntilMs);

    final configuredNow = _rootPinService.isPinConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _rootPinEnabled = enabled && configuredNow;
      _rootPinConfigured = configuredNow;
    });
  }

  Future<void> _loadRootAuthMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(PrefKeys.rootAuthMode) ?? 'integrated';
    if (!mounted) return;
    setState(() {
      _rootAuthMode = mode;
    });
  }

  Future<void> _setRootAuthMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.rootAuthMode, mode);
    if (mode == 'integrated') {
      // Integrated mode uses the asset session only.
      await prefs.remove(PrefKeys.rootAuthSessionUntilMs);
    }
    if (!mounted) return;
    setState(() {
      _rootAuthMode = mode;
    });
  }

  // 생체 인증 설정 저장
  Future<void> _toggleBiometricAuth(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.assetAuthEnabled, value);
    await prefs.setBool(PrefKeys.assetBiometricEnabled, value);
    await prefs.setBool(PrefKeys.biometricAuthEnabled, value);
    if (!mounted) return;
    setState(() {
      _biometricAuthEnabled = value;
      if (!value) {
        _isAuthenticated = true; // 인증 끄면 자동으로 접근 허용
        _autoLockTimer?.cancel();
        prefs.remove(PrefKeys.assetAuthSessionUntilMs);
        prefs.remove(PrefKeys.rootAuthSessionUntilMs);
      } else {
        // Turning security on should require re-auth.
        _isAuthenticated = false;
        prefs.remove(PrefKeys.assetAuthSessionUntilMs);
        prefs.remove(PrefKeys.rootAuthSessionUntilMs);
      }
    });
  }

  // 생체 인증 가능 여부 확인
  Future<void> _checkDeviceAuthSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (!mounted) return;
      setState(() {
        _canCheckBiometrics = canCheck;
        _isDeviceSupported = supported;
      });
    } catch (e) {
      debugPrint('생체 인증 확인 오류: $e');
    }
  }
}
