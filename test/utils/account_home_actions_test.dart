import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/utils/account_home_actions.dart';

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  group('AccountHomeActions', () {
    testWidgets('openTransactionAdd pushes AppRoutes.transactionAdd with args', (
      tester,
    ) async {
      final observer = _RecordingNavigatorObserver();
      late BuildContext homeContext;

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          onGenerateRoute: (settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Route')),
            );
          },
          home: Builder(
            builder: (context) {
              homeContext = context;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );

      final future = AccountHomeActions.openTransactionAdd(
        homeContext,
        accountName: 'MyAccount',
      );

      await tester.pumpAndSettle();

      expect(observer.pushedRoutes, isNotEmpty);
      final last = observer.pushedRoutes.last;
      expect(last.settings.name, AppRoutes.transactionAdd);
      expect(last.settings.arguments, isA<TransactionAddArgs>());
      final args = last.settings.arguments as TransactionAddArgs;
      expect(args.accountName, 'MyAccount');

      // Pop the pushed route to allow the awaited pushNamed future to complete.
      Navigator.of(homeContext).pop();
      await tester.pumpAndSettle();
      await future;
    });
  });
}
