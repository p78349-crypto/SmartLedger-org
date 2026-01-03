import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/user_password_service.dart';

class VerifyCurrentUserPasswordDialog extends StatefulWidget {
  const VerifyCurrentUserPasswordDialog({
    super.key,
    required this.prefs,
    required this.service,
  });

  final SharedPreferences prefs;
  final UserPasswordService service;

  @override
  State<VerifyCurrentUserPasswordDialog> createState() =>
      _VerifyCurrentUserPasswordDialogState();
}

class _VerifyCurrentUserPasswordDialogState
    extends State<VerifyCurrentUserPasswordDialog> {
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
    final warning = (result.showWarning ?? false) ? ' (경고: $attempts회 실패)' : '';
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
      title: const Text('기존 비밀번호 확인'),
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
