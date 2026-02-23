import 'package:flutter/material.dart';

/// 자산 보호 인증 방법 선택지
enum AssetAuthChoice { biometric, pin, password, exit }

/// 자산 보호 인증 방법 선택 다이얼로그
class AssetAuthChoiceDialog extends StatelessWidget {
  const AssetAuthChoiceDialog({
    super.key,
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
      title: const Text('자산 보호 인증'),
      content: const Text('사용할 인증 방법을 선택하세요.'),
      actions: [
        if (canBiometric)
          FilledButton.icon(
            onPressed: () => Navigator.of(context)
                .pop(AssetAuthChoice.biometric),
            icon: const Icon(Icons.fingerprint),
            label: const Text('지문'),
          ),
        if (canPin)
          FilledButton.icon(
            onPressed: () => Navigator.of(context)
                .pop(AssetAuthChoice.pin),
            icon: const Icon(Icons.lock_outline),
            label: const Text('PIN'),
          ),
        if (canPassword)
          FilledButton.icon(
            onPressed: () => Navigator.of(context)
                .pop(AssetAuthChoice.password),
            icon: const Icon(Icons.password_outlined),
            label: const Text('비번'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(AssetAuthChoice.exit),
          child: const Text('취소'),
        ),
      ],
    );
  }
}
