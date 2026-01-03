import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/auth_service.dart';
import 'package:smart_ledger/services/backup_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';

class BackupPasswordBootstrapper {
  const BackupPasswordBootstrapper._();

  static Future<void> ensureBackupPasswordConfiguredOnEntry(
    BuildContext context,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();
    final encryptionEnabled =
        prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false;
    if (!encryptionEnabled) return;

    final existing = await BackupService().getStoredBackupEncryptionPassword();
    if (existing != null && existing.trim().isNotEmpty) return;

    // Avoid repeated prompting within the same app session.
    if (!BackupService().consumeBackupPasswordSetupNoticeToken()) return;

    if (!context.mounted) return;
    final wantsSetup = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 암호 설정'),
        content: const Text(
          '백업 암호화가 켜져 있지만, 저장된 백업 암호가 없습니다.\n'
          '앱 진입 시 암호를 1회 설정하면 자동백업도 암호화할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('설정'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (wantsSetup != true) return;

    // If two-factor is enabled, require device auth before setting a password.
    final device = await AuthService().maybeAuthenticateBackupRestore(
      prefs: prefs,
      reason: '백업 암호 설정을 위해 기기 인증을 진행합니다.',
    );
    if (!device.ok) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(device.message ?? '인증이 필요합니다'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final pw = await _promptNewBackupPassword(context);
    if (!context.mounted) return;
    if (pw == null || pw.trim().isEmpty) return;

    await BackupService().setStoredBackupEncryptionPassword(pw);
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('백업 암호가 설정되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Future<String?> _promptNewBackupPassword(BuildContext context) async {
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

      return value?.trim();
    } finally {
      controller1.dispose();
      controller2.dispose();
    }
  }
}

