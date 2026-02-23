import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../models/trash_entry.dart';
import '../services/account_service.dart';
import '../services/asset_service.dart';
import '../services/backup_service.dart';
import '../services/transaction_service.dart';
import '../services/trash_service.dart';
import '../utils/account_name_language_tag.dart';
import '../utils/utils.dart';

/// Restore logic for TrashScreen, extracted as a mixin.
mixin TrashScreenRestoreMixin<T extends StatefulWidget> on State<T> {
  Future<void> loadEntries();

  Future<void> restoreEntry(TrashEntry entry) async {
    switch (entry.entityType) {
      case TrashEntityType.transaction:
        await _restoreTransaction(entry);
        break;
      case TrashEntityType.asset:
        await _restoreAsset(entry);
        break;
      case TrashEntityType.account:
        await _restoreAccount(entry);
        break;
    }
  }

  Future<void> _restoreTransaction(TrashEntry entry) async {
    try {
      final accountName = entry.accountName;
      final accountService = AccountService();
      await accountService.loadAccounts();
      if (accountService.getAccountByName(accountName) == null) {
        final added = await accountService.addAccount(
          Account(name: accountName),
        );
        if (!added) {
          if (!mounted) return;
          SnackbarUtils.showError(
            context,
            '계정을 생성할 수 없습니다: $accountName',
          );
          return;
        }
      }
      final transaction = Transaction.fromJson(entry.payload);
      await TransactionService().addTransaction(
        accountName,
        transaction,
      );
      await TrashService().removeEntry(entry.id);
      await loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '거래가 복원되었습니다.');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        '거래 복원 중 오류가 발생했습니다: $e',
      );
    }
  }

  Future<void> _restoreAsset(TrashEntry entry) async {
    try {
      final accountName = entry.accountName;
      final accountService = AccountService();
      await accountService.loadAccounts();
      if (accountService.getAccountByName(accountName) == null) {
        final added = await accountService.addAccount(
          Account(name: accountName),
        );
        if (!added) {
          if (!mounted) return;
          SnackbarUtils.showError(
            context,
            '계정을 생성할 수 없습니다: $accountName',
          );
          return;
        }
      }
      final asset = Asset.fromJson(entry.payload);
      await AssetService().addAsset(accountName, asset);
      await TrashService().removeEntry(entry.id);
      await loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '자산이 복원되었습니다.');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        '자산 복원 중 오류가 발생했습니다: $e',
      );
    }
  }

  Future<void> _restoreAccount(TrashEntry entry) async {
    final originalName = entry.accountName;
    final controller = TextEditingController(text: originalName);
    String? confirmedName;
    try {
      confirmedName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('계정 복원'),
          content: AccountRestoreDialogContent(
            controller: controller,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final baseName = controller.text.trim();
                if (baseName.isNotEmpty) {
                  final locale = Localizations.localeOf(ctx);
                  final finalName =
                      AccountNameLanguageTag.applyForcedSuffix(
                        baseName,
                        locale,
                      );
                  Navigator.of(ctx).pop(finalName);
                }
              },
              child: const Text('복원'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (!mounted) return;
    if (confirmedName == null || confirmedName.isEmpty) return;

    final accountService = AccountService();
    await accountService.loadAccounts();
    if (accountService.getAccountByName(confirmedName) != null) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        '이미 존재하는 계정입니다: $confirmedName',
      );
      return;
    }
    try {
      final snapshot = Map<String, dynamic>.from(entry.payload);
      final encoded = jsonEncode(snapshot);
      await BackupService().importAccountDataAsNew(
        encoded,
        confirmedName,
      );
      await TrashService().removeEntry(entry.id);
      await loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        '$confirmedName 계정이 복원되었습니다.\n(보안: 비밀번호는 새로 설정해주세요)',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        '계정 복원 중 오류가 발생했습니다: $e',
      );
    }
  }
}

/// Dialog content for account restore name input.
class AccountRestoreDialogContent extends StatelessWidget {
  const AccountRestoreDialogContent({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final locale = Localizations.localeOf(context);
        final suffix =
            AccountNameLanguageTag.suffixForLocale(locale);
        final baseName = value.text.trim();
        final finalName = AccountNameLanguageTag.applyForcedSuffix(
          baseName,
          locale,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('복원할 계정 이름을 입력하세요.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '계정명',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              '언어 태그가 강제 삽입됩니다: $suffix',
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
    );
  }
}
