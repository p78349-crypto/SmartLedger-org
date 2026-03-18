import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';
import 'package:smart_ledger/services/subscription_access_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/widgets/asset_route_auth_gate.dart';
import 'package:smart_ledger/widgets/root_auth_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SMOKE(AUTH): RootAuthGate bypass opens child', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.bypassSecurityForTesting: true,
      PrefKeys.rootAuthEnabled: true,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: RootAuthGate(child: Scaffold(body: Text('ROOT_OPEN'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ROOT_OPEN'), findsOneWidget);
  });

  testWidgets('SMOKE(AUTH): AssetRouteAuthGate bypass opens child', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.bypassSecurityForTesting: true,
      PrefKeys.assetAuthEnabled: true,
      PrefKeys.assetAuthRequired: true,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AssetRouteAuthGate(child: Scaffold(body: Text('ASSET_OPEN'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ASSET_OPEN'), findsOneWidget);
  });

  testWidgets(
    'SMOKE(AUTH): AssetRouteAuthGate blocks when subscription required but expired',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.bypassSecurityForTesting: true,
        PrefKeys.assetAuthEnabled: true,
        PrefKeys.assetAuthRequired: true,
      });

      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: 'smoke_sub_expired',
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.expired,
          expiresAtMs: now
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AssetRouteAuthGate(
            requiresSubscription: true,
            subscriptionUserId: 'smoke_sub_expired',
            child: Scaffold(body: Text('ASSET_OPEN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('구독 인증 필요'), findsOneWidget);
      expect(find.text('ASSET_OPEN'), findsNothing);
    },
  );

  testWidgets(
    'SMOKE(AUTH): AssetRouteAuthGate allows when subscription required and active',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.bypassSecurityForTesting: true,
        PrefKeys.assetAuthEnabled: true,
        PrefKeys.assetAuthRequired: true,
      });

      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: 'smoke_sub_active',
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.active,
          expiresAtMs: now.add(const Duration(days: 7)).millisecondsSinceEpoch,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AssetRouteAuthGate(
            requiresSubscription: true,
            subscriptionUserId: 'smoke_sub_active',
            child: Scaffold(body: Text('ASSET_OPEN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ASSET_OPEN'), findsOneWidget);
      expect(find.text('구독 인증 필요'), findsNothing);
    },
  );

  testWidgets(
    'SMOKE(AUTH): Subscription blocked UI action button invokes callback',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.bypassSecurityForTesting: true,
        PrefKeys.assetAuthEnabled: true,
        PrefKeys.assetAuthRequired: true,
      });

      final now = DateTime.now();
      await SubscriptionAccessService.saveState(
        userId: 'smoke_sub_action',
        state: SubscriptionAccessState(
          status: SubscriptionAccessStatus.expired,
          expiresAtMs: now
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        ),
      );

      var actionPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AssetRouteAuthGate(
            requiresSubscription: true,
            subscriptionUserId: 'smoke_sub_action',
            onSubscriptionAction: () => actionPressed = true,
            child: const Scaffold(body: Text('ASSET_OPEN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('구독 관리'), findsOneWidget);
      await tester.tap(find.text('구독 관리'));
      await tester.pump();
      expect(actionPressed, isTrue);
    },
  );

  testWidgets('SMOKE(AUTH): Main page ASSET slot shell renders', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.bypassSecurityForTesting: true,
    });

    const accountName = 'smoke_auth_pages';

    final assetSlots = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
    assetSlots[0] = 'asset_simple_input';
    await UserPrefService.setPageIconSlots(
      accountName: accountName,
      pageIndex: 4,
      slots: assetSlots,
    );

    Route<dynamic> stubRoute(RouteSettings settings) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: SizedBox.shrink()),
        settings: settings,
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: const AccountMainScreen(
          accountName: accountName,
          initialIndex: 4,
        ),
        onGenerateRoute: stubRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('main_icon_slot_4_0')),
      findsOneWidget,
    );
  });

  testWidgets('SMOKE(AUTH): Main page can navigate to ROOT page (index 5)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.bypassSecurityForTesting: true,
      PrefKeys.rootAuthEnabled: true,
    });

    const accountName = 'smoke_auth_root_page';

    final rootSlots = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
    rootSlots[0] = 'ceo_assistant';
    await UserPrefService.setPageIconSlots(
      accountName: accountName,
      pageIndex: 5,
      slots: rootSlots,
    );

    Route<dynamic> stubRoute(RouteSettings settings) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: SizedBox.shrink()),
        settings: settings,
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: const AccountMainScreen(
          accountName: accountName,
          initialIndex: 4,
        ),
        onGenerateRoute: stubRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();

    expect(find.text('ROOT'), findsOneWidget);
    expect(find.byType(RootAuthGate), findsOneWidget);
  });
}
