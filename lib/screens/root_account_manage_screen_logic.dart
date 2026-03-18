part of 'root_account_manage_screen.dart';

extension RootAccountManageLogic on _RootAccountManageScreenState {
  Future<void> _showRootSecurityChoice() async {
    // 생체인식 가용성 체크
    final biometricAvailable = await _authService.canUseDeviceAuth();

    if (!mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ROOT 보안 방식 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '설정한 보안 방식은 모든 계정에 동일하게 적용됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.dialpad, size: 36),
              title: const Text(
                'PIN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('6자리 숫자 PIN으로 보호합니다.'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () => Navigator.of(context).pop('pin'),
            ),
            const SizedBox(height: 8),
            if (biometricAvailable)
              ListTile(
                leading: const Icon(Icons.fingerprint, size: 36),
                title: const Text(
                  '지문/생체인식',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('기기 지문 또는 얼굴인식으로 보호합니다.'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () => Navigator.of(context).pop('biometric'),
              )
            else
              ListTile(
                leading: Icon(
                  Icons.fingerprint,
                  size: 36,
                  color: Colors.grey.shade400,
                ),
                title: Text(
                  '지문/생체인식',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                subtitle: Text(
                  '스마트폰 설정에서 지문/생체인식을 먼저 등록하세요.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                enabled: false,
              ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.password, size: 36),
              title: const Text(
                '비밀번호',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('영문/숫자 조합 비밀번호로 보호합니다.'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () => Navigator.of(context).pop('password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    switch (choice) {
      case 'pin':
        await _setupPin();
        break;
      case 'biometric':
        await _setupBiometric();
        break;
      case 'password':
        await _setupPassword();
        break;
    }
  }

  Future<void> _setupPin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ROOT PIN 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (6자리 숫자)',
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'PIN 확인',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();

              if (pin.length != 6) {
                SnackbarUtils.showWarning(context, 'PIN은 6자리 숫자여야 합니다');
                return;
              }

              if (pin != confirm) {
                SnackbarUtils.showWarning(context, 'PIN이 일치하지 않습니다');
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final prefs = await SharedPreferences.getInstance();
    await _rootPinService.setPin(prefs, pin: pinController.text.trim());
    await prefs.setBool(PrefKeys.rootPinEnabled, true);
    await prefs.setString(PrefKeys.rootSecurityMode, 'pin');
    await prefs.setBool(PrefKeys.rootAuthEnabled, true);

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, 'ROOT PIN이 설정되었습니다');
    await _loadRootAuthSettings();
  }

  Future<void> _setupBiometric() async {
    final result = await _authService.authenticateDevice(
      reason: 'ROOT 보안을 생체인식으로 설정합니다',
    );

    if (!result.ok) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        '생체인식 인증에 실패했습니다.\n스마트폰 설정에서 지문/얼굴인식이 등록되어 있는지 확인하세요.',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.rootBiometricEnabled, true);
    await prefs.setString(PrefKeys.rootSecurityMode, 'biometric');
    await prefs.setBool(PrefKeys.rootAuthEnabled, true);

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, 'ROOT 생체인식이 설정되었습니다');
    await _loadRootAuthSettings();
  }

  Future<void> _setupPassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ROOT 비밀번호 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '영문, 숫자 조합 (최소 8자)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();

              if (password.length < 8) {
                SnackbarUtils.showWarning(context, '비밀번호는 최소 8자 이상이어야 합니다');
                return;
              }

              if (password != confirm) {
                SnackbarUtils.showWarning(context, '비밀번호가 일치하지 않습니다');
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true) return;

    // 비밀번호는 ROOT PIN Service를 사용하되, 더 긴 문자열 허용
    final prefs = await SharedPreferences.getInstance();
    await _rootPinService.setPin(prefs, pin: passwordController.text.trim());
    await prefs.setBool(PrefKeys.rootPasswordEnabled, true);
    await prefs.setString(PrefKeys.rootSecurityMode, 'password');
    await prefs.setBool(PrefKeys.rootAuthEnabled, true);

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, 'ROOT 비밀번호가 설정되었습니다');
    await _loadRootAuthSettings();
  }

  Future<void> _deleteAccount(Account account) async {
    // Prevent deleting the last remaining account.
    if (AccountService().accounts.length <= 1) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '계정이 1개일 경우 삭제할 수 없습니다.');
      return;
    }
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
      final existing = AccountService().getAccountByName(
        _RootAccountManageScreenState._fallbackAccountName,
      );
      if (existing == null) {
        await AccountService().addAccount(
          Account(name: _RootAccountManageScreenState._fallbackAccountName),
        );
      }
      await UserPrefService.setLastAccountName(
        _RootAccountManageScreenState._fallbackAccountName,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.accountMain,
        (route) => false,
        arguments: const AccountMainArgs(
          accountName: _RootAccountManageScreenState._fallbackAccountName,
        ),
      );
      return;
    }

    if (!mounted) return;

    SnackbarUtils.showSuccess(context, '$deletedName 계정이 삭제되었습니다');
    await _loadAccounts();
  }

  Future<void> _showCreateAccountDialog() async {
    final controller = TextEditingController();
    final passwordController = TextEditingController();
    final passwordConfirmController = TextEditingController();
    bool obscurePassword = true;
    bool obscurePasswordConfirm = true;
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('새 계정 이름 입력'),
            content: SingleChildScrollView(
              child: ValueListenableBuilder<TextEditingValue>(
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
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: '비밀번호 (선택사항)',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordConfirmController,
                        obscureText: obscurePasswordConfirm,
                        decoration: InputDecoration(
                          labelText: '비밀번호 확인',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePasswordConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscurePasswordConfirm =
                                    !obscurePasswordConfirm;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final baseName = controller.text.trim();
                  if (baseName.isEmpty) {
                    return;
                  }

                  final password = passwordController.text;
                  final passwordConfirm = passwordConfirmController.text;

                  if (password.isNotEmpty || passwordConfirm.isNotEmpty) {
                    if (password != passwordConfirm) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('비밀번호가 일치하지 않습니다'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (password.length < 4) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('비밀번호는 최소 4자 이상이어야 합니다'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }

                  final locale = Localizations.localeOf(dialogContext);
                  final value = AccountNameLanguageTag.applyForcedSuffix(
                    baseName,
                    locale,
                  );

                  // Pass both name and password as JSON
                  final resultData = jsonEncode({
                    'name': value,
                    'password': password.isEmpty ? null : password,
                  });
                  Navigator.of(dialogContext).pop(resultData);
                },
                child: const Text('생성'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
      passwordController.dispose();
      passwordConfirmController.dispose();
    }
    if (!mounted) return;
    if (result == null || result.isEmpty) {
      return;
    }

    // Parse result
    final Map<String, dynamic> data =
        jsonDecode(result) as Map<String, dynamic>;
    final name = data['name'] as String;
    final password = data['password'] as String?;

    final added = await AccountService().addAccount(
      Account(name: name, password: password),
    );
    if (!added) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '이미 존재하는 계정입니다: $name');
      return;
    }
    await _loadAccounts();
    if (!mounted) return;
    SnackbarUtils.showSuccess(context, '$name 계정이 생성되었습니다');
  }

  Future<void> _showPasswordDialog(Account account) async {
    // 생체인식 가용성 체크
    final biometricAvailable = await _authService.canUseDeviceAuth();

    if (!mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${account.name} 보안 방식 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '계정 "${account.name}"의 보안 방식을 선택하세요.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.dialpad, size: 36),
              title: const Text(
                'PIN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('6자리 숫자 PIN으로 보호합니다.'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () => Navigator.of(context).pop('pin'),
            ),
            const SizedBox(height: 8),
            if (biometricAvailable)
              ListTile(
                leading: const Icon(Icons.fingerprint, size: 36),
                title: const Text(
                  '지문/생체인식',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('기기 지문 또는 얼굴인식으로 보호합니다.'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () => Navigator.of(context).pop('biometric'),
              )
            else
              ListTile(
                leading: Icon(
                  Icons.fingerprint,
                  size: 36,
                  color: Colors.grey.shade400,
                ),
                title: Text(
                  '지문/생체인식',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                subtitle: Text(
                  '스마트폰 설정에서 지문/생체인식을 먼저 등록하세요.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                enabled: false,
              ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.password, size: 36),
              title: const Text(
                '비밀번호',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('영문/숫자 조합 비밀번호로 보호합니다.'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () => Navigator.of(context).pop('password'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.no_encryption,
                size: 36,
                color: Colors.grey,
              ),
              title: const Text(
                '보호 해제',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('보안 설정을 제거합니다.'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () => Navigator.of(context).pop('none'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    switch (choice) {
      case 'pin':
        await _setupAccountPin(account);
        break;
      case 'biometric':
        await _setupAccountBiometric(account);
        break;
      case 'password':
        await _setupAccountPassword(account);
        break;
      case 'none':
        await _removeAccountSecurity(account);
        break;
    }
  }

  Future<void> _setupAccountPin(Account account) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${account.name} PIN 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (6자리 숫자)',
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'PIN 확인',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();

              if (pin.length != 6) {
                SnackbarUtils.showWarning(context, 'PIN은 6자리 숫자여야 합니다');
                return;
              }

              if (pin != confirm) {
                SnackbarUtils.showWarning(context, 'PIN이 일치하지 않습니다');
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final prefs = await SharedPreferences.getInstance();
    final accountKey = 'account_${account.name}';
    await _userPinService.setPin(prefs, pin: pinController.text.trim());
    await prefs.setBool('${accountKey}_pin_enabled', true);
    await prefs.setString('${accountKey}_security_mode', 'pin');

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, '${account.name} PIN이 설정되었습니다');
    await _loadAccounts();
  }

  Future<void> _setupAccountBiometric(Account account) async {
    final result = await _authService.authenticateDevice(
      reason: '${account.name} 계정을 생체인식으로 보호합니다',
    );

    if (!result.ok) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        '생체인식 인증에 실패했습니다.\n스마트폰 설정에서 지문/얼굴인식이 등록되어 있는지 확인하세요.',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final accountKey = 'account_${account.name}';
    await prefs.setBool('${accountKey}_biometric_enabled', true);
    await prefs.setString('${accountKey}_security_mode', 'biometric');

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, '${account.name} 생체인식이 설정되었습니다');
    await _loadAccounts();
  }

  Future<void> _setupAccountPassword(Account account) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${account.name} 비밀번호 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '최소 4자 이상',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();

              if (password.length < 4) {
                SnackbarUtils.showWarning(context, '비밀번호는 최소 4자 이상이어야 합니다');
                return;
              }

              if (password != confirm) {
                SnackbarUtils.showWarning(context, '비밀번호가 일치하지 않습니다');
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Account 모델의 password 필드에 저장 (레거시 호환)
    final success = await AccountService().updateAccountPassword(
      account.name,
      passwordController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final accountKey = 'account_${account.name}';
      await prefs.setString('${accountKey}_security_mode', 'password');

      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '${account.name} 비밀번호가 설정되었습니다');
      await _loadAccounts();
    } else {
      SnackbarUtils.showError(context, '비밀번호 설정에 실패했습니다');
    }
  }

  Future<void> _removeAccountSecurity(Account account) async {
    final prefs = await SharedPreferences.getInstance();
    final accountKey = 'account_${account.name}';

    // SharedPreferences 보안 설정 제거
    await prefs.remove('${accountKey}_pin_enabled');
    await prefs.remove('${accountKey}_biometric_enabled');
    await prefs.remove('${accountKey}_security_mode');

    // Account 모델의 password도 제거 (레거시 호환)
    final success = await AccountService().updateAccountPassword(
      account.name,
      null,
    );

    if (!mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(context, '${account.name} 보안 설정이 제거되었습니다');
      await _loadAccounts();
    } else {
      SnackbarUtils.showError(context, '보안 설정 제거에 실패했습니다');
    }
  }
}
