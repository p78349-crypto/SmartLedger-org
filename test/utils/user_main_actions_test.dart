import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/utils/user_main_actions.dart';

void main() {
  testWidgets('UserMainActions navigates to expected routes', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    Object? lastArgs;

    Route<dynamic> buildRoute(RouteSettings settings) {
      lastArgs = settings.arguments;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text(settings.name ?? 'unknown')),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        onGenerateRoute: buildRoute,
        home: const Scaffold(body: Text('home')),
      ),
    );

    UserMainActions.openSearch(navKey.currentState!, account: 'acc1');
    await tester.pumpAndSettle();
    expect(find.text(AppRoutes.accountStatsSearch), findsOneWidget);
    expect(lastArgs, isA<AccountArgs>());

    UserMainActions.openTrash(navKey.currentState!);
    await tester.pumpAndSettle();
    expect(find.text(AppRoutes.trash), findsOneWidget);

    unawaited(UserMainActions.openIncomeSplit(navKey.currentState!, account: 'acc1'));
    await tester.pumpAndSettle();
    expect(find.text(AppRoutes.incomeSplit), findsOneWidget);

    unawaited(UserMainActions.openSavingsPlanList(navKey.currentState!, account: 'acc1'));
    await tester.pumpAndSettle();
    expect(find.text(AppRoutes.savingsPlanList), findsOneWidget);

    unawaited(UserMainActions.openBackup(navKey.currentState!, account: 'acc1'));
    await tester.pumpAndSettle();
    expect(find.text(AppRoutes.backup), findsOneWidget);
  });

  testWidgets('openTransactionDetail passes TransactionDetailArgs and returns result', (tester) async {
    final navKey = GlobalKey<NavigatorState>();

    Route<dynamic> onGenerate(RouteSettings settings) {
      if (settings.name == AppRoutes.transactionDetail) {
        // Pop a result after route is pushed.
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop(true);
            });
            return const SizedBox.shrink();
          },
        );
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SizedBox.shrink(),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        onGenerateRoute: onGenerate,
        home: const Scaffold(body: Text('home')),
      ),
    );

    final future = UserMainActions.openTransactionDetail(
      navKey.currentState!,
      account: 'acc1',
      initialType: TransactionType.expense,
    );

    await tester.pumpAndSettle();
    final result = await future;
    expect(result, isTrue);
  });
}
