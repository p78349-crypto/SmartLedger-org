import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/backup_service.dart';
import '../utils/account_name_language_tag.dart';
import '../utils/backup_password_bootstrapper.dart';
import '../utils/dialog_utils.dart';
import '../utils/online_password_key_backup_facade.dart';
import '../utils/snackbar_utils.dart';
import '../database/db_encryption_key_manager.dart';

class AccountCreateScreen extends StatefulWidget {
  const AccountCreateScreen({super.key});

  @override
  State<AccountCreateScreen> createState() => _AccountCreateScreenState();
}

class _AccountCreateScreenState extends State<AccountCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  Future<void> _tryBootstrapOnlineKeyBackup({
    required String accountId,
    required String password,
  }) async {
    if (password.trim().isEmpty) return;

    final result = await OnlinePasswordKeyBackupFacade().bootstrapAccount(
      accountId: accountId,
      password: password,
    );

    if (!mounted) return;

    if (result.isSuccess &&
        result.recoveryKeyBase64 != null &&
        result.recoveryKeyBase64!.isNotEmpty) {
      bool recoveryKeyConfirmed = false;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('복구키 보관 안내'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  '아래 복구키는 1회만 표시됩니다.\n안전한 곳에 보관하세요.\n\n'
                  '${result.recoveryKeyBase64}',
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: recoveryKeyConfirmed,
                  onChanged: (value) {
                    setLocalState(() {
                      recoveryKeyConfirmed = value ?? false;
                    });
                  },
                  title: const Text('복구키를 안전한 곳에 보관했습니다'),
                  dense: true,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: recoveryKeyConfirmed
                    ? () => Navigator.of(dialogContext).pop()
                    : null,
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final message = result.message;
    if (message != null && message.isNotEmpty) {
      SnackbarUtils.showWarning(context, message);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final suffix = AccountNameLanguageTag.suffixForLocale(locale);

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 계정 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_outlined),
            tooltip: '암호화 키 복구',
            onPressed: () async {
              final controller = TextEditingController();
              final key = await showDialog<String>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('데이터베이스 암호화 키 복구'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '기기 변경 또는 앱 재설치 시 백업해둔 암호화 키를 입력하세요.\n'
                        '잘못된 키를 입력하면 기존 데이터를 읽을 수 없습니다.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: '암호화 키 (Base64)',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(
                        dialogContext,
                      ).pop(controller.text.trim()),
                      child: const Text('복구'),
                    ),
                  ],
                ),
              );

              if (key != null && key.isNotEmpty) {
                final success =
                    await DbEncryptionKeyManager.restoreKeyFromBackup(key);
                if (!context.mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('암호화 키가 성공적으로 복구되었습니다.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('잘못된 형식의 키입니다. (32바이트 Base64Url 필요)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '계정 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _nameController,
                builder: (context, value, _) {
                  final baseName = value.text.trim();
                  final finalName = AccountNameLanguageTag.applyForcedSuffix(
                    baseName,
                    locale,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '계정명 아래에 언어 태그가 강제 삽입됩니다: $suffix',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                      if (baseName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '최종 계정명: $finalName',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '비밀번호 (선택사항)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordConfirmController,
              obscureText: _obscurePasswordConfirm,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasswordConfirm
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePasswordConfirm = !_obscurePasswordConfirm;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '비밀번호를 설정하지 않으면 누구나 접근할 수 있습니다.',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final baseName = _nameController.text.trim();
                if (baseName.isEmpty) {
                  SnackbarUtils.showWarning(context, '계정 이름을 입력해주세요');
                  return;
                }

                // 비밀번호 검증
                final password = _passwordController.text;
                final passwordConfirm = _passwordConfirmController.text;

                if (password.isNotEmpty || passwordConfirm.isNotEmpty) {
                  if (password != passwordConfirm) {
                    SnackbarUtils.showWarning(context, '비밀번호가 일치하지 않습니다');
                    return;
                  }
                  if (password.length < 4) {
                    SnackbarUtils.showWarning(context, '비밀번호는 최소 4자 이상이어야 합니다');
                    return;
                  }
                }

                final navigator = Navigator.of(context);
                final name = AccountNameLanguageTag.applyForcedSuffix(
                  baseName,
                  locale,
                );
                final newAccount = Account(
                  name: name,
                  password: password.isEmpty ? null : password,
                );
                final added = await AccountService().addAccount(newAccount);
                if (!added) {
                  if (!context.mounted) return;
                  await DialogUtils.showErrorDialog(
                    context,
                    title: '중복된 계정명',
                    message: '이미 존재하는 계정 이름입니다. 다른 이름을 입력해 주세요.',
                  );
                  return;
                }
                if (!context.mounted) return;
                const ensureBackupPasswordConfiguredOnEntry =
                    BackupPasswordBootstrapper
                        .ensureBackupPasswordConfiguredOnEntry;
                await ensureBackupPasswordConfiguredOnEntry(context);
                await _tryBootstrapOnlineKeyBackup(
                  accountId: name,
                  password: password,
                );
                await BackupService().autoBackupIfNeeded(name);
                if (!context.mounted) return;
                SnackbarUtils.showSuccess(context, '계정이 생성되었습니다');
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (context.mounted) navigator.pop(name);
                });
              },
              child: const Text('계정 생성'),
            ),
          ],
        ),
      ),
    );
  }
}
