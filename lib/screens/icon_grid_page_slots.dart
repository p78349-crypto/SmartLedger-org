part of 'account_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension IconGridPageSlots on _IconGridPageState {
  Future<void> _loadSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final assetLockEnabled =
        prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false;
    final allowAssetOutsideWhenUnlocked =
        prefs.getBool(PrefKeys.iconAllowAssetIconsOutsideAssetWhenUnlocked) ??
        false;
    final untilMs = prefs.getInt(PrefKeys.assetAuthSessionUntilMs);
    final assetSessionUnlocked =
        untilMs != null && DateTime.now().millisecondsSinceEpoch < untilMs;

    final slots = await UserPrefService.getPageIconSlots(
      accountName: widget.accountName,
      pageIndex: widget.pageIndex,
    );
    final validated = slots.map((s) {
      final id = s.trim();
      if (id.isEmpty) return '';
      if (!_allKnownIconIds.contains(id)) return '';
      final allowed = _isAllowedOnPage(
        pageIndex: widget.pageIndex,
        iconId: id,
        assetLockEnabled: assetLockEnabled,
        allowAssetOutsideWhenUnlocked: allowAssetOutsideWhenUnlocked,
        assetSessionUnlocked: assetSessionUnlocked,
      );
      return allowed ? id : '';
    }).toList();

    // If slots are empty (or became empty after applying page policy), prefill
    // from available icons (visible + allowed set).
    final allEmptyStored = slots.every((s) => s.isEmpty);
    final allEmptyAfterValidation = validated.every((s) => s.isEmpty);
    final isReservedPage =
        _isStatsReservedPage(widget.pageIndex) ||
        _isAssetReservedPage(widget.pageIndex) ||
        _isRootReservedPage(widget.pageIndex) ||
        _isSettingsOnlyPage(widget.pageIndex);

    if (allEmptyStored || (isReservedPage && allEmptyAfterValidation)) {
      final visibleAndAllowedIcons = _getOrderedIcons()
          .where(
            (i) => _isAllowedOnPage(
              pageIndex: widget.pageIndex,
              iconId: i.id,
              assetLockEnabled: assetLockEnabled,
              allowAssetOutsideWhenUnlocked: allowAssetOutsideWhenUnlocked,
              assetSessionUnlocked: assetSessionUnlocked,
            ),
          )
          .toList();

      var writeIndex = 0;
      for (final icon in visibleAndAllowedIcons) {
        if (writeIndex >= _defaultSlotCount) break;
        validated[writeIndex] = icon.id;
        writeIndex++;
      }

      await UserPrefService.setPageIconSlots(
        accountName: widget.accountName,
        pageIndex: widget.pageIndex,
        slots: validated,
      );
    }

    // Page 0: ensure "음성 단축어" is visible early.
    if (widget.pageIndex == 0) {
      _ensureVoiceShortcuts(validated);
    }

    if (!mounted) return;
    setState(() {
      _slots = validated;
    });
  }

  Future<void> _ensureVoiceShortcuts(List<String> validated) async {
    final hasVoiceShortcuts = validated.contains(_voiceShortcutsIconId);
    if (hasVoiceShortcuts) return;

    // Only add if it's a known icon in the current catalog
    if (!_allKnownIconIds.contains(_voiceShortcutsIconId)) return;

    const preferredIndex = 0;
    final preferredEmpty =
        preferredIndex < validated.length && validated[preferredIndex].isEmpty;
    if (preferredEmpty) {
      validated[preferredIndex] = _voiceShortcutsIconId;
    } else {
      final emptyIndex = validated.indexOf('');
      if (emptyIndex != -1) {
        validated[emptyIndex] = _voiceShortcutsIconId;
      }
    }
    await UserPrefService.setPageIconSlots(
      accountName: widget.accountName,
      pageIndex: widget.pageIndex,
      slots: validated,
    );
  }

  Future<void> _saveSlotsDebounced() async {
    if (_isSavingSlots) return; // simple guard
    _isSavingSlots = true;
    try {
      await UserPrefService.setPageIconSlots(
        accountName: widget.accountName,
        pageIndex: widget.pageIndex,
        slots: _slots,
      );
    } finally {
      _isSavingSlots = false;
    }
  }

  void _assignOrSwap(String draggedId, int targetIndex) {
    setState(() {
      final currentIndex = _slots.indexOf(draggedId);
      if (currentIndex == -1) {
        // dragged from palette, assign into slot
        _slots[targetIndex] = draggedId;
      } else {
        // dragged from another slot -> swap
        final temp = _slots[targetIndex];
        _slots[targetIndex] = draggedId;
        _slots[currentIndex] = temp;
      }
    });
    _saveSlotsDebounced();
  }

  void _navigateToIcon(MainFeatureIcon icon) {
    if (icon.id == 'account_switch') {
      _showAccountSwitchDialog();
      return;
    }
    if (icon.id == 'accountStatsMemoSearch') {
      MemoSearchUtils.openMemoOnlySearch(
        context,
        accountName: widget.accountName,
      );
      return;
    }
    if (icon.id == 'accountStatsMemoStats') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoStatsScreen(accountName: widget.accountName),
        ),
      );
      return;
    }
    if (icon.routeName == null) {
      debugPrint('🔴 Icon ${icon.id} has no routeName');
      return;
    }

    final request = IconLaunchUtils.buildRequest(
      routeName: icon.routeName!,
      accountName: widget.accountName,
    );
    if (request == null) {
      debugPrint('🔴 Failed to build request for route: ${icon.routeName}');
      return;
    }

    debugPrint(
      '🟢 Navigating to: ${request.routeName} with args: ${request.arguments}',
    );

    Navigator.of(context)
        .pushNamed(request.routeName, arguments: request.arguments)
        .catchError((error) {
          debugPrint('🔴 Navigation error: $error');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('화면 이동 실패: $error')));
          }
          return null;
        });
  }

  Future<void> _showAccountSwitchDialog() async {
    final accountService = AccountService();
    final accounts = accountService.accounts;

    // ROOT 포함한 계정 목록
    final accountNames = accounts.map((a) => a.name).toList();
    if (!accountNames.contains('ROOT')) {
      accountNames.add('ROOT');
    }

    // 라벨 설정
    final labels = <String, String>{};
    int userIndex = 0;
    for (final name in accountNames) {
      if (name.trim().toUpperCase() == 'ROOT') {
        labels[name] = 'ROOT';
        continue;
      }
      userIndex++;
      if (userIndex == 1) {
        labels[name] = '유저1';
      } else if (userIndex == 2) {
        labels[name] = '유저2';
      }
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('계정 전환'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: accountNames.map((accountName) {
              final label = labels[accountName];
              final isRoot = accountName.trim().toUpperCase() == 'ROOT';
              final account = accountService.getAccountByName(accountName);
              final hasPassword =
                  account?.password != null && account!.password!.isNotEmpty;

              return ListTile(
                leading: Icon(
                  isRoot
                      ? Icons.admin_panel_settings
                      : (hasPassword ? Icons.lock : Icons.person),
                  color: isRoot ? Colors.amber : null,
                ),
                title: Text(accountName),
                trailing: label == null
                    ? null
                    : Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                onTap: () => Navigator.pop(dialogContext, accountName),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (selected == null) return;

    final isRoot = selected.trim().toUpperCase() == 'ROOT';

    // 글로벌 보안 규정: 복원된 계정 확인 (재인증 필요)
    if (!isRoot) {
      final prefs = await SharedPreferences.getInstance();
      final reauthJson =
          prefs.getString(PrefKeys.restoredAccountsNeedReauth) ?? '[]';
      final List<String> reauthAccounts =
          (json.decode(reauthJson) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (reauthAccounts.contains(selected)) {
        // 복원된 계정: 보안 경고
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('🔒 보안 알림'),
            content: const Text(
              '이 계정은 백업에서 복원된 계정입니다.\n\n'
              '글로벌 보안 규정에 따라 이 계정은 비밀번호 보호 없이 복원되었습니다.\n\n'
              '필요시 계정 설정에서 새로운 비밀번호를 설정해주세요.',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('계정 취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('계속 진행'),
              ),
            ],
          ),
        );

        if (!mounted) return;

        if (confirmed != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('계정 전환이 취소되었습니다'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // 재인증 플래그 제거 (이번 로그인부터는 경고 안 함)
        reauthAccounts.remove(selected);
        await prefs.setString(
          PrefKeys.restoredAccountsNeedReauth,
          json.encode(reauthAccounts),
        );
        if (!mounted) return;
      }
    }

    // ROOT 선택 시 RootAuthGate로 보호된 페이지 5(ROOT 관리)로 이동
    if (!mounted) return;
    if (isRoot) {
      await UserPrefService.setLastAccountName('ROOT');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const RootAuthGate(
            child: AccountMainScreen(accountName: 'ROOT', initialIndex: 5),
          ),
        ),
      );
      return;
    }

    final account = accountService.getAccountByName(selected);
    if (account == null) return;

    // 비밀번호가 설정된 계정인 경우 비밀번호 확인
    if (account.password != null && account.password!.isNotEmpty) {
      final passwordController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('${account.name} 비밀번호 입력'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              Navigator.of(dialogContext).pop(true);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (!mounted) {
        passwordController.dispose();
        return;
      }

      if (confirmed != true) {
        passwordController.dispose();
        return;
      }

      if (passwordController.text != account.password) {
        passwordController.dispose();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호가 올바르지 않습니다'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      passwordController.dispose();
    }

    // 선택한 계정을 마지막 계정으로 저장
    await UserPrefService.setLastAccountName(account.name);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.accountMain,
      arguments: AccountMainArgs(accountName: account.name),
    );
  }
}
