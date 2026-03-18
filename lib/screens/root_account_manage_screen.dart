import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../navigation/app_routes.dart';
import '../services/account_service.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/emergency_fund_service.dart';
import '../services/fixed_cost_service.dart';
import '../services/root_pin_service.dart';
import '../services/savings_plan_service.dart';
import '../services/income_split_service.dart';
import '../services/transaction_service.dart';
import '../services/trash_service.dart';
import '../services/user_pin_service.dart';
import '../services/user_pref_service.dart';
import '../services/user_password_service.dart';
import '../utils/account_name_language_tag.dart';
import '../utils/dialog_utils.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/root_auth_gate.dart';
part 'root_account_manage_screen_logic.dart';

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
  bool _rootAuthEnabled = false;
  bool _rootPasswordConfigured = false;
  final UserPasswordService _passwordService = UserPasswordService();
  final UserPinService _userPinService = UserPinService();
  final AuthService _authService = AuthService();
  final RootPinService _rootPinService = RootPinService();

  static const String _fallbackAccountName = 'A';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadRootAuthSettings();
  }

  Future<void> _loadRootAuthSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.rootAuthEnabled) ?? false;
    final configured = _passwordService.isPasswordConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _rootAuthEnabled = enabled;
      _rootPasswordConfigured = configured;
    });
  }

  Future<void> _loadAccounts() async {
    await AccountService().loadAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = List<Account>.from(AccountService().accounts);
      _isLoading = false;
    });
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
                  // ROOT 인증 설정 섹션
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: Icon(
                        _rootPasswordConfigured ? Icons.lock : Icons.lock_open,
                        color: _rootPasswordConfigured
                            ? Colors.green
                            : Colors.grey,
                      ),
                      title: const Text('ROOT 보안 설정'),
                      subtitle: Text(
                        _rootPasswordConfigured
                            ? (_rootAuthEnabled
                                  ? 'ROOT 인증 활성화됨'
                                  : 'ROOT 인증 설정됨 (비활성화)')
                            : 'ROOT 보안 방식을 선택하세요 (PIN/지문/비밀번호)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.security),
                        tooltip: 'ROOT 보안 설정',
                        onPressed: _showRootSecurityChoice,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // CEO 대시보드 링크 제거 (Root 계정 관리 화면에서만 표시 안함)
                  const Text(
                    '계정을 삭제하면 해당 계정의 모든 데이터가 삭제됩니다.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ..._accounts.map((a) {
                    final label = labelByAccount[a.name];
                    final canDelete = _accounts.length > 1;
                    final hasPassword =
                        a.password != null && a.password!.isNotEmpty;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          hasPassword ? Icons.lock : Icons.lock_open,
                          color: hasPassword ? Colors.green : Colors.grey,
                        ),
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
                              icon: const Icon(Icons.vpn_key),
                              tooltip: '비밀번호 설정',
                              onPressed: () => _showPasswordDialog(a),
                            ),
                            if (canDelete)
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
