part of 'asset_tab_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension AssetTabScreenAuthDialogs on _AssetTabScreenState {
  Future<bool> _showSetRootPinDialog() async {
    if (!mounted) return false;

    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('ROOT PIN 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmartInputField(
                    label: '새 PIN',
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  SmartInputField(
                    label: 'PIN 확인',
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final pin = pinController.text.trim();
                    final confirm = confirmController.text.trim();
                    if (pin.length < 4) {
                      setDialogState(() {
                        error = 'PIN은 최소 4자리 이상이어야 합니다.';
                      });
                      return;
                    }
                    if (pin != confirm) {
                      setDialogState(() {
                        error = 'PIN이 일치하지 않습니다.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) {
      pinController.dispose();
      confirmController.dispose();
      return false;
    }

    final pin = pinController.text.trim();
    pinController.dispose();
    confirmController.dispose();

    final prefs = await SharedPreferences.getInstance();
    await _rootPinService.setPin(prefs, pin: pin);

    if (!mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ROOT PIN이 설정되었습니다')));
    return true;
  }

  // 생체 인증 실행
  Future<bool> _authenticateForAssetProtection() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final pinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
      final passwordEnabled =
          prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
      final biometricEnabled =
          prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;

      final pinConfigured = _userPinService.isPinConfigured(prefs);
      final passwordConfigured = _userPasswordService.isPasswordConfigured(
        prefs,
      );

      final canPin = pinEnabled && pinConfigured;
      final canPassword = passwordEnabled && passwordConfigured;
      final canBiometric = biometricEnabled;
      final any = canPin || canPassword || canBiometric;

      if (!any) {
        // Backward-compatible fallback: if user hasn't enabled any methods,
        // keep using device auth like the old asset protection.
        final result = await _authService.authenticateDevice(
          reason: '자산 정보에 접근하려면 인증이 필요합니다',
        );

        // If device auth is not available (e.g., emulator/no biometrics),
        // allow access as a pragmatic fallback but set the session marker.
        if (result.status == AuthStatus.unavailable) {
          await prefs.setInt(
            PrefKeys.assetAuthSessionUntilMs,
            DateTime.now()
                .add(AuthService.assetSessionTimeout)
                .millisecondsSinceEpoch,
          );
          if (!mounted) return true;
          setState(() => _isAuthenticated = true);
          _resetAutoLockTimer();
          return true;
        }

        if (!result.ok) return false;

        await prefs.setInt(
          PrefKeys.assetAuthSessionUntilMs,
          DateTime.now()
              .add(AuthService.assetSessionTimeout)
              .millisecondsSinceEpoch,
        );

        if (!mounted) return true;
        setState(() => _isAuthenticated = true);
        _resetAutoLockTimer();
        return true;
      }

      if (!mounted) return false;
      final choice = await showDialog<_AssetAuthChoice>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _AssetAuthChoiceDialog(
            canPin: canPin,
            canPassword: canPassword,
            canBiometric: canBiometric,
          );
        },
      );

      if (!mounted) return false;
      if (choice == null || choice == _AssetAuthChoice.exit) return false;

      switch (choice) {
        case _AssetAuthChoice.biometric:
          final result = await _authService.authenticateDevice(
            reason: '자산 정보에 접근하려면 인증이 필요합니다',
          );
          if (!result.ok) return false;
          break;
        case _AssetAuthChoice.pin:
          final ok = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return VerifyCurrentUserPinDialog(
                prefs: prefs,
                service: _userPinService,
              );
            },
          );
          if (ok != true) return false;
          break;
        case _AssetAuthChoice.password:
          final ok = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return VerifyCurrentUserPasswordDialog(
                prefs: prefs,
                service: _userPasswordService,
              );
            },
          );
          if (ok != true) return false;
          break;
        case _AssetAuthChoice.exit:
          return false;
      }

      await prefs.setInt(
        PrefKeys.assetAuthSessionUntilMs,
        DateTime.now()
            .add(AuthService.assetSessionTimeout)
            .millisecondsSinceEpoch,
      );

      if (!mounted) return true;
      setState(() => _isAuthenticated = true);
      _resetAutoLockTimer();
      return true;
    } catch (e) {
      debugPrint('자산 인증 오류: $e');
      return false;
    }
  }
}
