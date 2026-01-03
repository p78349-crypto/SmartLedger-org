import 'package:flutter/material.dart';
import 'package:smart_ledger/utils/screen_saver_ids.dart';
import 'package:smart_ledger/widgets/in_app_screen_saver.dart';

/// Helper to launch the in-app screen saver from anywhere.
class ScreenSaverLauncher {
  const ScreenSaverLauncher._();

  static Future<void> show({
    required BuildContext context,
    required String accountName,
    String? title,
  }) async {
    final theme = Theme.of(context);
    final scrim = theme.colorScheme.scrim.withValues(alpha: 0.65);

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: ScreenSaverIds.shortcutIconId,
      barrierColor: scrim,
      pageBuilder: (context, a1, a2) {
        return InAppScreenSaver(
          accountName: accountName,
          title: title ?? '$accountName 보호기',
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (context, anim, secondary, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }
}
