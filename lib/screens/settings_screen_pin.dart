part of 'settings_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension SettingsPin on _SettingsScreenState {
  Future<void> setUserPinEnabled(bool enabled) async {
    if (_isLoading) return;

    final prefs = await SharedPreferences.getInstance();
    final configured = _userPinService.isPinConfigured(prefs);

    if (enabled && !configured) {
      final didSet = await _showSetUserPinDialog();
      if (!didSet) {
        if (!mounted) return;
        setState(() {
          _userPinEnabled = false;
          _userPinConfigured = _userPinService.isPinConfigured(prefs);
        });
        return;
      }
    }

    if (!enabled) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('PIN 해지'),
            content: const Text('유저 계정 PIN을 해지할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('해지'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        if (!mounted) return;
        setState(() => _userPinEnabled = true);
        return;
      }

      await _userPinService.clearPin(prefs);
    }

    await prefs.setBool(PrefKeys.userPinEnabled, enabled);
    final configuredNow = _userPinService.isPinConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _userPinEnabled = enabled && configuredNow;
      _userPinConfigured = configuredNow;
    });
  }

  Future<bool> _showSetUserPinDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    if (!mounted) {
      pinController.dispose();
      confirmController.dispose();
      return false;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('유저 계정 PIN 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '새 PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PIN 확인',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final pin = pinController.text.trim();
                    final confirm = confirmController.text.trim();
                    if (pin.length < 4) {
                      setDialogState(() {
                        error = 'PIN은 최소 4자리 이상이어야 합니다.';
                      });
                      return;
                    }
                    if (pin != confirm) {
                      setDialogState(() {
                        error = 'PIN이 일치하지 않습니다.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('설정'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      pinController.dispose();
      confirmController.dispose();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final pin = pinController.text.trim();
    pinController.dispose();
    confirmController.dispose();
    await _userPinService.setPin(prefs, pin: pin);
    if (!mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('유저 계정 PIN이 설정되었습니다')));
    return true;
  }

  Future<void> changeUserPin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_userPinService.isPinConfigured(prefs)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 PIN을 설정하세요')));
      return;
    }

    if (!mounted) return;
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
    if (ok != true || !mounted) return;

    final didSet = await _showSetUserPinDialog();
    if (!didSet || !mounted) return;

    await prefs.setBool(PrefKeys.userPinEnabled, true);
    final configuredNow = _userPinService.isPinConfigured(prefs);
    setState(() {
      _userPinEnabled = configuredNow;
      _userPinConfigured = configuredNow;
    });
  }
}
