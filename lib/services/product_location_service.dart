import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 상품별 마지막 위치를 학습하고 제안하는 서비스
///
/// 사용자가 장바구니에 상품을 추가할 때 이전에 기록한 위치를 제안하여
/// 마트 내에서 상품을 더 쉽게 찾을 수 있도록 지원합니다.
class ProductLocationService {
  ProductLocationService._();
  static final ProductLocationService instance = ProductLocationService._();

  static const String _keyPrefix = 'product_location_v1_';

  /// 계정별 상품 위치 맵 키
  String _locationMapKey(String accountName) => '$_keyPrefix${accountName}_map';

  /// 상품명을 정규화 (대소문자, 공백 무시)
  String _normalizeProductName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  /// 상품의 마지막 위치를 저장
  ///
  /// [accountName] - 계정명
  /// [productName] - 상품명
  /// [location] - 위치 (예: "3번 통로", "냉장고", "1층 입구")
  Future<void> saveLocation({
    required String accountName,
    required String productName,
    required String location,
  }) async {
    final normalized = _normalizeProductName(productName);
    if (normalized.isEmpty || location.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _locationMapKey(accountName);

    // 기존 맵 로드
    final raw = prefs.getString(key);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          map = decoded;
        }
      } catch (_) {
        // 파싱 실패 시 새로 시작
      }
    }

    // 위치 업데이트
    map[normalized] = {
      'location': location.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
      'originalName': productName.trim(),
    };

    // 저장 (최대 500개 항목 유지)
    if (map.length > 500) {
      // 오래된 항목부터 제거
      final entries = map.entries.toList();
      entries.sort((a, b) {
        final aTime = (a.value as Map)['updatedAt'] as String? ?? '';
        final bTime = (b.value as Map)['updatedAt'] as String? ?? '';
        return aTime.compareTo(bTime);
      });

      // 최근 500개만 유지
      map = Map.fromEntries(entries.skip(entries.length - 500));
    }

    await prefs.setString(key, jsonEncode(map));
  }

  /// 상품의 마지막 위치를 조회
  ///
  /// [accountName] - 계정명
  /// [productName] - 상품명
  ///
  /// Returns: 저장된 위치 문자열, 없으면 null
  Future<String?> getLocation({
    required String accountName,
    required String productName,
  }) async {
    final normalized = _normalizeProductName(productName);
    if (normalized.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final key = _locationMapKey(accountName);
    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final entry = decoded[normalized];
      if (entry is! Map) return null;

      return (entry['location'] as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  /// 모든 저장된 위치 정보 조회 (디버깅용)
  ///
  /// Returns: Map<상품명, 위치>
  Future<Map<String, String>> getAllLocations({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _locationMapKey(accountName);
    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};

      final result = <String, String>{};
      decoded.forEach((normalizedName, value) {
        if (value is Map) {
          final originalName =
              (value['originalName'] as String?) ?? normalizedName;
          final location = (value['location'] as String?) ?? '';
          if (location.isNotEmpty) {
            result[originalName] = location;
          }
        }
      });

      return result;
    } catch (_) {
      return {};
    }
  }

  /// 위치 정보 삭제
  Future<void> removeLocation({
    required String accountName,
    required String productName,
  }) async {
    final normalized = _normalizeProductName(productName);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _locationMapKey(accountName);
    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      decoded.remove(normalized);
      await prefs.setString(key, jsonEncode(decoded));
    } catch (_) {
      // 무시
    }
  }

  /// 모든 위치 정보 초기화
  Future<void> clearAllLocations({required String accountName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationMapKey(accountName));
  }

  /// 위치 제안 목록 (자주 사용되는 위치들)
  static const List<String> commonLocations = [
    '입구',
    '1층',
    '2층',
    '지하',
    '냉장고',
    '냉동실',
    '채소 코너',
    '과일 코너',
    '정육 코너',
    '생선 코너',
    '유제품 코너',
    '빵 코너',
    '과자 코너',
    '음료 코너',
    '라면 코너',
    '통조림 코너',
    '생활용품',
    '화장품',
    '의류',
    '가전',
    '계산대 근처',
    '1번 통로',
    '2번 통로',
    '3번 통로',
    '4번 통로',
    '5번 통로',
    '6번 통로',
    '7번 통로',
    '8번 통로',
    '9번 통로',
    '10번 통로',
  ];
}
