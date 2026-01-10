/// 범용 메모리 캐시 유틸리티
/// 
/// 사용 예시:
/// ```dart
/// final cache = SimpleCache<String, RecipeMatch>(
///   maxAge: Duration(minutes: 5),
/// );
/// 
/// // 저장
/// cache.set('key1', recipeData);
/// 
/// // 조회
/// final data = cache.get('key1'); // null이면 만료됨
/// 
/// // 무효화
/// cache.clear();
/// ```
class SimpleCache<K, V> {
  final Duration maxAge;
  final Map<K, _CacheEntry<V>> _storage = {};

  SimpleCache({
    required this.maxAge,
  });

  /// 캐시에 값 저장
  void set(K key, V value) {
    _storage[key] = _CacheEntry(
      value: value,
      timestamp: DateTime.now(),
    );
  }

  /// 캐시에서 값 조회 (만료되었으면 null 반환)
  V? get(K key) {
    final entry = _storage[key];
    if (entry == null) return null;

    if (entry.isExpired(maxAge)) {
      _storage.remove(key);
      return null;
    }

    return entry.value;
  }

  /// 캐시 전체 무효화
  void clear() {
    _storage.clear();
  }

  /// 특정 키만 삭제
  void remove(K key) {
    _storage.remove(key);
  }

  /// 만료된 항목들 정리
  void cleanup() {
    _storage.removeWhere((key, entry) => entry.isExpired(maxAge));
  }

  /// 캐시된 항목 수
  int get length => _storage.length;

  /// 캐시가 비어있는지
  bool get isEmpty => _storage.isEmpty;
}

/// 캐시 엔트리 (내부 사용)
class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;

  _CacheEntry({
    required this.value,
    required this.timestamp,
  });

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) >= maxAge;
  }
}

/// 단순 키-값 캐시 (싱글톤 패턴)
/// 
/// 사용 예시:
/// ```dart
/// // 저장
/// SingletonCache.instance.set('user_data', userData, maxAge: Duration(hours: 1));
/// 
/// // 조회
/// final data = SingletonCache.instance.get('user_data');
/// ```
class SingletonCache {
  SingletonCache._();
  static final SingletonCache instance = SingletonCache._();

  final Map<String, _TimedCacheEntry> _storage = {};

  /// 값 저장
  void set(String key, dynamic value, {Duration maxAge = const Duration(minutes: 5)}) {
    _storage[key] = _TimedCacheEntry(
      value: value,
      timestamp: DateTime.now(),
      maxAge: maxAge,
    );
  }

  /// 값 조회
  T? get<T>(String key) {
    final entry = _storage[key];
    if (entry == null) return null;

    if (entry.isExpired()) {
      _storage.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// 전체 삭제
  void clear() {
    _storage.clear();
  }

  /// 특정 키 삭제
  void remove(String key) {
    _storage.remove(key);
  }

  /// 만료된 항목 정리
  void cleanup() {
    _storage.removeWhere((key, entry) => entry.isExpired());
  }
}

class _TimedCacheEntry {
  final dynamic value;
  final DateTime timestamp;
  final Duration maxAge;

  _TimedCacheEntry({
    required this.value,
    required this.timestamp,
    required this.maxAge,
  });

  bool isExpired() {
    return DateTime.now().difference(timestamp) >= maxAge;
  }
}
