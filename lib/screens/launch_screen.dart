import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/account.dart';
import '../navigation/app_routes.dart';
import 'permission_gate_screen.dart';
import '../services/account_service.dart';
import '../services/user_pref_service.dart';
import '../utils/pref_keys.dart';
import '../widgets/background_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  bool _permissionsGranted = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isBypassed =
          prefs.getBool(PrefKeys.permissionGateBypassed) ?? false;

      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;
      final notificationStatus = await Permission.notification.status;

      debugPrint(
        '[LaunchScreen] Permission Status - Photos: $photosStatus, '
        'Storage: $storageStatus, Notification: $notificationStatus',
      );

      final hasStorage =
          photosStatus.isGranted ||
          storageStatus.isGranted ||
          photosStatus.isLimited;
      final hasNotification =
          notificationStatus.isGranted || notificationStatus.isProvisional;

      if (hasStorage && hasNotification || isBypassed) {
        debugPrint('[LaunchScreen] Essential permissions granted or bypassed.');
        if (mounted) {
          setState(() {
            _permissionsGranted = true;
            _isCheckingPermissions = false;
          });
        }
        _goToAccountMain();
      } else {
        debugPrint(
          '[LaunchScreen] Essential permissions missing. '
          'hasStorage: $hasStorage, hasNotification: $hasNotification',
        );
        if (mounted) {
          setState(() {
            _permissionsGranted = false;
            _isCheckingPermissions = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[LaunchScreen] Error checking permissions: $e');
      if (mounted) {
        setState(() {
          _permissionsGranted = true; // Fallback to allow entry on error
          _isCheckingPermissions = false;
        });
      }
      _goToAccountMain();
    }
  }

  Future<void> _goToAccountMain() async {
    try {
      debugPrint('[LaunchScreen] _goToAccountMain 시작');

      final last = await UserPrefService.getLastAccountName();
      debugPrint('[LaunchScreen] 마지막 계정: $last');

      if (!mounted) return;

      final service = AccountService();
      final exists = last != null && service.getAccountByName(last) != null;
      debugPrint('[LaunchScreen] 계정 존재 여부: $exists');

      if (exists) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.accountMain,
          arguments: AccountMainArgs(accountName: last),
        );
        return;
      }

      final existing = service.getAccountByName('A');
      final guestAccount = existing ?? Account(name: 'A');
      if (existing == null) {
        await service.addAccount(guestAccount);
      }
      await UserPrefService.setLastAccountName(guestAccount.name);

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.accountMain,
        arguments: AccountMainArgs(accountName: guestAccount.name),
      );
    } catch (e, stackTrace) {
      debugPrint('[LaunchScreen] 오류 발생: $e');
      debugPrint('[LaunchScreen] StackTrace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return ListenableBuilder(
        listenable: Listenable.merge([
          BackgroundHelper.colorNotifier,
          BackgroundHelper.typeNotifier,
          BackgroundHelper.imagePathNotifier,
          BackgroundHelper.blurNotifier,
        ]),
        builder: (context, _) {
          final bgColor = BackgroundHelper.colorNotifier.value;
          final bgType = BackgroundHelper.typeNotifier.value;
          final bgImagePath = BackgroundHelper.imagePathNotifier.value;
          final bgBlur = BackgroundHelper.blurNotifier.value;

          return Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              children: [
                if (bgType == 'image' && bgImagePath != null)
                  Positioned.fill(
                    child: Image.file(
                      File(bgImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          ColoredBox(color: bgColor),
                    ),
                  ),
                if (bgType == 'image' && bgImagePath != null && bgBlur > 0)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        },
      );
    }

    if (!_permissionsGranted) {
      return PermissionGateScreen(
        onGranted: () {
          setState(() {
            _permissionsGranted = true;
          });
          _goToAccountMain();
        },
      );
    }

    // Requested: show nothing visible on app start.
    return ListenableBuilder(
      listenable: Listenable.merge([
        BackgroundHelper.colorNotifier,
        BackgroundHelper.typeNotifier,
        BackgroundHelper.imagePathNotifier,
        BackgroundHelper.blurNotifier,
      ]),
      builder: (context, _) {
        final bgColor = BackgroundHelper.colorNotifier.value;
        final bgType = BackgroundHelper.typeNotifier.value;
        final bgImagePath = BackgroundHelper.imagePathNotifier.value;
        final bgBlur = BackgroundHelper.blurNotifier.value;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              if (bgType == 'image' && bgImagePath != null)
                Positioned.fill(
                  child: Image.file(
                    File(bgImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: bgColor),
                  ),
                ),
              if (bgType == 'image' && bgImagePath != null && bgBlur > 0)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              ColoredBox(
                color: bgType == 'image'
                    ? Colors.black.withValues(alpha: 0.3)
                    : bgColor,
                child: const SizedBox.expand(),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Smart Ledger',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '당신의 스마트한 자산 관리 파트너',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
