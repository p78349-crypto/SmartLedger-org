import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/cache_utils.dart';

void main() {
  group('SimpleCache', () {
    late SimpleCache<String, int> cache;

    setUp(() {
      cache = SimpleCache<String, int>(maxAge: const Duration(seconds: 1));
    });

    test('stores and retrieves value', () {
      cache.set('key1', 100);
      expect(cache.get('key1'), 100);
    });

    test('returns null for non-existent key', () {
      expect(cache.get('nonexistent'), isNull);
    });

    test('overwrites existing value', () {
      cache.set('key1', 100);
      cache.set('key1', 200);
      expect(cache.get('key1'), 200);
    });

    test('returns null for expired entry', () async {
      final shortCache = SimpleCache<String, int>(
        maxAge: const Duration(milliseconds: 50),
      );
      shortCache.set('key1', 100);

      // 만료 전
      expect(shortCache.get('key1'), 100);

      // 만료 대기
      await Future.delayed(const Duration(milliseconds: 60));

      // 만료 후
      expect(shortCache.get('key1'), isNull);
    });

    test('clear removes all entries', () {
      cache.set('key1', 100);
      cache.set('key2', 200);
      expect(cache.length, 2);

      cache.clear();
      expect(cache.length, 0);
      expect(cache.isEmpty, isTrue);
    });

    test('remove deletes specific key', () {
      cache.set('key1', 100);
      cache.set('key2', 200);

      cache.remove('key1');

      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), 200);
    });

    test('cleanup removes expired entries', () async {
      final shortCache = SimpleCache<String, int>(
        maxAge: const Duration(milliseconds: 50),
      );
      shortCache.set('key1', 100);

      await Future.delayed(const Duration(milliseconds: 60));

      shortCache.set('key2', 200); // 새로운 항목

      shortCache.cleanup();

      expect(shortCache.get('key1'), isNull); // 만료됨
      expect(shortCache.get('key2'), 200); // 유효함
    });

    test('length returns correct count', () {
      expect(cache.length, 0);

      cache.set('key1', 100);
      expect(cache.length, 1);

      cache.set('key2', 200);
      expect(cache.length, 2);
    });

    test('isEmpty returns correct state', () {
      expect(cache.isEmpty, isTrue);

      cache.set('key1', 100);
      expect(cache.isEmpty, isFalse);
    });
  });

  group('SimpleCache with different types', () {
    test('works with String values', () {
      final cache = SimpleCache<String, String>(maxAge: const Duration(minutes: 5));
      cache.set('greeting', 'hello');
      expect(cache.get('greeting'), 'hello');
    });

    test('works with List values', () {
      final cache = SimpleCache<String, List<int>>(
        maxAge: const Duration(minutes: 5),
      );
      cache.set('numbers', [1, 2, 3]);
      expect(cache.get('numbers'), [1, 2, 3]);
    });

    test('works with int keys', () {
      final cache = SimpleCache<int, String>(maxAge: const Duration(minutes: 5));
      cache.set(1, 'one');
      cache.set(2, 'two');
      expect(cache.get(1), 'one');
      expect(cache.get(2), 'two');
    });
  });
}
