import 'package:flutter/material.dart';
import 'package:smart_ledger/models/account.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/widgets/background_widget.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    _goToAccountMain();
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
