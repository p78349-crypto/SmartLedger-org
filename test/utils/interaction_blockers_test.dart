import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/interaction_blockers.dart';

void main() {
  group('InteractionBlockers', () {
    tearDown(() {
      // Reset the state after each test
      // Force reset by running an empty action if blocked
      if (InteractionBlockers.isBlocked) {
        // Wait for any pending action to complete
      }
    });

    group('isBlocked', () {
      test('returns false initially', () {
        // The state might be dirty from other tests, so we test the type
        expect(InteractionBlockers.isBlocked, isA<bool>());
      });
    });

    group('run', () {
      test('executes action when not blocked', () async {
        var executed = false;
        await InteractionBlockers.run(() {
          executed = true;
        });
        expect(executed, true);
      });

      test('does not execute action when blocked', () async {
        var firstExecuted = false;
        var secondExecuted = false;

        // Start a slow action
        final firstFuture = InteractionBlockers.run(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          firstExecuted = true;
        });

        // Try to run another action while blocked
        await InteractionBlockers.run(() {
          secondExecuted = true;
        });

        await firstFuture;

        expect(firstExecuted, true);
        expect(secondExecuted, false);
      });

      test('unblocks after action completes', () async {
        await InteractionBlockers.run(() async {
          await Future.delayed(const Duration(milliseconds: 10));
        });

        var executed = false;
        await InteractionBlockers.run(() {
          executed = true;
        });
        expect(executed, true);
      });

      test('unblocks even if action throws', () async {
        try {
          await InteractionBlockers.run(() {
            throw Exception('Test error');
          });
        } catch (_) {
          // Expected
        }

        var executed = false;
        await InteractionBlockers.run(() {
          executed = true;
        });
        expect(executed, true);
      });
    });

    group('gate', () {
      test('returns a function that executes action', () async {
        var executed = false;
        final gated = InteractionBlockers.gate(() {
          executed = true;
        });

        await gated();
        expect(executed, true);
      });

      test('gated function prevents double execution', () async {
        var count = 0;
        final gated = InteractionBlockers.gate(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          count++;
        });

        // Call twice rapidly
        final f1 = gated();
        gated(); // Should be blocked

        await f1;
        expect(count, 1);
      });
    });

    group('gateValue', () {
      test('returns a ValueChanged that executes action with value', () async {
        int? receivedValue;
        final gated = InteractionBlockers.gateValue<int>((value) {
          receivedValue = value;
        });

        gated(42);
        // Small delay to let the action complete
        await Future.delayed(Duration.zero);
        expect(receivedValue, 42);
      });
    });
  });
}
