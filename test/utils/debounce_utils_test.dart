import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/debounce_utils.dart';

void main() {
  group('Debouncer', () {
    test('run executes action after delay', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int counter = 0;

      debouncer.run(() => counter++);

      expect(counter, 0); // 아직 실행 안됨
      await Future.delayed(const Duration(milliseconds: 60));
      expect(counter, 1); // 지연 후 실행됨

      debouncer.dispose();
    });

    test('multiple runs only execute last action', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int counter = 0;

      debouncer.run(() => counter += 1);
      debouncer.run(() => counter += 10);
      debouncer.run(() => counter += 100);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(counter, 100); // 마지막 액션만 실행

      debouncer.dispose();
    });

    test('cancel stops pending action', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int counter = 0;

      debouncer.run(() => counter++);
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 60));
      expect(counter, 0); // 취소되어 실행 안됨

      debouncer.dispose();
    });

    test('isPending returns correct state', () {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

      expect(debouncer.isPending, false);

      debouncer.run(() {});
      expect(debouncer.isPending, true);

      debouncer.cancel();
      expect(debouncer.isPending, false);

      debouncer.dispose();
    });

    test('dispose clears timer', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int counter = 0;

      debouncer.run(() => counter++);
      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 60));
      expect(counter, 0);
    });
  });

  group('Throttler', () {
    test('run executes immediately on first call', () {
      final throttler = Throttler(delay: const Duration(milliseconds: 100));
      int counter = 0;

      throttler.run(() => counter++);
      expect(counter, 1); // 즉시 실행

      throttler.dispose();
    });

    test('run ignores rapid subsequent calls', () async {
      final throttler = Throttler(delay: const Duration(milliseconds: 100));
      int counter = 0;

      throttler.run(() => counter++); // 실행
      throttler.run(() => counter++); // 무시
      throttler.run(() => counter++); // 무시

      expect(counter, 1);

      throttler.dispose();
    });

    test('run executes again after delay', () async {
      final throttler = Throttler(delay: const Duration(milliseconds: 50));
      int counter = 0;

      throttler.run(() => counter++);
      expect(counter, 1);

      await Future.delayed(const Duration(milliseconds: 60));

      throttler.run(() => counter++);
      expect(counter, 2);

      throttler.dispose();
    });
  });
}
