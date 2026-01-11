import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/memo_search_utils.dart';

class _CapturingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  group('MemoSearchUtils', () {
    testWidgets('openMemoOnlySearch pushes a MaterialPageRoute', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final observer = _CapturingNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: <NavigatorObserver>[observer],
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final context = navigatorKey.currentContext;
      expect(context, isNotNull);

      // Start navigation without awaiting (it completes when the route pops).
      final future = MemoSearchUtils.openMemoOnlySearch(
        context!,
        accountName: 'acct',
      );

      // No extra pump needed: push is synchronous; route build is async.
      expect(observer.pushedRoutes, isNotEmpty);
      expect(observer.pushedRoutes.last, isA<MaterialPageRoute<dynamic>>());

      navigatorKey.currentState!.pop();
      await tester.pump();
      await future;
    });
  });
}
