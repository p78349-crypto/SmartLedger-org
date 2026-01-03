import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_ledger/models/account.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/screens/permission_gate_screen.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/widgets/background_widget.dart';
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
        '[LaunchScreen] Permission Status - Photos: $photosStatus, Storage: $storageStatus, Notification: $notificationStatus',
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
          '[LaunchScreen] Essential permissions missing. hasStorage: $hasStorage, hasNotification: $hasNotification',
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
      return ValueListenableBuilder<Color>(
        valueListenable: BackgroundHelper.colorNotifier,
        builder: (context, bgColor, _) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator()),
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
    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          body: ColoredBox(color: bgColor, child: const SizedBox.expand()),
        );
      },
    );
  }
}
