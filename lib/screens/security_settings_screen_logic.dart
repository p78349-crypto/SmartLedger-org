part of 'security_settings_screen.dart';

extension SecuritySettingsLogic on _SecuritySettingsScreenState {
  Future<void> _setUserBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled) {
      final can = await _authService.canUseDeviceAuth();
      if (!can) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이 기기에서 지문(기기 인증)을 사용할 수 없습니다')),
        );
        return;
      }
    }

    await prefs.setBool(PrefKeys.userBiometricEnabled, enabled);
    if (!mounted) return;
    setState(() => _userBiometricEnabled = enabled);
  }

  Future<void> _setUserPasswordEnabled(bool enabled) async {
    if (_isLoading) return;

    final prefs = await SharedPreferences.getInstance();
    final configured = _userPasswordService.isPasswordConfigured(prefs);

    if (enabled && !configured) {
      final newPassword = await _showSetUserPasswordDialog();
      if (newPassword == null || newPassword.isEmpty) {
        if (!mounted) return;
        setState(() {
          _userPasswordEnabled = false;
          _userPasswordConfigured = _userPasswordService.isPasswordConfigured(
            prefs,
          );
        });
        return;
      }
    }

    if (!enabled) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('비밀번호 해지'),
            content: const Text('유저 계정 비밀번호를 해지할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('해지'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        if (!mounted) return;
        setState(() => _userPasswordEnabled = true);
        return;
      }

      await _userPasswordService.clearPassword(prefs);
      await BackupService().clearStoredBackupEncryptionPassword();
    }

    await prefs.setBool(PrefKeys.userPasswordEnabled, enabled);
    final configuredNow = _userPasswordService.isPasswordConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _userPasswordEnabled = enabled && configuredNow;
      _userPasswordConfigured = configuredNow;
    });
  }

  Future<void> _changeUserPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_userPasswordService.isPasswordConfigured(prefs)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 비밀번호를 설정하세요')));
      return;
    }

    if (!mounted) return;
    final currentPassword = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return VerifyCurrentUserPasswordDialog(
          prefs: prefs,
          service: _userPasswordService,
          returnPasswordOnSuccess: true,
        );
      },
    );
    if (currentPassword == null || currentPassword.isEmpty || !mounted) return;

    final newPassword = await _showSetUserPasswordDialog();
    if (newPassword == null || newPassword.isEmpty || !mounted) return;

    final accountName = await UserPrefService.getLastAccountName();
    if (accountName != null &&
        accountName.isNotEmpty &&
        accountName != 'ROOT') {
      final rotate = await OnlinePasswordKeyBackupFacade().rotatePassword(
        accountId: accountName,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;
      if (rotate.isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(rotate.message ?? '서버 오프라인 상태입니다.')),
        );
      } else if (!rotate.isSuccess && !rotate.isDisabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(rotate.message ?? '비밀번호 서버 동기화에 실패했습니다.')),
        );
      }
    }

    await prefs.setBool(PrefKeys.userPasswordEnabled, true);
    final configuredNow = _userPasswordService.isPasswordConfigured(prefs);
    setState(() {
      _userPasswordEnabled = configuredNow;
      _userPasswordConfigured = configuredNow;
    });
  }

  Future<String?> _showSetUserPasswordDialog() async {
    final pwController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    if (!mounted) {
      pwController.dispose();
      confirmController.dispose();
      return null;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('유저 계정 비밀번호 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      border: OutlineInputBorder(),
                    ),
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
                    final pw = pwController.text;
                    final confirm = confirmController.text;
                    if (pw.trim().length < 6) {
                      setDialogState(() {
                        error = '비밀번호는 최소 6자 이상이어야 합니다.';
                      });
                      return;
                    }
                    if (pw != confirm) {
                      setDialogState(() {
                        error = '비밀번호가 일치하지 않습니다.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('설정'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      pwController.dispose();
      confirmController.dispose();
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final password = pwController.text;
    pwController.dispose();
    confirmController.dispose();

    await _userPasswordService.setPassword(prefs, password: password);
    await BackupService().setStoredBackupEncryptionPassword(password);

    if (!mounted) return password;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('유저 계정 비밀번호가 설정되었습니다')));
    return password;
  }

  Future<void> _setUserPinEnabled(bool enabled) async {
    if (_isLoading) return;

    final prefs = await SharedPreferences.getInstance();
    final configured = _userPinService.isPinConfigured(prefs);

    if (enabled && !configured) {
      final didSet = await _showSetUserPinDialog();
      if (!didSet) {
        if (!mounted) return;
        setState(() {
          _userPinEnabled = false;
          _userPinConfigured = _userPinService.isPinConfigured(prefs);
        });
        return;
      }
    }

    if (!enabled) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('PIN 해지'),
            content: const Text('유저 계정 PIN을 해지할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('해지'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        if (!mounted) return;
        setState(() => _userPinEnabled = true);
        return;
      }

      await _userPinService.clearPin(prefs);
      await BackupService().clearStoredBackupEncryptionPassword();
    }

    await prefs.setBool(PrefKeys.userPinEnabled, enabled);
    final configuredNow = _userPinService.isPinConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _userPinEnabled = enabled && configuredNow;
      _userPinConfigured = configuredNow;
    });
  }

  Future<void> _changeUserPin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_userPinService.isPinConfigured(prefs)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 PIN을 설정하세요')));
      return;
    }

    if (!mounted) return;
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
    if (ok != true || !mounted) return;

    final didSet = await _showSetUserPinDialog();
    if (!didSet || !mounted) return;

    await prefs.setBool(PrefKeys.userPinEnabled, true);
    final configuredNow = _userPinService.isPinConfigured(prefs);
    setState(() {
      _userPinEnabled = configuredNow;
      _userPinConfigured = configuredNow;
    });
  }

  Future<bool> _showSetUserPinDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    if (!mounted) {
      pinController.dispose();
      confirmController.dispose();
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('유저 계정 PIN 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '새 PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PIN 확인',
                      border: OutlineInputBorder(),
                    ),
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
                  child: const Text('설정'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      pinController.dispose();
      confirmController.dispose();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final pin = pinController.text.trim();
    pinController.dispose();
    confirmController.dispose();

    await _userPinService.setPin(prefs, pin: pin);
    await BackupService().setStoredBackupEncryptionPassword(pin);

    if (!mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('유저 계정 PIN이 설정되었습니다')));
    return true;
  }
}
