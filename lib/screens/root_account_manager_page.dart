import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/trash_entry.dart';
import '../navigation/app_routes.dart';
import 'root_account_screen.dart';
import '../services/account_service.dart';
import '../services/asset_service.dart';
import '../services/backup_service.dart';
import '../services/budget_service.dart';
import '../services/fixed_cost_service.dart';
import '../services/root_overview_service.dart';
import '../services/transaction_service.dart';
import '../services/trash_service.dart';
import '../services/user_pref_service.dart';
import '../utils/account_name_language_tag.dart';
import '../utils/snackbar_utils.dart';

class RootAccountManagerPage extends StatefulWidget {
  const RootAccountManagerPage({
    super.key,
    this.embed = false,
    this.onAccountSelected,
    this.onOpenSearch,
    this.onOpenTrash,
  });

  final bool embed;
  final void Function(String)? onAccountSelected;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenTrash;

  @override
  State<RootAccountManagerPage> createState() => _RootAccountManagerPageState();
}

class _RootAccountManagerPageState extends State<RootAccountManagerPage> {
  final TextEditingController _searchController = TextEditingController();
  RootFinancialOverview? _overview;
  bool _loading = false;
  String? _errorMessage;

  static const String _fallbackAccountName = 'A';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _refreshAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterAccount(String name) {
    if (widget.onAccountSelected != null) {
      widget.onAccountSelected!(name);
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(name);
    }
  }

  Future<void> _deleteAccount(String name) async {
    final navigator = Navigator.of(context);
    TrashEntry? trashEntry;
    try {
      final snapshotJson = await BackupService().exportAccountData(name);
      final snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>;
      trashEntry = await TrashService().addAccountSnapshot(
        accountName: name,
        snapshot: snapshot,
      );
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '휴지통 저장 중 오류가 발생했습니다: $e');
      }
    }
    final removed = await AccountService().deleteAccount(name);
    await TransactionService().deleteAccount(name);
    await BudgetService().removeBudget(name);
    await AssetService().deleteAccount(name);
    await FixedCostService().deleteAccount(name);

    final remainingAccounts = AccountService().accounts;
    final lastAccount = await UserPrefService.getLastAccountName();
    if (lastAccount == name) {
      if (remainingAccounts.isNotEmpty) {
        await UserPrefService.setLastAccountName(remainingAccounts.first.name);
      } else {
        await UserPrefService.clearLastAccountName();
      }
    }

    await _refreshAll();
    if (!mounted) return;
    if (!removed) {
      if (trashEntry != null) {
        await TrashService().removeEntry(trashEntry.id);
      }
      if (mounted) {
        SnackbarUtils.showError(context, '계정을 찾을 수 없습니다: $name');
      }
    } else {
      if (mounted) {
        SnackbarUtils.showSuccess(context, '$name 계정이 휴지통으로 이동했습니다.');
      }

      // Option B: if that was the last account, create a fallback account and
      // move the user into it immediately.
      if (AccountService().accounts.isEmpty) {
        final existing = AccountService().getAccountByName(
          _fallbackAccountName,
        );
        if (existing == null) {
          await AccountService().addAccount(
            Account(name: _fallbackAccountName),
          );
        }
        await UserPrefService.setLastAccountName(_fallbackAccountName);
        await _refreshAll();
        if (!mounted) return;

        if (navigator.canPop()) {
          navigator.pop(_fallbackAccountName);
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.accountMain,
            (route) => false,
            arguments: const AccountMainArgs(accountName: _fallbackAccountName),
          );
        }
        return;
      }

      if (navigator.canPop()) {
        navigator.pop(name);
      }
    }
  }

  Future<void> _showCreateAccountDialog() async {
    final controller = TextEditingController();
    final navigator = Navigator.of(context);
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('새 계정 이름 입력'),
          content: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final locale = Localizations.localeOf(dialogContext);
              final suffix = AccountNameLanguageTag.suffixForLocale(locale);
              final baseName = value.text.trim();
              final finalName = AccountNameLanguageTag.applyForcedSuffix(
                baseName,
                locale,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: '계정명'),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final baseName = controller.text.trim();
                if (baseName.isNotEmpty) {
                  final locale = Localizations.localeOf(dialogContext);
                  final value = AccountNameLanguageTag.applyForcedSuffix(
                    baseName,
                    locale,
                  );
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('생성'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (!mounted) return;
    if (result == null || result.isEmpty) {
      return;
    }

    final added = await AccountService().addAccount(Account(name: result));
    if (!added) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '이미 존재하는 계정입니다: $result');
      return;
    }
    await _refreshAll();
    if (!mounted) return;
    if (navigator.canPop()) {
      navigator.pop(result);
    } else {
      _enterAccount(result);
    }
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final overview = await RootOverviewService().buildOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '데이터를 불러오지 못했습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RootAccountScreen(
      overview: _overview,
      isLoading: _loading,
      errorMessage: _errorMessage,
      searchController: _searchController,
      onRefresh: _refreshAll,
      onEnterAccount: _enterAccount,
      onDeleteAccount: _deleteAccount,
      onCreateAccount: _showCreateAccountDialog,
      showInlineAccountControls: !widget.embed,
      showSearchField: !widget.embed,
      onOpenSearch: widget.onOpenSearch,
      onOpenTrash: widget.onOpenTrash,
      useScaffold: !widget.embed,
    );
  }
}
