part of 'settings_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension SettingsPassword on _SettingsScreenState {
  Future<void> setUserPasswordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final configured = _userPasswordService.isPasswordConfigured(prefs);

    if (enabled && !configured) {
      final didSet = await _showSetUserPasswordDialog();
      if (!didSet) {
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
      // Clear mirrored backup encryption password from secure storage when app password is removed
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

  Future<bool> _showSetUserPasswordDialog() async {
    final pwController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    if (!mounted) {
      pwController.dispose();
      confirmController.dispose();
      return false;
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
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final password = pwController.text;
    pwController.dispose();
    confirmController.dispose();

    await _userPasswordService.setPassword(prefs, password: password);
    // Mirror the app password to the backup encryption password store for auto-backups
    await BackupService().setStoredBackupEncryptionPassword(password);

    if (!mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('유저 계정 비밀번호가 설정되었습니다')));
    return true;
  }

  Future<void> changeUserPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_userPasswordService.isPasswordConfigured(prefs)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 비밀번호를 설정하세요')));
      return;
    }

    if (!mounted) return;
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
    if (ok != true || !mounted) return;

    final didSet = await _showSetUserPasswordDialog();
    if (!didSet || !mounted) return;

    await prefs.setBool(PrefKeys.userPasswordEnabled, true);
    final configuredNow = _userPasswordService.isPasswordConfigured(prefs);
    setState(() {
      _userPasswordEnabled = configuredNow;
      _userPasswordConfigured = configuredNow;
    });
  }
}
