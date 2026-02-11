part of 'backup_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension BackupScreenAuth on _BackupScreenState {
  Future<void> _authenticateForBackupProtection({
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final pinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final passwordEnabled =
        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
    final biometricEnabled =
        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;

    final pinConfigured = _userPinService.isPinConfigured(prefs);
    final passwordConfigured = _userPasswordService.isPasswordConfigured(prefs);

    final canPin = pinEnabled && pinConfigured;
    final canPassword = passwordEnabled && passwordConfigured;
    final canBiometric = biometricEnabled;

    final any = canPin || canPassword || canBiometric;
    if (!any) {
      await _authenticateDeviceForBackup(reason: reason);
      return;
    }

    if (!mounted) return;
    final choice = await showDialog<_BackupAuthChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _BackupAuthChoiceDialog(
          canPin: canPin,
          canPassword: canPassword,
          canBiometric: canBiometric,
        );
      },
    );

    if (!mounted) return;
    if (choice == null || choice == _BackupAuthChoice.exit) {
      throw Exception('인증이 취소되었습니다');
    }

    switch (choice) {
      case _BackupAuthChoice.biometric:
        final result = await _authService.authenticateDevice(reason: reason);
        if (!result.ok) {
          throw Exception(result.message ?? '인증이 취소되었습니다');
        }
        return;
      case _BackupAuthChoice.pin:
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
        if (ok != true) throw Exception('PIN 인증이 취소되었습니다');
        return;
      case _BackupAuthChoice.password:
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
        if (ok != true) throw Exception('비밀번호 인증이 취소되었습니다');
        return;
      case _BackupAuthChoice.exit:
        throw Exception('인증이 취소되었습니다');
    }
  }

  Future<void> _authenticateDeviceForBackup({required String reason}) async {
    final auth = LocalAuthentication();
    final canAuth =
        await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (!canAuth) {
      throw Exception('이 기기에서 기기 인증을 사용할 수 없습니다');
    }
    final ok = await auth.authenticate(localizedReason: reason);
    if (!ok) throw Exception('인증이 취소되었습니다');
  }

  Future<String?> _promptBackupPassword({
    required String title,
    required String confirmText,
  }) async {
    final controller = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('백업 암호를 입력하세요.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '암호',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(confirmText),
            ),
          ],
        ),
      );

      if (!mounted) return null;
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.length < 4) {
        SnackbarUtils.showError(context, '암호는 4자 이상으로 설정하세요');
        return null;
      }
      return trimmed;
    } finally {
      controller.dispose();
    }
  }

  Future<String?> _promptNewBackupPassword() async {
    final controller1 = TextEditingController();
    final controller2 = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('백업 암호 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('이 암호는 백업 복원에 필요합니다.\n잊어버리면 복원이 불가능합니다.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller1,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '암호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller2,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '암호 확인',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final a = controller1.text.trim();
                final b = controller2.text.trim();
                if (a.length < 4) {
                  SnackbarUtils.showError(context, '암호는 4자 이상으로 설정하세요');
                  return;
                }
                if (a != b) {
                  SnackbarUtils.showError(context, '암호가 일치하지 않습니다');
                  return;
                }
                Navigator.pop(context, a);
              },
              child: const Text('설정'),
            ),
          ],
        ),
      );
      if (!mounted) return null;
      return value?.trim();
    } finally {
      controller1.dispose();
      controller2.dispose();
    }
  }

  Future<String?> _prepareBackupEncryptionPassword() async {
    if (_backupTwoFactorEnabled) {
      await _authenticateForBackupProtection(reason: '백업 보호를 위해 인증을 진행합니다.');
    }

    final stored = await BackupService().getStoredBackupEncryptionPassword();
    if (_backupEncryptionEnabled &&
        stored != null &&
        stored.trim().isNotEmpty) {
      return stored;
    }

    if (!mounted) return null;
    final wantsEncrypt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('암호화 백업'),
        content: Text(
          _backupEncryptionEnabled
              ? '백업 암호를 설정하면 백업 파일이 암호화됩니다.\n'
                    '지금 설정하지 않으면 암호 없이(평문) 백업됩니다.'
              : '이번 백업을 암호화할 수 있습니다.\n'
                    '암호를 설정하지 않으면 암호 없이(평문) 백업됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('암호 없이'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('암호 걸기'),
          ),
        ],
      ),
    );

    if (!mounted) return null;
    if (wantsEncrypt != true) return null;

    final pw = await _promptNewBackupPassword();
    if (pw == null || pw.trim().isEmpty) return null;

    if (_backupEncryptionEnabled) {
      await BackupService().setStoredBackupEncryptionPassword(pw);
    }
    return pw;
  }

  Future<String?> _prepareRestorePasswordIfNeeded(File file) async {
    // ignore: avoid_slow_async_io
    final text = await file.readAsString();
    final isEncrypted = BackupService().isEncryptedBackupText(text);
    if (!isEncrypted) return null;

    if (_backupTwoFactorEnabled) {
      await _authenticateForBackupProtection(reason: '복원을 위해 인증을 진행합니다.');
    }
    return _promptBackupPassword(title: '암호화 백업 복원', confirmText: '복원');
  }
}
