import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/user_pin_service.dart';

class VerifyCurrentUserPinDialog extends StatefulWidget {
  const VerifyCurrentUserPinDialog({
    super.key,
    required this.prefs,
    required this.service,
  });

  final SharedPreferences prefs;
  final UserPinService service;

  @override
  State<VerifyCurrentUserPinDialog> createState() =>
      _VerifyCurrentUserPinDialogState();
}

class _VerifyCurrentUserPinDialogState
    extends State<VerifyCurrentUserPinDialog> {
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
      title: const Text('기존 PIN 확인'),
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

