import 'package:flutter/material.dart';
import 'package:smart_ledger/models/account.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/backup_service.dart';
import 'package:smart_ledger/utils/account_name_language_tag.dart';
import 'package:smart_ledger/utils/backup_password_bootstrapper.dart';
import 'package:smart_ledger/utils/dialog_utils.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';

class AccountCreateScreen extends StatefulWidget {
  const AccountCreateScreen({super.key});

  @override
  State<AccountCreateScreen> createState() => _AccountCreateScreenState();
}

class _AccountCreateScreenState extends State<AccountCreateScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
            ElevatedButton(
              onPressed: () async {
                final baseName = _nameController.text.trim();
                if (baseName.isEmpty) {
                  SnackbarUtils.showWarning(context, '계정 이름을 입력해주세요');
                  return;
                }
                final navigator = Navigator.of(context);
                final name = AccountNameLanguageTag.applyForcedSuffix(
                  baseName,
                  locale,
                );
                final newAccount = Account(name: name);
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
