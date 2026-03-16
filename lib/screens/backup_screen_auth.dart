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
    String? passwordHint,
  }) async {
    final controller = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('백업 암호를 입력하세요.'),
              if (passwordHint != null && passwordHint.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '암호 힌트: $passwordHint',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이 암호는 백업 데이터 해독을 위한 마스터 키입니다.\n'
                '⚠️ 기기를 변경하거나 앱 재설치 시 이 암호를 모르면 절대 복원이 불가능합니다.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller1,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '백업 핀(PIN) 또는 비밀번호',
                  border: OutlineInputBorder(),
                  helperText: '예: 1234 (핀) 또는 영문/기호 조합',
                ),
                keyboardType: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller2,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '암호 확인',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.visiblePassword,
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
              ? '백업 암호를 설정하면 백업 파일이 강력하게 암호화됩니다.\n\n'
                '⚠️ 주의: 암호 분실 시 개발자를 포함해 누구도 데이터를 복구할 수 없습니다. 반드시 암호와 힌트를 안전하게 보관해 주세요.'
              : '이번 백업을 암호화할 수 있습니다.\n\n'
                '⚠️ 주의: 암호를 잊어버리면 백업 파일을 절대 열 수 없으며, 추후 복구 요청이 불가능합니다.',
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
    if (wantsEncrypt != true) return ''; // 암호 없이 진행 (null=취소와 구분)

    final pw = await _promptNewBackupPassword();
    if (pw == null || pw.trim().isEmpty) return ''; // 암호 입력 안 해도 백업 진행

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

    final hint = BackupService().getBackupPasswordHint(text);

    if (_backupTwoFactorEnabled) {
      await _authenticateForBackupProtection(reason: '복원을 위해 인증을 진행합니다.');
    }
    return _promptBackupPassword(
      title: '암호화 백업 복원', 
      confirmText: '복원',
      passwordHint: hint,
    );
  }
}
