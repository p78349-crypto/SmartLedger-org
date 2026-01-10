import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 마트 레이아웃 및 통로 순서 관리 서비스
/// 
/// 대형 마트에서 효율적으로 쇼핑하기 위한 통로 순서를 관리합니다.
class StoreLayoutService {
  StoreLayoutService._();
  static final StoreLayoutService instance = StoreLayoutService._();

  static const String _keyPrefix = 'store_layout_v1_';

  /// 계정별 마트 레이아웃 맵 키
  String _layoutMapKey(String accountName) =>
      '$_keyPrefix${accountName}_map';

  /// 통로/구역 순서 정의 (일반적인 마트 동선)
  /// 숫자가 낮을수록 먼저 방문
  static const Map<String, int> defaultAisleOrder = {
    // 입구 근처 (1-10)
    '입구': 1,
    '1층': 2,
    '2층': 3,
    '지하': 4,
    
    // 신선 식품 구역 (11-30)
    '채소 코너': 11,
    '과일 코너': 12,
    '정육 코너': 13,
    '생선 코너': 14,
    
    // 냉장/냉동 구역 (31-50)
    '냉장고': 31,
    '유제품 코너': 32,
    '냉동실': 33,
    
    // 통로별 구역 (51-100)
    '1번 통로': 51,
    '2번 통로': 52,
    '3번 통로': 53,
    '4번 통로': 54,
    '5번 통로': 55,
    '6번 통로': 56,
    '7번 통로': 57,
    '8번 통로': 58,
    '9번 통로': 59,
    '10번 통로': 60,
    
    // 가공식품 구역 (101-130)
    '빵 코너': 101,
    '과자 코너': 102,
    '음료 코너': 103,
    '라면 코너': 104,
    '통조림 코너': 105,
    
    // 생활용품 구역 (131-150)
    '생활용품': 131,
    '화장품': 132,
    '의류': 133,
    '가전': 134,
    
    // 계산대 (151+)
    '계산대 근처': 151,
  };

  /// 위치 문자열에서 통로 순서 추출
  /// 
  /// 예: "3번 통로" → 53, "냉장고" → 31, "알 수 없음" → 999
  int getAisleOrder(String location) {
    if (location.isEmpty) return 999;
    
    final normalized = location.trim().toLowerCase();
    
    // 정확히 일치하는 경우
    for (final entry in defaultAisleOrder.entries) {
      if (normalized == entry.key.toLowerCase()) {
        return entry.value;
      }
    }
    
    // 부분 일치 (예: "3번 통로 냉장고" → "3번 통로" 우선)
    for (final entry in defaultAisleOrder.entries) {
      if (normalized.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    return 999; // 알 수 없는 위치
  }

  /// 위치 문자열을 표준화된 구역명으로 변환
  /// 
  /// 예: "냉장", "냉장실" → "냉장고"
  String normalizeLocation(String location) {
    if (location.isEmpty) return '';
    
    final lower = location.trim().toLowerCase();
    
    // 냉장 관련
    if (lower.contains('냉장') && !lower.contains('냉동')) {
      if (lower.contains('유제품')) return '유제품 코너';
      return '냉장고';
    }
    
    // 냉동 관련
    if (lower.contains('냉동')) {
      return '냉동실';
    }
    
    // 통로 번호 추출 (예: "3통로", "통로3" → "3번 통로")
    final aisleMatch = RegExp(r'(\d+)\s*번?\s*통로|통로\s*(\d+)').firstMatch(lower);
    if (aisleMatch != null) {
      final num = aisleMatch.group(1) ?? aisleMatch.group(2);
      return '$num번 통로';
    }
    
    // 층수 추출
    if (lower.contains('1층') || lower == '1f') return '1층';
    if (lower.contains('2층') || lower == '2f') return '2층';
    if (lower.contains('지하') || lower == 'b1') return '지하';
    
    // 코너 이름
    if (lower.contains('채소')) return '채소 코너';
    if (lower.contains('과일')) return '과일 코너';
    if (lower.contains('정육') || lower.contains('고기')) return '정육 코너';
    if (lower.contains('생선') || lower.contains('수산')) return '생선 코너';
    if (lower.contains('유제품')) return '유제품 코너';
    if (lower.contains('빵')) return '빵 코너';
    if (lower.contains('과자')) return '과자 코너';
    if (lower.contains('음료')) return '음료 코너';
    if (lower.contains('라면')) return '라면 코너';
    if (lower.contains('통조림') || lower.contains('캔')) return '통조림 코너';
    if (lower.contains('생활용품')) return '생활용품';
    if (lower.contains('화장품')) return '화장품';
    if (lower.contains('계산')) return '계산대 근처';
    
    // 원본 반환
    return location.trim();
  }

  /// 사용자 정의 통로 순서 저장
  Future<void> saveCustomAisleOrder({
    required String accountName,
    required Map<String, int> customOrder,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _layoutMapKey(accountName);
    await prefs.setString(key, jsonEncode(customOrder));
  }

  /// 사용자 정의 통로 순서 조회
  Future<Map<String, int>?> getCustomAisleOrder({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _layoutMapKey(accountName);
    final raw = prefs.getString(key);
    
    if (raw == null || raw.isEmpty) return null;
    
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      
      return Map<String, int>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  /// 통로 순서 초기화
  Future<void> clearCustomAisleOrder({required String accountName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_layoutMapKey(accountName));
  }

  /// 위치 목록을 쇼핑 동선 순서로 정렬
  /// 
  /// Returns: 정렬된 위치 목록
  List<String> sortLocationsByRoute(List<String> locations) {
    final withOrder = locations.map((loc) {
      return (location: loc, order: getAisleOrder(loc));
    }).toList();
    
    withOrder.sort((a, b) => a.order.compareTo(b.order));
    
    return withOrder.map((e) => e.location).toList();
  }

  /// 다음 방문할 위치 제안
  /// 
  /// [currentLocation] - 현재 위치
  /// [remainingLocations] - 아직 방문하지 않은 위치 목록
  /// 
  /// Returns: 다음 방문할 위치, 없으면 null
  String? suggestNextLocation({
    String? currentLocation,
    required List<String> remainingLocations,
  }) {
    if (remainingLocations.isEmpty) return null;
    
    final currentOrder = currentLocation != null 
        ? getAisleOrder(currentLocation) 
        : 0;
    
    // 현재 위치 이후의 위치들을 순서대로 정렬
    final sorted = sortLocationsByRoute(remainingLocations);
    
    // 현재 위치보다 뒤에 있는 첫 번째 위치 찾기
    for (final loc in sorted) {
      if (getAisleOrder(loc) > currentOrder) {
        return loc;
      }
    }
    
    // 모든 위치가 현재 위치보다 앞에 있으면 첫 번째 반환
    return sorted.isNotEmpty ? sorted.first : null;
  }

  /// 위치가 설정된 항목과 설정되지 않은 항목 분리
  /// 
  /// Returns: (위치 있음, 위치 없음)
  (List<T> withLocation, List<T> withoutLocation) separateByLocation<T>({
    required List<T> items,
    required String? Function(T) getLocation,
  }) {
    final withLoc = <T>[];
    final withoutLoc = <T>[];
    
    for (final item in items) {
      final loc = getLocation(item);
      if (loc != null && loc.isNotEmpty) {
        withLoc.add(item);
      } else {
        withoutLoc.add(item);
      }
    }
    
    return (withLoc, withoutLoc);
  }

  /// 위치별로 항목 그룹화
  /// 
  /// Returns: Map<위치, 항목 리스트>
  Map<String, List<T>> groupByLocation<T>({
    required List<T> items,
    required String Function(T) getLocation,
  }) {
    final grouped = <String, List<T>>{};
    
    for (final item in items) {
      final loc = normalizeLocation(getLocation(item));
      if (loc.isEmpty) continue;
      
      grouped.putIfAbsent(loc, () => []).add(item);
    }
    
    return grouped;
  }

  /// 쇼핑 진행률 계산
  /// 
  /// Returns: 0.0 ~ 1.0 (0% ~ 100%)
  double calculateProgress({
    required int totalItems,
    required int completedItems,
  }) {
    if (totalItems <= 0) return 0.0;
    return (completedItems / totalItems).clamp(0.0, 1.0);
  }
}
