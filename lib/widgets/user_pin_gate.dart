import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_pin_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';

class UserPinGate extends StatefulWidget {
  const UserPinGate({super.key, required this.child});

  final Widget child;

  @override
  State<UserPinGate> createState() => _UserPinGateState();
}

class _UserPinGateState extends State<UserPinGate> {
  bool _ready = false;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final service = UserPinService();
    final configured = service.isPinConfigured(prefs);

    if (!enabled || !configured) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _authorized = true;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _ready = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptUntilAuthorized(prefs, service);
    });
  }

  Future<void> _promptUntilAuthorized(
    SharedPreferences prefs,
    UserPinService service,
  ) async {
    while (mounted && !_authorized) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _UserPinDialog(prefs: prefs, service: service);
        },
      );

      if (!mounted) return;
      if (result == true) {
        setState(() => _authorized = true);
        return;
      }

      // If the dialog returns false (user chose exit), pop this route.
      Navigator.of(context).maybePop();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: SizedBox.shrink());
    }

    if (!_authorized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconCatalog.lockOutline, size: 48),
              SizedBox(height: 12),
              Text('PIN 확인 중...'),
            ],
          ),
        ),
      );
    }

    return widget.child;
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

  @override
  void initState() {
    super.initState();
    _syncLockState();
  }

  void _syncLockState() {
    final remaining = widget.service.lockRemaining(widget.prefs);
    if (remaining == null) return;
    setState(() {
      final seconds = remaining.inSeconds;
      _message = '잠금 상태입니다. $seconds초 후 다시 시도하세요.';
    });
  }

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
        _message = 'PIN이 올바르지 않습니다. $seconds초 후 다시 시도하세요.';
      });
      return;
    }

    final attempts = result.failedAttempts ?? 0;
    final warning = (result.showWarning ?? false) ? ' (경고: $attempts회 실패)' : '';
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
          child: const Text('나가기'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
