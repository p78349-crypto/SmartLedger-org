part of user_account_auth_gate;

class _UserAuthChoiceDialog extends StatelessWidget {
  const _UserAuthChoiceDialog({
    required this.canPin,
    required this.canPassword,
    required this.canBiometric,
  });

  final bool canPin;
  final bool canPassword;
  final bool canBiometric;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('계정 인증'),
      content: const Text('사용할 인증 방법을 선택하세요.'),
      actions: [
        if (canBiometric)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(_UserAuthChoiceResult.biometric);
            },
            icon: const Icon(IconCatalog.fingerprint),
            label: const Text('지문'),
          ),
        if (canPin)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(_UserAuthChoiceResult.pin);
            },
            icon: const Icon(IconCatalog.lockOutline),
            label: const Text('PIN'),
          ),
        if (canPassword)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(_UserAuthChoiceResult.password);
            },
            icon: const Icon(IconCatalog.passwordOutlined),
            label: const Text('비번'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_UserAuthChoiceResult.exit);
          },
          child: const Text('나가기'),
        ),
      ],
    );
  }
}

class _UserPinDialog extends StatefulWidget {
  const _UserPinDialog({required this.prefs, required this.service});

  final SharedPreferences prefs;
  final UserPinService service;

  @override
  State<_UserPinDialog> createState() => _UserPinDialogState();
}

class _UserPinDialogState extends State<_UserPinDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    if (_busy) return;

    final pin = _controller.text.trim();
    if (pin.isEmpty) {
      setState(() => _message = 'PIN을 입력하세요.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final result = await widget.service.verifyPinWithPolicy(
      widget.prefs,
      pin: pin,
    );

    if (!mounted) return;

    if (result.status == UserPinPolicyStatus.success) {
      Navigator.of(context).pop(true);
      return;
    }

    if (result.status == UserPinPolicyStatus.locked) {
      final seconds = result.lockRemaining?.inSeconds ?? 0;
      setState(() {
        _busy = false;
        _message = '잠금 상태입니다. $seconds초 후 다시 시도하세요.';
      });
      return;
    }

    final attempts = result.failedAttempts ?? 0;
    final showWarning = result.showWarning ?? false;
    final warning = showWarning ? ' (경고: $attempts회 실패)' : '';
    setState(() {
      _busy = false;
      _message = 'PIN이 올바르지 않습니다.$warning';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PIN 입력'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _UserPasswordDialog extends StatefulWidget {
  const _UserPasswordDialog({required this.prefs, required this.service});

  final SharedPreferences prefs;
  final UserPasswordService service;

  @override
  State<_UserPasswordDialog> createState() => _UserPasswordDialogState();
}

class _UserPasswordDialogState extends State<_UserPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    if (_busy) return;

    final password = _controller.text;
    if (password.trim().isEmpty) {
      setState(() => _message = '비밀번호를 입력하세요.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final result = await widget.service.verifyPasswordWithPolicy(
      widget.prefs,
      password: password,
    );

    if (!mounted) return;

    if (result.status == UserPasswordPolicyStatus.success) {
      Navigator.of(context).pop(true);
      return;
    }

    if (result.status == UserPasswordPolicyStatus.locked) {
      final seconds = result.lockRemaining?.inSeconds ?? 0;
      setState(() {
        _busy = false;
        _message = '잠금 상태입니다. $seconds초 후 다시 시도하세요.';
      });
      return;
    }

    final attempts = result.failedAttempts ?? 0;
    final showWarning = result.showWarning ?? false;
    final warning = showWarning ? ' (경고: $attempts회 실패)' : '';
    setState(() {
      _busy = false;
      _message = '비밀번호가 올바르지 않습니다.$warning';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('비밀번호 입력'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
