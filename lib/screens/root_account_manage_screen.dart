import 'package:flutter/material.dart';
import '../models/account.dart';
import '../navigation/app_routes.dart';
import '../services/account_service.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../services/budget_service.dart';
import '../services/emergency_fund_service.dart';
import '../services/fixed_cost_service.dart';
import '../services/savings_plan_service.dart';
import '../services/income_split_service.dart';
import '../services/transaction_service.dart';
import '../services/trash_service.dart';
import '../services/user_pref_service.dart';
import '../utils/account_name_language_tag.dart';
import '../utils/dialog_utils.dart';
import '../utils/icon_catalog.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/root_auth_gate.dart';

/// ROOT 전용 - 계정 삭제 관리
class RootAccountManageScreen extends StatefulWidget {
  const RootAccountManageScreen({super.key});

  @override
  State<RootAccountManageScreen> createState() =>
      _RootAccountManageScreenState();
}

class _RootAccountManageScreenState extends State<RootAccountManageScreen> {
  List<Account> _accounts = [];
  bool _isLoading = true;

  static const String _fallbackAccountName = 'A';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    await AccountService().loadAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = List<Account>.from(AccountService().accounts);
      _isLoading = false;
    });
  }

  Future<void> _deleteAccount(Account account) async {
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: '계정 삭제',
      message:
          '정말로 "${account.name}" 계정을 삭제하시겠습니까?\n'
          '(해당 계정의 모든 데이터가 삭제됩니다)',
      confirmText: '삭제',
      isDangerous: true,
    );

    if (!confirm) return;

    final deletedName = account.name;
    final removed = await AccountService().deleteAccount(deletedName);

    if (!mounted) return;

    if (!removed) {
      SnackbarUtils.showError(context, '계정을 찾을 수 없습니다: $deletedName');
      return;
    }

    // Purge all account-scoped data after confirming the account row removal.
    await TransactionService().deleteAccount(deletedName);
    await BudgetService().removeBudget(deletedName);
    await AssetService().deleteAccount(deletedName);
    await AssetMoveService().deleteAccount(deletedName);
    await FixedCostService().deleteAccount(deletedName);
    await EmergencyFundService().deleteAccount(deletedName);
    await SavingsPlanService().deleteAccount(deletedName);
    await TrashService().purgeAccount(deletedName);
    await IncomeSplitService().deleteAccount(deletedName);
    await UserPrefService.clearAllAccountScopedPrefs(accountName: deletedName);

    // If the deleted account was the active one, update the pointer.
    final lastAccount = await UserPrefService.getLastAccountName();
    final remainingAccounts = AccountService().accounts;
    if (lastAccount == deletedName) {
      if (remainingAccounts.isNotEmpty) {
        await UserPrefService.setLastAccountName(remainingAccounts.first.name);
      } else {
        await UserPrefService.clearLastAccountName();
      }
    }

    // Option B: never stay in a 0-account state.
    if (remainingAccounts.isEmpty) {
      final existing = AccountService().getAccountByName(_fallbackAccountName);
      if (existing == null) {
        await AccountService().addAccount(Account(name: _fallbackAccountName));
      }
      await UserPrefService.setLastAccountName(_fallbackAccountName);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.accountMain,
        (route) => false,
        arguments: const AccountMainArgs(accountName: _fallbackAccountName),
      );
      return;
    }

    if (!mounted) return;

    SnackbarUtils.showSuccess(context, '$deletedName 계정이 삭제되었습니다');
    await _loadAccounts();
  }

  Future<void> _showCreateAccountDialog() async {
    final controller = TextEditingController();
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
    await _loadAccounts();
    if (!mounted) return;
    SnackbarUtils.showSuccess(context, '$result 계정이 생성되었습니다');
  }

  @override
  Widget build(BuildContext context) {
    final labelByAccount = <String, String>{};
    int userIndex = 0;
    for (final a in _accounts) {
      final name = a.name;
      if (name.trim().toUpperCase() == 'ROOT') {
        labelByAccount[name] = 'ROOT';
        continue;
      }
      userIndex++;
      if (userIndex == 1) {
        labelByAccount[name] = '유저1';
      } else if (userIndex == 2) {
        labelByAccount[name] = '유저2';
      }
    }

    return RootAuthGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ROOT 계정 관리'),
          actions: [
            IconButton(
              icon: const Icon(IconCatalog.add),
              tooltip: '계정 추가',
              onPressed: _showCreateAccountDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // CEO 대시보드 링크 (ROOT 전용)
                  Card(
                    child: ListTile(
                      leading: const Icon(IconCatalog.insightsOutlined),
                      title: const Text('CEO 비서 대시보드'),
                      subtitle: const Text('전략 지표 및 복구 계획 보기'),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.ceoAssistant),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '계정을 삭제하면 해당 계정의 모든 데이터가 삭제됩니다.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ..._accounts.map((a) {
                    final label = labelByAccount[a.name];
                    return Card(
                      child: ListTile(
                        title: Text(a.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (label != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  label,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ),
                            IconButton(
                              icon: const Icon(IconCatalog.deleteOutline),
                              tooltip: '계정 삭제',
                              onPressed: () => _deleteAccount(a),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
